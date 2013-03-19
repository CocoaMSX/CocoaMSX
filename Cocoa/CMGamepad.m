//
//  CMGamepad.m
//  CocoaMSX
//
//  Created by Akop Karapetyan on 3/18/13.
//  Copyright (c) 2013 Akop Karapetyan. All rights reserved.
//

#import "CMGamepad.h"

#define AXIS_CENTER 127

#pragma mark - CMGamepadEvent

@interface CMGamepadEvent ()

+ (CMGamepadEvent *)gamepadEventWithUsagePage:(NSInteger)usagePage
                                        usage:(NSInteger)usage
                                        value:(NSInteger)value;

@end

@implementation CMGamepadEvent

+ (CMGamepadEvent *)gamepadEventWithUsagePage:(NSInteger)usagePage
                                        usage:(NSInteger)usage
                                        value:(NSInteger)value
{
    CMGamepadEvent *gamepadEvent = [[CMGamepadEvent alloc] initWithUsagePage:usagePage
                                                                       usage:usage
                                                                       value:value];
    
    return [gamepadEvent autorelease];
}

- (id)initWithUsagePage:(NSInteger)usagePage
                  usage:(NSInteger)usage
                  value:(NSInteger)value
{
    if ((self = [self init]))
    {
        _usagePage = usagePage;
        _usage = usage;
        _value = value;
    }
    
    return self;
}

- (NSInteger)usagePage
{
    return _usagePage;
}

- (NSInteger)usage
{
    return _usage;
}

- (NSInteger)value
{
    return _value;
}

@end

#pragma mark - CMGamepad

static void gamepadInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value);

@interface CMGamepad()

- (void)registerForEvents;
- (void)unregisterFromEvents;

- (void)gamepadDidConnect:(CMGamepad *)gamepad;
- (void)gamepadDidDisconnect:(CMGamepad *)gamepad;

- (void)gamepad:(CMGamepad *)gamepad
       xChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event;
- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event;

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
          event:(CMGamepadEvent *)event;
- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
          event:(CMGamepadEvent *)event;

- (void)didReceiveInputValue:(IOHIDValueRef)valueRef;

@end

@implementation CMGamepad

@synthesize delegate = _delegate;

+ (id)gamepadWithHidDevice:(IOHIDDeviceRef)device
{
    return [[[CMGamepad alloc] initWithHidDevice:device] autorelease];
}

- (id)initWithHidDevice:(IOHIDDeviceRef)device
{
    if ((self = [self init]))
    {
        registeredForEvents = NO;
        hidDevice = device;
        
        IOObjectRetain(hidDevice);
        
        deviceProperties = [[NSMutableDictionary alloc] init];
        [deviceProperties setObject:(NSString *)IOHIDDeviceGetProperty(hidDevice, CFSTR(kIOHIDProductKey))
                             forKey:@"productKey"];
        
        [self registerForEvents];
    }
    
    return self;
}

- (void)dealloc
{
    [self unregisterFromEvents];
    
    IOObjectRelease(hidDevice);
    [deviceProperties release];
    
    [super dealloc];
}

- (void)registerForEvents
{
    if (!registeredForEvents)
    {
        IOHIDDeviceOpen(hidDevice, kIOHIDOptionsTypeNone);
        IOHIDDeviceRegisterInputValueCallback(hidDevice, gamepadInputValueCallback, self);
        
        registeredForEvents = YES;
        
        [self gamepadDidConnect:self];
    }
}

- (void)unregisterFromEvents
{
    if (registeredForEvents)
    {
//        IOHIDDeviceClose(hidDevice, kIOHIDOptionsTypeNone);
        
        registeredForEvents = NO;
        
        [self gamepadDidDisconnect:self];
    }
}

- (NSString *)name
{
    return [deviceProperties objectForKey:@"productKey"];
}

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
        [_delegate gamepad:gamepad
                  xChanged:newValue
                    center:center
                     event:event];
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepad:gamepad
                  yChanged:newValue
                    center:center
                     event:event];
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepad:gamepad
                buttonDown:index
                     event:event];
}

- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    if ([_delegate respondsToSelector:_cmd])
        [_delegate gamepad:gamepad
                  buttonUp:index
                     event:event];
}

- (void)didReceiveInputValue:(IOHIDValueRef)valueRef
{
    IOHIDElementRef element = IOHIDValueGetElement(valueRef);
    
    NSInteger usagePage = IOHIDElementGetUsagePage(element);
    NSInteger usage = IOHIDElementGetUsage(element);
    NSInteger value = IOHIDValueGetIntegerValue(valueRef);
    
    CMGamepadEvent *event = [CMGamepadEvent gamepadEventWithUsagePage:usagePage
                                                                usage:usage
                                                                value:value];
    
    if (usagePage == kHIDPage_GenericDesktop)
    {
        if (usage == kHIDUsage_GD_X)
        {
            [self gamepad:self
                 xChanged:value
                   center:AXIS_CENTER
                    event:event];
        }
        else if (usage == kHIDUsage_GD_Y)
        {
            [self gamepad:self
                 yChanged:value
                   center:AXIS_CENTER
                    event:event];
        }
    }
    else if (usagePage == kHIDPage_Button)
    {
        if (!value)
        {
            [self gamepad:self
                 buttonUp:usage
                    event:event];
        }
        else
        {
            [self gamepad:self
               buttonDown:usage
                    event:event];
        }
    }
}

@end

#pragma mark - IOHID C Callbacks

static void gamepadInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
    @autoreleasepool
    {
        [(CMGamepad *)context didReceiveInputValue:value];
    }
}