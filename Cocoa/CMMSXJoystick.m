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
#import "CMMSXJoystick.h"

#include "InputEvent.h"

#pragma mark - CMJoystickButton

@interface CMJoystickButton : NSObject
{
    NSInteger _portOneVirtualCode;
    NSInteger _portTwoVirtualCode;
    NSString *_label;
}

@property (nonatomic, assign) NSInteger portOneVirtualCode;
@property (nonatomic, assign) NSInteger portTwoVirtualCode;
@property (nonatomic, retain) NSString *label;

- (NSString *)presentationLabel;

@end

@implementation CMJoystickButton

@synthesize portOneVirtualCode = _portOneVirtualCode;
@synthesize portTwoVirtualCode = _portTwoVirtualCode;
@synthesize label = _label;

- (NSString *)presentationLabel
{
    return [self label];
}

- (void)dealloc
{
    [self setLabel:nil];
    
    [super dealloc];
}

@end

#pragma mark - CMMSXJoystick

@interface CMMSXJoystick ()

- (CMJoystickButton *)mapButtonWithPortOneVirtualCode:(NSInteger)portOneVirtualCode
                                   portTwoVirtualCode:(NSInteger)portTwoVirtualCode
                                                label:(NSString *)label;

+ (CMMSXJoystick *)twoButtonJoystick;

@end

static NSDictionary *layoutToJoystickMap;

@implementation CMMSXJoystick

+ (void)initialize
{
    layoutToJoystickMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [self twoButtonJoystick], @(CMMSXJoystickTwoButton),
                           
                           nil];
}

- (id)init
{
    if ((self = [super init]))
    {
        virtualCodeToButtonInfoMap = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [virtualCodeToButtonInfoMap release];
    
    [super dealloc];
}

- (CMJoystickButton *)mapButtonWithPortOneVirtualCode:(NSInteger)portOneVirtualCode
                                   portTwoVirtualCode:(NSInteger)portTwoVirtualCode
                                                label:(NSString *)label
{
    CMJoystickButton *button = [[[CMJoystickButton alloc] init] autorelease];
    
    [button setPortOneVirtualCode:portOneVirtualCode];
    [button setPortTwoVirtualCode:portTwoVirtualCode];
    [button setLabel:label];
    
    [virtualCodeToButtonInfoMap setObject:button forKey:@(portOneVirtualCode)];
    [virtualCodeToButtonInfoMap setObject:button forKey:@(portTwoVirtualCode)];
    
    return button;
}

- (NSString *)presentationLabelForVirtualCode:(NSInteger)keyCode
{
    return [[virtualCodeToButtonInfoMap objectForKey:@(keyCode)] presentationLabel];
}

+ (CMMSXJoystick *)joystickWithLayout:(CMMSXJoystickLayout)layout
{
    return [layoutToJoystickMap objectForKey:@(layout)];
}

+ (CMMSXJoystick *)twoButtonJoystick
{
    CMMSXJoystick *joystick = [[CMMSXJoystick alloc] init];
    
    [joystick mapButtonWithPortOneVirtualCode:EC_JOY1_BUTTON1
                           portTwoVirtualCode:EC_JOY2_BUTTON1
                                        label:CMLoc(@"Button 1", @"Joystick button")];
    [joystick mapButtonWithPortOneVirtualCode:EC_JOY1_BUTTON2
                           portTwoVirtualCode:EC_JOY2_BUTTON2
                                        label:CMLoc(@"Button 2", @"Joystick button")];
    
    [joystick mapButtonWithPortOneVirtualCode:EC_JOY1_UP
                           portTwoVirtualCode:EC_JOY2_UP
                                        label:CMLoc(@"Up", @"Joystick button")];
    [joystick mapButtonWithPortOneVirtualCode:EC_JOY1_DOWN
                           portTwoVirtualCode:EC_JOY2_DOWN
                                        label:CMLoc(@"Down", @"Joystick button")];
    [joystick mapButtonWithPortOneVirtualCode:EC_JOY1_LEFT
                           portTwoVirtualCode:EC_JOY2_LEFT
                                        label:CMLoc(@"Left", @"Joystick button")];
    [joystick mapButtonWithPortOneVirtualCode:EC_JOY1_RIGHT
                           portTwoVirtualCode:EC_JOY2_RIGHT
                                        label:CMLoc(@"Right", @"Joystick button")];
    
    return [joystick autorelease];
}

@end
