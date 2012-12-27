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
#import <Foundation/Foundation.h>

#define CMKeyLayoutArabic    0x01
#define CMKeyLayoutBrazilian 0x02
#define CMKeyLayoutEstonian  0x03
#define CMKeyLayoutEuropean  0x04
#define CMKeyLayoutFrench    0x05
#define CMKeyLayoutGerman    0x06
#define CMKeyLayoutJapanese  0x07
#define CMKeyLayoutKorean    0x08
#define CMKeyLayoutRussian   0x09
#define CMKeyLayoutSpanish   0x10
#define CMKeyLayoutSwedish   0x11

#define CMKeyCategoryTypewriterRowOne   1
#define CMKeyCategoryTypewriterRowTwo   2
#define CMKeyCategoryTypewriterRowThree 3
#define CMKeyCategoryTypewriterRowFour  4
#define CMKeyCategorySpecial            5
#define CMKeyCategoryModifier           6
#define CMKeyCategoryFunction           7
#define CMKeyCategoryDirectional        8
#define CMKeyCategoryNumericPad         9
#define CMKeyCategoryJoyDirections     10
#define CMKeyCategoryJoyButtons        11

#define CMKeyShiftStateNormal  0
#define CMKeyShiftStateShifted 1

@interface CMCocoaKeyboard : NSObject
{
}

- (void)setEmulatorHasFocus:(BOOL)focus;

- (void)keyDown:(NSEvent*)event;
- (void)keyUp:(NSEvent*)event;
- (void)flagsChanged:(NSEvent *)event;
- (void)resetState;

- (BOOL)areAnyKeysDown;
- (void)releaseAllKeys;

- (NSString *)inputNameForVirtualCode:(NSUInteger)virtualCode
                           shiftState:(NSInteger)shiftState
                             layoutId:(NSInteger)layoutId;
- (NSInteger)categoryForVirtualCode:(NSUInteger)virtualCode;
- (NSString *)nameForCategory:(NSInteger)category;
+ (NSInteger)compareKeysByOrderOfAppearance:(NSNumber *)one
                                 keyCodeTwo:(NSNumber *)two;

@end
