/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2014 Akop Karapetyan
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

#define STATE_CENTER         0
#define STATE_PRESS_UP       1
#define STATE_PRESS_DOWN     2
#define STATE_PRESS_LEFT     3
#define STATE_PRESS_RIGHT    4
#define STATE_PRESS_BUTTON_A 5
#define STATE_PRESS_BUTTON_B 6
#define STATE_DONE           7

#define STATE_INVALID        -1

@interface CMConfigureJoystickController ()

- (void)updateStateVisuals;
- (void)proceedToNextState;

@end

@implementation CMConfigureJoystickController

@synthesize delegate = _delegate;

- (id)init
{
    if ((self = [super initWithWindowNibName:@"ConfigureJoystick"]))
    {
        configuration = [[CMGamepadConfiguration alloc] init];
        allAxisValues = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [allAxisValues release];
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
       xChanged:(NSInteger)newValue
         center:(NSInteger)center
      eventData:(CMGamepadEventData *)eventData
{
    if ([gamepad gamepadId] == selectedJoypadId)
    {
        if (currentState == STATE_PRESS_LEFT || currentState == STATE_PRESS_RIGHT)
        {
            if ([configuration centerX] == NSIntegerMin)
            {
                NSNumber *centerValue = [allAxisValues objectForKey:@([eventData sourceId])];
                if (centerValue)
                    [configuration setCenterX:[centerValue integerValue]];
            }
            
            if ([configuration centerX] != NSIntegerMin)
            {
                if (currentState == STATE_PRESS_LEFT && newValue < [configuration centerX])
                {
                    [configuration setMinX:newValue];
                    [self proceedToNextState];
                }
                else if (currentState == STATE_PRESS_RIGHT  && newValue > [configuration centerX])
                {
                    [configuration setMaxX:newValue];
                    [self proceedToNextState];
                }
            }
        }
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
      eventData:(CMGamepadEventData *)eventData
{
    if ([gamepad gamepadId] == selectedJoypadId)
    {
        if (currentState == STATE_PRESS_UP || currentState == STATE_PRESS_DOWN)
        {
            if ([configuration centerY] == NSIntegerMin)
            {
                NSNumber *centerValue = [allAxisValues objectForKey:@([eventData sourceId])];
                if (centerValue)
                    [configuration setCenterY:[centerValue integerValue]];
            }
            
            if ([configuration centerY] != NSIntegerMin)
            {
                if (currentState == STATE_PRESS_UP && newValue < [configuration centerY])
                {
                    [configuration setMinY:newValue];
                    [self proceedToNextState];
                }
                else if (currentState == STATE_PRESS_DOWN  && newValue > [configuration centerY])
                {
                    [configuration setMaxY:newValue];
                    [self proceedToNextState];
                }
            }
        }
    }
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
      eventData:(CMGamepadEventData *)eventData
{
    if ([gamepad gamepadId] == selectedJoypadId)
    {
        if (currentState == STATE_CENTER)
        {
            CMGamepad *gamepad = [[CMGamepadManager sharedInstance] gamepadWithId:selectedJoypadId];
            
            [allAxisValues removeAllObjects];
            [allAxisValues addEntriesFromDictionary:[gamepad currentAxisValues]];
            
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
}

#pragma mark - Private methods

- (void)restartConfiguration:(NSInteger)joypadId
{
    currentState = 0;
    selectedJoypadId = joypadId;
    
    [configuration clear];
    
    [allAxisValues removeAllObjects];
    
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
        case STATE_CENTER:
            [directionField setStringValue:CMLoc(@"Release the directional controls then press any button", @"")];
            break;
        case STATE_PRESS_UP:
            [directionField setStringValue:CMLoc(@"Press Up", @"")];
            break;
        case STATE_PRESS_DOWN:
            [directionField setStringValue:CMLoc(@"Press Down", @"")];
            break;
        case STATE_PRESS_LEFT:
            [directionField setStringValue:CMLoc(@"Press Left", @"")];
            break;
        case STATE_PRESS_RIGHT:
            [directionField setStringValue:CMLoc(@"Press Right", @"")];
            break;
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
