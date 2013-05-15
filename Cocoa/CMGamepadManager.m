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
#import "CMGamepadManager.h"
#import "CMGamepad.h"

void gamepadWasAdded(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef device);
void gamepadWasRemoved(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef device);

@interface CMGamepadManager ()

- (void)deviceDidConnect:(IOHIDDeviceRef)device;
- (void)deviceDidDisconnect:(IOHIDDeviceRef)device;

@end

@implementation CMGamepadManager

@synthesize delegate = _delegate;

- (id)init
{
    if ((self = [super init]))
    {
        gamepads = [[NSMutableDictionary alloc] init];
        
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        
        NSMutableDictionary *gamepadCriterion = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          @(kHIDPage_GenericDesktop), (NSString *)CFSTR(kIOHIDDeviceUsagePageKey),
                                          @(kHIDUsage_GD_GamePad), (NSString *)CFSTR(kIOHIDDeviceUsageKey),
                                          nil];
        NSMutableDictionary *joystickCriterion = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @(kHIDPage_GenericDesktop), (NSString *)CFSTR(kIOHIDDeviceUsagePageKey),
                                         @(kHIDUsage_GD_Joystick), (NSString *)CFSTR(kIOHIDDeviceUsageKey),
                                         nil];
        
        IOHIDManagerSetDeviceMatchingMultiple(hidManager, (CFArrayRef)[NSArray arrayWithObjects:gamepadCriterion, joystickCriterion, nil]);
        IOHIDManagerRegisterDeviceMatchingCallback(hidManager, gamepadWasAdded, (void *)self);
        IOHIDManagerRegisterDeviceRemovalCallback(hidManager, gamepadWasRemoved, (void *)self);
        
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    
    [gamepads release];
    
    IOHIDManagerUnscheduleFromRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(hidManager);
    
    [super dealloc];
}

- (void)deviceDidConnect:(IOHIDDeviceRef)device
{
    CMGamepad *gamepad = [[[CMGamepad alloc] initWithHidDevice:device] autorelease];
    [gamepad setDelegate:self];
    [gamepad setGamepadId:@((NSInteger)device)];
    [gamepad registerForEvents];
    
    [gamepads setObject:gamepad
                 forKey:[gamepad gamepadId]];
}

- (void)deviceDidDisconnect:(IOHIDDeviceRef)device
{
    [gamepads removeObjectForKey:@((NSInteger)device)];
}

#pragma mark - CMGamepadDelegate

- (void)gamepadDidConnect:(CMGamepad *)gamepad
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepadDidConnect:gamepad];
}

- (void)gamepadDidDisconnect:(CMGamepad *)gamepad
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepadDidDisconnect:gamepad];
}

- (void)gamepad:(CMGamepad *)gamepad
       xChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepad:gamepad xChanged:newValue center:center event:event];
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepad:gamepad yChanged:newValue center:center event:event];
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepad:gamepad buttonDown:index event:event];
}

- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepad:gamepad buttonUp:index event:event];
}

@end

#pragma mark - IOHID C Callbacks

void gamepadWasAdded(void* inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef device)
{
    @autoreleasepool
    {
        [((CMGamepadManager *) inContext) deviceDidConnect:device];
    }
}

void gamepadWasRemoved(void* inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef device)
{
    @autoreleasepool
    {
        [((CMGamepadManager *) inContext) deviceDidDisconnect:device];
    }
}