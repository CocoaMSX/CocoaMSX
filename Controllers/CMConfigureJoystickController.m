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

#define STATE_CENTER         0
#define STATE_PRESS_UP       1
#define STATE_PRESS_DOWN     2
#define STATE_PRESS_LEFT     3
#define STATE_PRESS_RIGHT    4
#define STATE_PRESS_BUTTON_A 5
#define STATE_PRESS_BUTTON_B 6

#define STATE_INITIAL        STATE_CENTER

@implementation CMGamepadConfiguration

@synthesize minX = _minX;
@synthesize centerX = _centerX;
@synthesize maxX = _maxX;
@synthesize minY = _minY;
@synthesize centerY = _centerY;
@synthesize maxY = _maxY;
@synthesize buttonAIndex = _buttonAIndex;
@synthesize buttonBIndex = _buttonBIndex;

- (id)init
{
    if ((self = [super init]))
    {
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@end

@interface CMConfigureJoystickController ()

- (void)updateStateVisuals;
- (void)proceedToNextState;

@end

@implementation CMConfigureJoystickController

- (id)init
{
    if ((self = [super initWithWindowNibName:@"ConfigureJoystick"]))
    {
        configuration = nil;
    }
    
    return self;
}

- (void)dealloc
{
    [configuration release];
    
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
{
    if (currentState == STATE_PRESS_LEFT)
    {
        [configuration setMinX:newValue];
        [self proceedToNextState];
    }
    else if (currentState == STATE_PRESS_RIGHT)
    {
        [configuration setMaxX:newValue];
        [self proceedToNextState];
    }
    
    NSLog(@"(%@) x changed: %ld/%ld", [gamepad name], newValue, center);
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
{
    if (currentState == STATE_PRESS_UP)
    {
        [configuration setMinY:newValue];
        [self proceedToNextState];
    }
    else if (currentState == STATE_PRESS_DOWN)
    {
        [configuration setMaxY:newValue];
        [self proceedToNextState];
    }
    
    NSLog(@"(%@) y changed: %ld/%ld", [gamepad name], newValue, center);
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
{
    if (currentState == STATE_CENTER)
    {
        // FIXME!
//        [configuration setButtonAIndex:index];
        [self proceedToNextState];
    }
    else if (currentState == STATE_PRESS_BUTTON_A)
    {
        [configuration setButtonAIndex:index];
        [self proceedToNextState];
    }
    else if (currentState == STATE_PRESS_BUTTON_B)
    {
        [configuration setButtonBIndex:index];
        [self proceedToNextState];
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
{
    NSLog(@"(%@) button %ld up", [gamepad name], index);
}

- (void)restartConfiguration
{
    currentState = STATE_INITIAL;
    
    [configuration release];
    configuration = [[CMGamepadConfiguration alloc] init];
    
    [self updateStateVisuals];
}

- (void)proceedToNextState
{
    currentState++;
    [self updateStateVisuals];
}

- (void)updateStateVisuals
{
    switch(currentState)
    {
        case STATE_CENTER:
            [directionField setStringValue:CMLoc(@"Release all directional buttons and press any button")];
            break;
        case STATE_PRESS_UP:
            [directionField setStringValue:CMLoc(@"Press Up")];
            break;
        case STATE_PRESS_DOWN:
            [directionField setStringValue:CMLoc(@"Press Down")];
            break;
        case STATE_PRESS_LEFT:
            [directionField setStringValue:CMLoc(@"Press Left")];
            break;
        case STATE_PRESS_RIGHT:
            [directionField setStringValue:CMLoc(@"Press Right")];
            break;
        case STATE_PRESS_BUTTON_A:
            [directionField setStringValue:CMLoc(@"Press button A")];
            break;
        case STATE_PRESS_BUTTON_B:
            [directionField setStringValue:CMLoc(@"Press button B")];
            break;
    }
}

@end
