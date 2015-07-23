/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2015 Akop Karapetyan
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

#import "CMMSXKeyboard.h"

#import "CMGamepadManager.h"
#import "CMKeyboardManager.h"

#define CMJoypadNone 0

extern NSString * const CMKeyPasteStarted;
extern NSString * const CMKeyPasteEnded;

@interface CMCocoaInput : NSObject<CMGamepadEventDelegate, CMKeyboardEventDelegate>
{
    int virtualCodeMap[256];
    NSUInteger pollCounter;
    
    NSObject *keysToPasteLock;
    
    NSMutableArray *keysToPaste;
    
    NSInteger _joypadOneId;
    NSInteger _joypadTwoId;
    
    CMMSXKeyCombination *_keyCombinationToAutoPress;
    NSTimeInterval timeOfAutoPress;
    BOOL autoKeyPressPasted;
    
    NSMutableDictionary *joypadConfigurations;
}

@property (nonatomic, assign, readonly) NSInteger joypadOneId;
@property (nonatomic, assign, readonly) NSInteger joypadTwoId;

@property (nonatomic, retain) CMMSXKeyCombination *keyCombinationToAutoPress;

- (void)setEmulatorHasFocus:(BOOL)focus;

- (void)resetState;

- (BOOL)pasteText:(NSString *)text
       layoutName:(NSString *)layoutName;

- (void)resetState;
- (void)releaseAllKeys;

@end
