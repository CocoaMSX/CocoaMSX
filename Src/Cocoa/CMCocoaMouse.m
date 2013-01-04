/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012 Akop Karapetyan
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
        
        cursorVisible = YES;
        cursorAssociated = YES;
        
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
    return self.mouseMode != AM_DISABLE;
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
        
        if (!cursorAssociated)
        {
            cursorAssociated = YES;
            CGAssociateMouseAndMouseCursorPosition(true);
        }
        
        if (!cursorVisible)
        {
            cursorVisible = YES;
            [NSCursor unhide];
        }
    }
    
    _emulatorHasFocus = emulatorHasFocus;
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

#pragma mark - Cocoa Callbacks

- (void)mouseMoved:(NSEvent *)theEvent
        withinView:(NSView*)view
{
    if (![self isMouseEnabled])
        return;
    
    if (discardNextDelta)
    {
        discardNextDelta = NO;
        return;
    }
    
    NSScreen *currentScreen = [NSScreen mainScreen];
    NSSize screenRect = currentScreen.frame.size;
    
    CGFloat escapeThresholdX = screenRect.width * ESCAPE_THRESHOLD_RATIO;
    CGFloat escapeThresholdY = screenRect.height * ESCAPE_THRESHOLD_RATIO;
    
    NSPoint viewOrig = view.bounds.origin;
    NSSize viewSize = view.bounds.size;
    
    NSPoint point = [view convertPoint:[theEvent locationInWindow]
                              fromView:nil];
    
    BOOL cursorOutsideBounds = (point.x < 0 || point.x > viewSize.width ||
                                point.y < 0 || point.y > viewSize.height);
    
    if (self.mouseMode == AM_ENABLE_MOUSE)
    {
        if (cursorOutsideBounds)
        {
            // Out of bounds
            
            if (wasWithinBounds)
            {
                wasWithinBounds = NO;
                buttonState = 0;
            }
            
            if (!cursorVisible)
            {
                [NSCursor unhide];
                cursorVisible = YES;
            }
        }
        else
        {
            if (cursorVisible)
            {
                [NSCursor hide];
                cursorVisible = NO;
            }
            
            if (!wasWithinBounds)
            {
                NSRect centerView;
                centerView.origin.x = (viewOrig.x + viewSize.width) / 2.0;
                centerView.origin.y = (viewOrig.y + viewSize.height) / 2.0;
                
                // Compute screen coordinates
                NSPoint centerScreen = [view.window convertRectToScreen:centerView].origin;
                
                // Flip screen coordinates
                centerScreen.y = screenRect.height - centerScreen.y;
                
                // Reposition the cursor
                CGWarpMouseCursorPosition(NSPointToCGPoint(centerScreen));
                
                discardNextDelta = YES;
                wasWithinBounds = YES;
                
                if (cursorAssociated)
                {
                    cursorAssociated = NO;
                    CGAssociateMouseAndMouseCursorPosition(false);
                }
            }
        }
        
        deltaX = theEvent.deltaX;
        deltaY = theEvent.deltaY;
        
        if (abs(deltaX) > escapeThresholdX || abs(deltaY) > escapeThresholdY)
        {
            if (!cursorAssociated)
            {
                cursorAssociated = YES;
                CGAssociateMouseAndMouseCursorPosition(true);
            }
        }
    }
    else if (self.mouseMode == AM_ENABLE_LASER)
    {
        if (!cursorOutsideBounds)
        {
            deltaX = 0x10000 * (point.x / viewSize.width);
            deltaY = 0x10000 * (1.0 - (point.y / viewSize.height));
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([self isMouseEnabled])
        buttonState |= 1;
}

- (void)mouseUp:(NSEvent *)theEvent
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSPoint coordinates = theEmulator.mouse.pointerCoordinates;
    *dx = (int)coordinates.x;
    *dy = (int)coordinates.y;
    
    [pool drain];
}

int archMouseGetButtonState(int checkAlways)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    int buttonState = theEmulator.mouse.buttonState;
    
    [pool drain];
    
    return buttonState;
}

void archMouseEmuEnable(AmEnableMode mode)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    theEmulator.mouse.mouseMode = mode;
    
    [pool drain];
}

void archMouseSetForceLock(int lock) { }

@end
