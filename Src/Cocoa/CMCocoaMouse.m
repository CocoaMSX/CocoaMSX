/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2014 Akop Karapetyan
 **
 ** This program is free software; you can redistribute it and/or modify
 ** it under the terms of the GNU General Public License as published by
 ** the Free Software Foundation; either version 2 of the License, or
 ** (at your option) any later version.
 **
 ** This program is distributed in the hope that it will be useful,
 ** but WITHOUT ANY WARRANTY; without even the implied warranty of
 ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ** GNU General Public License for more details.
 **
 ** You should have received a copy of the GNU General Public License
 ** along with this program; if not, write to the Free Software
 ** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 **
 ******************************************************************************
 */
#import "CMCocoaMouse.h"

#import "CMEmulatorController.h"

#include "ArchInput.h"

@interface CMCocoaMouse ()

+ (NSRect)convertRectToScreen:(NSRect)rect
                       window:(NSWindow *)window;

@end

@implementation CMCocoaMouse

@synthesize emulatorHasFocus = _emulatorHasFocus;
@synthesize mouseMode = _mouseMode;

// In terms of the screen size
#define ESCAPE_THRESHOLD_RATIO .15

- (id)init
{
    if ((self = [super init]))
    {
        self.mouseMode = AM_DISABLE;
        buttonState = 0;
        deltaX = 0;
        deltaY = 0;
        
        isCursorLocked = NO;
        isCursorVisible = YES;
        isCursorAssociated = YES;
        
        self.emulatorHasFocus = NO;
        discardNextDelta = NO;
        wasWithinBounds = NO;
    }
    
    return self;
}

- (void)dealloc
{
    self.emulatorHasFocus = NO;
    
    [super dealloc];
}

- (BOOL)isMouseEnabled
{
    return [self mouseMode] != AM_DISABLE;
}

- (void)setEmulatorHasFocus:(BOOL)emulatorHasFocus
{
    if (emulatorHasFocus == self.emulatorHasFocus)
        return; // No change
    
    if (!emulatorHasFocus)
    {
        buttonState = 0;
        deltaX = 0;
        deltaY = 0;
        wasWithinBounds = NO;
        
        [self unlockCursor];
    }
    
    _emulatorHasFocus = emulatorHasFocus;
}

- (void)lockCursor:(NSView *)screen
{
    if (isCursorVisible)
    {
        [NSCursor hide];
        isCursorVisible = NO;
    }
    
    NSPoint viewOrig = [screen bounds].origin;
    NSSize viewSize = [screen bounds].size;
    
    NSRect centerView = NSMakeRect((viewOrig.x + viewSize.width) / 2.0,
                                   (viewOrig.y + viewSize.height) / 2.0,
                                   0, 0);
    
    // Compute screen coordinates
    NSPoint centerScreen = [CMCocoaMouse convertRectToScreen:centerView
                                                      window:[screen window]].origin;
    
    // Flip screen coordinates
    centerScreen.y = [[NSScreen mainScreen] frame].size.height - centerScreen.y;
    
    // Reposition the cursor
    CGWarpMouseCursorPosition(NSPointToCGPoint(centerScreen));
    
    discardNextDelta = YES;
    wasWithinBounds = YES;
    
    if (isCursorAssociated)
    {
        isCursorAssociated = NO;
        CGAssociateMouseAndMouseCursorPosition(false);
    }
    
    isCursorLocked = YES;
    
#ifdef DEBUG
    NSLog(@"CocoaMouse: lockCursor");
#endif
}

- (void)unlockCursor
{
    if (!isCursorAssociated)
    {
        isCursorAssociated = YES;
        CGAssociateMouseAndMouseCursorPosition(true);
    }
    
    if (!isCursorVisible)
    {
        isCursorVisible = YES;
        [NSCursor unhide];
    }
    
    isCursorLocked = NO;
    
#ifdef DEBUG
    NSLog(@"CocoaMouse: unlockCursor");
#endif
}

- (NSInteger)buttonState
{
    return (self.emulatorHasFocus && wasWithinBounds) ? buttonState : 0;
}

