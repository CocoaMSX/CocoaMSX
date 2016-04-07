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

@interface CMGamepadConfiguration : NSObject<NSCoding, NSCopying>

#define CM_NO_INPUT 0

#define CM_KIND_MASK   0xf000000
#define CM_VALUE_MASK  0x0ffffff

#define CM_DIR_UP    0x0
#define CM_DIR_DOWN  0x1
#define CM_DIR_LEFT  0x2
#define CM_DIR_RIGHT 0x3

#define CM_KIND_BUTTON 0x1000000
#define CM_KIND_ANALOG 0x2000000

#define CMMakeButton(index) (CM_KIND_BUTTON|((index)&0x1f))
#define CMMakeAnalog(dir)   (CM_KIND_ANALOG|((dir)&0x3))

@property (nonatomic, assign) NSInteger vendorProductId;

@property (nonatomic, assign) NSInteger up;
@property (nonatomic, assign) NSInteger down;
@property (nonatomic, assign) NSInteger left;
@property (nonatomic, assign) NSInteger right;
@property (nonatomic, assign) NSInteger buttonA;
@property (nonatomic, assign) NSInteger buttonB;

- (void) clear;
+ (CMGamepadConfiguration *) defaultConfiguration;

@end
