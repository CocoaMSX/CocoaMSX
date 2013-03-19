//
//  CMGamepadManager.m
//  CocoaMSX
//
//  Created by Akop Karapetyan on 3/18/13.
//  Copyright (c) 2013 Akop Karapetyan. All rights reserved.
//

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
        
        hidManager = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        
        NSMutableDictionary* criterion = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          @(kHIDPage_GenericDesktop), (NSString *)CFSTR(kIOHIDDeviceUsagePageKey),
                                          @(kHIDUsage_GD_GamePad), (NSString *)CFSTR(kIOHIDDeviceUsageKey),
                                          nil];
        
        IOHIDManagerSetDeviceMatching(hidManager, (CFDictionaryRef)criterion);
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
    CMGamepad *gamepad = [CMGamepad gamepadWithHidDevice:device];
    [gamepad setDelegate:self];
    
    [gamepads setObject:gamepad
                 forKey:@((NSInteger)device)];
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