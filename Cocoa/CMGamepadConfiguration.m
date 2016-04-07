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
#import "CMGamepadConfiguration.h"

@implementation CMGamepadConfiguration

static CMGamepadConfiguration *_defaultConfig;

+ (void) initialize
{
	_defaultConfig = [[CMGamepadConfiguration alloc] init];
}

- (id)init
{
    if ((self = [super init])) {
		[self clear];
    }
    
    return self;
}

#pragma mark - Public

- (void) clear
{
	_up = CMMakeAnalog(CM_DIR_UP);
	_down = CMMakeAnalog(CM_DIR_DOWN);
	_left = CMMakeAnalog(CM_DIR_LEFT);
	_right = CMMakeAnalog(CM_DIR_RIGHT);
	_buttonA = CMMakeButton(1);
	_buttonB = CMMakeButton(2);
}

+ (CMGamepadConfiguration *) defaultConfiguration
{
	return _defaultConfig;
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *) decoder
{
    if ((self = [self init]))
    {
		_vendorProductId = [decoder decodeIntegerForKey:@"vendorProductId"];
		_up = [decoder decodeIntegerForKey:@"up"];
		_down = [decoder decodeIntegerForKey:@"down"];
		_left = [decoder decodeIntegerForKey:@"left"];
		_right = [decoder decodeIntegerForKey:@"right"];
		_buttonA = [decoder decodeIntegerForKey:@"buttonA"];
		_buttonB = [decoder decodeIntegerForKey:@"buttonB"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
    [encoder encodeInteger:_vendorProductId
					forKey:@"vendorProductId"];
	[encoder encodeInteger:_up
					forKey:@"up"];
	[encoder encodeInteger:_down
					forKey:@"down"];
	[encoder encodeInteger:_left
					forKey:@"left"];
	[encoder encodeInteger:_right
					forKey:@"right"];
	[encoder encodeInteger:_buttonA
					forKey:@"buttonA"];
	[encoder encodeInteger:_buttonB
					forKey:@"buttonB"];
}

#pragma mark - NSCopying

- (id) copyWithZone:(NSZone *) zone
{
    CMGamepadConfiguration *copy = [[[self class] allocWithZone:zone] init];
    
	copy->_vendorProductId = _vendorProductId;
	copy->_up = _up;
	copy->_down = _down;
	copy->_left = _left;
	copy->_right = _right;
	copy->_buttonA = _buttonA;
	copy->_buttonB = _buttonB;

    return copy;
}

@end
