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
#import <Foundation/Foundation.h>

@interface CMCocoaMouse : NSObject
{
    BOOL _emulatorHasFocus;
    NSUInteger _mouseMode;
    
    NSInteger buttonState;
    CGFloat deltaX;
    CGFloat deltaY;
    
    BOOL isCursorLocked;
    BOOL wasWithinBounds;
    BOOL isCursorVisible;
    BOOL isCursorAssociated;
    BOOL discardNextDelta;
}

@property (assign, nonatomic) BOOL emulatorHasFocus;
@property (assign, nonatomic) NSUInteger mouseMode;

- (void)lockCursor:(NSView *)screen;
- (void)unlockCursor;

- (BOOL)isMouseEnabled;
- (NSInteger)buttonState;
- (NSPoint)pointerCoordinates;

- (void)mouseMoved:(NSEvent *)theEvent
        withinView:(NSView *)view;
- (void)mouseDown:(NSEvent *)theEvent
       withinView:(NSView *)view;
- (void)mouseUp:(NSEvent *)theEvent
     withinView:(NSView *)view;
- (void)rightMouseDown:(NSEvent *)theEvent;
- (void)rightMouseUp:(NSEvent *)theEvent;

@end
