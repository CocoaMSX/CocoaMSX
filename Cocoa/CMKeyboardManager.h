/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2016 Akop Karapetyan
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
#import <IOKit/hid/IOHIDLib.h>

#import "CMKeyEventData.h"

@protocol CMKeyboardEventDelegate

@required
- (void)keyStateChanged:(CMKeyEventData *)event
                 isDown:(BOOL)isDown;

@end

@interface CMKeyboardManager : NSObject

+ (CMKeyboardManager *)sharedInstance;

- (void)addObserver:(id<CMKeyboardEventDelegate>)observer;
- (void)removeObserver:(id<CMKeyboardEventDelegate>)observer;

// Inject a key change from an AppKit responder (NSEvent.keyCode is already the
// macOS virtual key code that observers expect). Used by the DISASMTRACE build,
// which drives input through the responder chain instead of IOHIDManager so it
// needs no Input Monitoring permission.
- (void)injectKeyCode:(NSInteger)keyCode isDown:(BOOL)isDown;

@end