- (NSPoint)pointerCoordinates
{
    NSPoint point = { 0, 0};
    
    if (self.emulatorHasFocus && wasWithinBounds)
    {
        if (self.mouseMode == AM_ENABLE_MOUSE)
        {
            point.x = -deltaX;
            point.y = -deltaY;
            
            deltaX = 0;
            deltaY = 0;
        }
        else if (self.mouseMode == AM_ENABLE_LASER)
        {
            point.x = deltaX;
            point.y = deltaY;
        }
    }
    
    return point;
}

+ (NSRect)convertRectToScreen:(NSRect)rect
                       window:(NSWindow *)window
{
    if ([window respondsToSelector:@selector(convertRectToScreen:)])
        return [window convertRectToScreen:rect];
    
    NSRect frame = [window frame];
    
    rect.origin.x += frame.origin.x;
    rect.origin.y += frame.origin.y;
    
    return rect;
}

#pragma mark - Cocoa Callbacks

- (void)mouseMoved:(NSEvent *)theEvent
        withinView:(NSView *)view
{
    if (![self isMouseEnabled])
        return;
    
    if (discardNextDelta)
    {
        discardNextDelta = NO;
        return;
    }
    
    NSScreen *currentScreen = [NSScreen mainScreen];
    NSSize screenSize = [currentScreen frame].size;
    
    CGFloat escapeThresholdX = screenSize.width * ESCAPE_THRESHOLD_RATIO;
    CGFloat escapeThresholdY = screenSize.height * ESCAPE_THRESHOLD_RATIO;
    
    NSSize viewSize = [view bounds].size;
    
    NSPoint positionWithinView = [view convertPoint:[theEvent locationInWindow]
                                           fromView:nil];
    
    BOOL cursorInsideView = NSPointInRect(positionWithinView, [view bounds]);
    
    if (self.mouseMode == AM_ENABLE_MOUSE)
    {
        if (cursorInsideView)
        {
            if (!wasWithinBounds && CMGetBoolPref(@"lockMouseCursorOnHover"))
                [self lockCursor:view];
        }
        else if (isCursorLocked)
        {
            [self unlockCursor];
        }
        
        wasWithinBounds = cursorInsideView;
        
        if (isCursorLocked)
        {
            deltaX = theEvent.deltaX;
            deltaY = theEvent.deltaY;
            
            if (CMGetBoolPref(@"unlockMouseCursorOnShake") &&
                (abs(deltaX) > escapeThresholdX || abs(deltaY) > escapeThresholdY))
            {
                [self unlockCursor];
            }
        }
    }
    else if (self.mouseMode == AM_ENABLE_LASER)
    {
        if (cursorInsideView)
        {
            deltaX = 0x10000 * (positionWithinView.x / viewSize.width);
            deltaY = 0x10000 * (1.0 - (positionWithinView.y / viewSize.height));
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
       withinView:(NSView *)view
{
    if ([self isMouseEnabled])
    {
        BOOL isCursorLockedAtStartOfEvent = isCursorLocked;
        
        if (([theEvent modifierFlags] & NSCommandKeyMask) != 0)
        {
            if (isCursorLockedAtStartOfEvent)
                [self unlockCursor];
        }
        
        if (!isCursorLockedAtStartOfEvent)
            [self lockCursor:view];
        
        buttonState |= 1;
    }
}

- (void)mouseUp:(NSEvent *)theEvent
     withinView:(NSView *)view
{
    if ([self isMouseEnabled])
        buttonState &= ~1;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if ([self isMouseEnabled])
        buttonState |= 2;
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    if ([self isMouseEnabled])
        buttonState &= ~2;
}

#pragma mark - BlueMSX Callbacks

extern CMEmulatorController *theEmulator;

void archMouseGetState(int *dx, int *dy)
{
    @autoreleasepool
    {
        NSPoint coordinates = theEmulator.mouse.pointerCoordinates;
        *dx = (int)coordinates.x;
        *dy = (int)coordinates.y;
    }
}

int archMouseGetButtonState(int checkAlways)
{
    @autoreleasepool
    {
        return theEmulator.mouse.buttonState;
    }
}

void archMouseEmuEnable(AmEnableMode mode)
{
    @autoreleasepool
    {
        theEmulator.mouse.mouseMode = mode;
    }
}

void archMouseSetForceLock(int lock) { }

@end
