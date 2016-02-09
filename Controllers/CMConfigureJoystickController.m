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
#import "CMConfigureJoystickController.h"

#import "CMGamepadConfiguration.h"

#define STATE_PRESS_BUTTON_A 0
#define STATE_PRESS_BUTTON_B 1
#define STATE_DONE           2

#define STATE_INVALID        -1

@interface CMConfigureJoystickController ()

- (void)updateStateVisuals;
- (void)proceedToNextState;

@end

@implementation CMConfigureJoystickController

- (id)init
{
    if ((self = [super initWithWindowNibName:@"ConfigureJoystick"]))
    {
        configuration = [[CMGamepadConfiguration alloc] init];
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

- (void)gamepadDidDisconnect:(CMGamepad *)gamepad
{
    if ([gamepad gamepadId] == selectedJoypadId)
    {
        currentState = STATE_INVALID;
        [self updateStateVisuals];
    }
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
      eventData:(CMGamepadEventData *)eventData
{
    if ([gamepad gamepadId] == selectedJoypadId)
    {
        if (currentState == STATE_PRESS_BUTTON_A)
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
}

#pragma mark - Private methods

- (void) restartConfiguration:(NSInteger) joypadId
{
    currentState = 0;
    selectedJoypadId = joypadId;
    
    [configuration clear];
    
    [self updateStateVisuals];
    
    CMGamepad *gamepad = [[CMGamepadManager sharedInstance] gamepadWithId:selectedJoypadId];
    [configuration setVendorProductId:[gamepad vendorProductId]];
    
    [[self window] setTitle:[gamepad name]];
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
        case STATE_PRESS_BUTTON_A:
            [directionField setStringValue:CMLoc(@"Press Button A", @"")];
            break;
        case STATE_PRESS_BUTTON_B:
            [directionField setStringValue:CMLoc(@"Press Button B", @"")];
            break;
        case STATE_INVALID:
            [directionField setStringValue:CMLoc(@"Configuration canceled.", @"")];
            break;
        case STATE_DONE:
            [directionField setStringValue:CMLoc(@"Configuration complete.", @"")];
            break;
    }
    
    [saveButton setEnabled:(currentState == STATE_DONE)];
}

#pragma mark - Actions

- (void)onCancelClicked:(id)sender
{
    [[self window] close];
}

- (void)onSaveClicked:(id)sender
{
    if (_delegate)
    {
        CMGamepad *gamepad = [[CMGamepadManager sharedInstance] gamepadWithId:selectedJoypadId];
        if (gamepad)
            [_delegate gamepadDidConfigure:gamepad
                             configuration:[[configuration copy] autorelease]];
    }
    
    [[self window] close];
}

@end
