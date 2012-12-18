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
#import "CMCocoaJoystick.h"

#import "CMPreferences.h"

#include "JoystickPort.h"

#include "InputEvent.h"

#pragma mark - JoystickDevice

@implementation CMJoyPortDevice

+ (CMJoyPortDevice*)deviceLocalizedAs:(NSString*)localizationKey
                            deviceId:(NSInteger)deviceId
{
    CMJoyPortDevice *device = [[CMJoyPortDevice alloc] init];
    
    device.name = CMLoc(localizationKey);
    device.deviceId = deviceId;
    device.isKeyConfigurable = (deviceId == JOYSTICK_PORT_JOYSTICK);
    
    return [device autorelease];
}

- (void)dealloc
{
    self.name = nil;
    
    [super dealloc];
}

@end

@implementation CMCocoaJoystick

- (id)init
{
    if ((self = [super init]))
    {
        [self resetState];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setEmulatorHasFocus:(BOOL)emulatorHasFocus
{
    
}

- (void)resetState
{
    inputEventReset();
}

+ (NSArray*)supportedDevices
{
    return [NSArray arrayWithObjects:
            [CMJoyPortDevice deviceLocalizedAs:@"NoDevice"
                                     deviceId:JOYSTICK_PORT_NONE],
            [CMJoyPortDevice deviceLocalizedAs:@"TwoButtonJoystick"
                                     deviceId:JOYSTICK_PORT_JOYSTICK],
            [CMJoyPortDevice deviceLocalizedAs:@"Mouse"
                                     deviceId:JOYSTICK_PORT_MOUSE],
            [CMJoyPortDevice deviceLocalizedAs:@"Tetris2Dongle"
                                     deviceId:JOYSTICK_PORT_TETRIS2DONGLE],
            [CMJoyPortDevice deviceLocalizedAs:@"GunStick"
                                     deviceId:JOYSTICK_PORT_GUNSTICK],
            [CMJoyPortDevice deviceLocalizedAs:@"MagicKey"
                                     deviceId:JOYSTICK_PORT_MAGICKEYDONGLE],
            [CMJoyPortDevice deviceLocalizedAs:@"AsciiPlusLaser"
                                     deviceId:JOYSTICK_PORT_ASCIILASER],
            [CMJoyPortDevice deviceLocalizedAs:@"ArkanoidPad"
                                     deviceId:JOYSTICK_PORT_ARKANOID_PAD],
            nil];
}

#pragma mark - BlueMSX Callbacks

UInt8 archJoystickGetState(int joystickNo) { return 0; }

@end
