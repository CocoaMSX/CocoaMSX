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

#import "CMKeyboardManager.h"
#import "CMKeyboardInput.h"

@implementation CMGamepadConfiguration

static CMGamepadConfiguration *_defaultKeyboardPlayerOneConfig;
static CMGamepadConfiguration *_defaultKeyboardPlayerTwoConfig;
static CMGamepadConfiguration *_defaultGamepadConfig;

+ (void) initialize
{
	_defaultKeyboardPlayerOneConfig = [[CMGamepadConfiguration alloc] init];
	_defaultKeyboardPlayerOneConfig->_vendorProductId = CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_1;
	[_defaultKeyboardPlayerOneConfig reset];
	
	_defaultKeyboardPlayerTwoConfig = [[CMGamepadConfiguration alloc] init];
	_defaultKeyboardPlayerTwoConfig->_vendorProductId = CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_2;
	[_defaultKeyboardPlayerTwoConfig reset];
	
	_defaultGamepadConfig = [[CMGamepadConfiguration alloc] init];
	_defaultGamepadConfig->_vendorProductId = -1;
	[_defaultGamepadConfig reset];
}

- (id)init
{
    if ((self = [super init])) {
    }
    
    return self;
}

#pragma mark - Public

- (void) reset
{
	switch (_vendorProductId) {
		case CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_1:
			_up = CMMakeKey(CMKeyUp);
			_down = CMMakeKey(CMKeyDown);
			_left = CMMakeKey(CMKeyLeft);
			_right = CMMakeKey(CMKeyRight);
			_buttonA = CMMakeKey(CMKeySpacebar);
			_buttonB = CMMakeKey(CMKeyLeftAlt);
			break;
		case CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_2:
			_up = CMMakeKey(CMKeyW);
			_down = CMMakeKey(CMKeyS);
			_left = CMMakeKey(CMKeyA);
			_right = CMMakeKey(CMKeyD);
			_buttonA = CMMakeKey(CMKeyLeftBracket);
			_buttonB = CMMakeKey(CMKeyRightBracket);
			break;
		default:
			_up = CMMakeAnalog(CM_DIR_UP);
			_down = CMMakeAnalog(CM_DIR_DOWN);
			_left = CMMakeAnalog(CM_DIR_LEFT);
			_right = CMMakeAnalog(CM_DIR_RIGHT);
			_buttonA = CMMakeButton(1);
			_buttonB = CMMakeButton(2);
			break;
	}
}

+ (CMGamepadConfiguration *) defaultKeyboardPlayerOneConfiguration
{
	return _defaultKeyboardPlayerOneConfig;
}

+ (CMGamepadConfiguration *) defaultKeyboardPlayerTwoConfiguration
{
	return _defaultKeyboardPlayerTwoConfig;
}

+ (CMGamepadConfiguration *) defaultGamepadConfiguration
{
	return _defaultGamepadConfig;
}

- (NSString *) vendorProductString
{
	return [NSString stringWithFormat:@"%08lx", _vendorProductId];
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
