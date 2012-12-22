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

#define CMKeyCategoryCharacters    1
#define CMKeyCategorySymbols       2
#define CMKeyCategorySpecial       3
#define CMKeyCategoryModifier      4
#define CMKeyCategoryFunction      5
#define CMKeyCategoryDirectional   6
#define CMKeyCategoryNumericPad    7
#define CMKeyCategoryJoyDirections 8
#define CMKeyCategoryJoyButtons    9

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

- (NSString *)inputNameForVirtualCode:(NSUInteger)virtualCode;
- (NSInteger)categoryForVirtualCode:(NSUInteger)virtualCode;
- (NSString *)nameForCategory:(NSInteger)category;

@end
