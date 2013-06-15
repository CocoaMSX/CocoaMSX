/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2013 Akop Karapetyan
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
#import "CMConfigureJoystickController.h"

#define STATE_PRESS_BUTTON_A 0
#define STATE_PRESS_BUTTON_B 1

@interface CMConfigureJoystickController ()

- (void)updateStateVisuals;

@end

@implementation CMConfigureJoystickController

- (id)init
{
    if ((self = [super initWithWindowNibName:@"ConfigureJoystick"]))
    {
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self updateStateVisuals];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    NSLog(@"CMConfigureJoystick: Starting gamepad observation ...");
    [[CMGamepadManager sharedInstance] addObserver:self];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    NSLog(@"CMConfigureJoystick: Stopping gamepad observation ...");
    [[CMGamepadManager sharedInstance] removeObserver:self];
}

#pragma mark - CMGamepadDelegate

- (void)gamepad:(CMGamepad *)gamepad
       xChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event
{
    NSLog(@"(%@) x changed: %ld/%ld", [gamepad name], newValue, center);
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event
{
    NSLog(@"(%@) y changed: %ld/%ld", [gamepad name], newValue, center);
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    NSLog(@"(%@) button down", [gamepad name]);
    currentState++;
    
    [self updateStateVisuals];
}

- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    NSLog(@"(%@) button up", [gamepad name]);
}

- (void)restartConfiguration
{
    currentState = STATE_PRESS_BUTTON_A;
    
    [self updateStateVisuals];
}

- (void)updateStateVisuals
{
    switch(currentState)
    {
        case STATE_PRESS_BUTTON_A:
            [directionField setStringValue:CMLoc(@"Press button A on the gamepad")];
            break;
        case STATE_PRESS_BUTTON_B:
            [directionField setStringValue:CMLoc(@"Press button B on the gamepad")];
            break;
    }
}

@end
