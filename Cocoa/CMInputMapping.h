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

#define CMKeyCategoryModifier            1
#define CMKeyCategoryDirectional         2
#define CMKeyCategoryFunction            3
#define CMKeyCategoryAlpha               4
#define CMKeyCategoryNumeric             5
#define CMKeyCategoryNumericPad          6
#define CMKeyCategorySpecial             7
#define CMKeyCategorySymbols             8
#define CMKeyCategoryJoystickDirectional 9
#define CMKeyCategoryJoystickButtons     10

@interface CMInputMapping : NSObject<NSCopying, NSCoding>

@property (nonatomic, assign) NSUInteger virtualCode;

- (id)initWithVirtualCode:(NSUInteger)virtualCode;

- (NSString *)inputName;

- (NSInteger)category;
- (NSString *)categoryName;

- (BOOL)isMapped;

@end
