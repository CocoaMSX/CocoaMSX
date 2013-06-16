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
#import "CMGamepad.h"

#define AXIS_CENTER 127

#pragma mark - CMGamepad

static void gamepadInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value);

@interface CMGamepad()

- (NSInteger)locationId;

- (void)unregisterFromEvents;

- (void)didReceiveInputValue:(IOHIDValueRef)valueRef;

@end

@implementation CMGamepad

@synthesize delegate = _delegate;
@synthesize gamepadId = _gamepadId;

+ (NSArray *)allGamepads
{
    NSUInteger usagePage = kHIDPage_GenericDesktop;
    NSUInteger usageId = kHIDUsage_GD_GamePad;
    
    CFMutableDictionaryRef hidMatchDictionary = IOServiceMatching(kIOHIDDeviceKey);
    NSMutableDictionary *objcMatchDictionary = (NSMutableDictionary *)hidMatchDictionary;
    
    [objcMatchDictionary setObject:@(usagePage)
                            forKey:[NSString stringWithUTF8String:kIOHIDDeviceUsagePageKey]];
    [objcMatchDictionary setObject:@(usageId)
                            forKey:[NSString stringWithUTF8String:kIOHIDDeviceUsageKey]];
    
    io_iterator_t hidObjectIterator = MACH_PORT_NULL;
    NSMutableArray *gamepads = [NSMutableArray array];
    
    @try
    {
        IOServiceGetMatchingServices(kIOMasterPortDefault,
                                     hidMatchDictionary,
                                     &hidObjectIterator);
        
        if (hidObjectIterator == 0)
            return [NSArray array];
        
        io_object_t hidDevice;
        while ((hidDevice = IOIteratorNext(hidObjectIterator)))
        {
            CMGamepad *gamepad = [[CMGamepad alloc] initWithHidDevice:hidDevice];
            [gamepad autorelease];
            
            if ([gamepad locationId] == 0)
                continue;
            
            [gamepads addObject:gamepad];
        }
    }
    @finally
    {
        if (hidObjectIterator != MACH_PORT_NULL)
            IOObjectRelease(hidObjectIterator);
    }
    
    return gamepads;
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
//        [deviceProperties setObject:(NSNumber *)IOHIDDeviceGetProperty(hidDevice, CFSTR(kIOHIDSerialNumberKey))
//                             forKey:@"serialNumber"];
        [deviceProperties setObject:(NSString *)IOHIDDeviceGetProperty(hidDevice, CFSTR(kIOHIDLocationIDKey))
                             forKey:@"locationId"];
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
        
        if ([_delegate respondsToSelector:@selector(gamepadDidConnect:)])
            [_delegate gamepadDidConnect:self];
    }
}

- (void)unregisterFromEvents
{
    if (registeredForEvents)
    {
        // FIXME: why does this crash the emulator?
//        IOHIDDeviceClose(hidDevice, kIOHIDOptionsTypeNone);
        
        registeredForEvents = NO;
        
        if ([_delegate respondsToSelector:@selector(gamepadDidDisconnect:)])
            [_delegate gamepadDidDisconnect:self];
    }
}

- (NSInteger)locationId
{
    return [[deviceProperties objectForKey:@"locationId"] integerValue];
}

- (NSString *)name
{
    return [deviceProperties objectForKey:@"productKey"];
}

- (NSString *)description
{
    return [self name];
}

- (NSString *)serialNumber
{
    return [deviceProperties objectForKey:@"serialNumber"];
}

- (void)didReceiveInputValue:(IOHIDValueRef)valueRef
{
    IOHIDElementRef element = IOHIDValueGetElement(valueRef);
    
    NSInteger usagePage = IOHIDElementGetUsagePage(element);
    NSInteger usage = IOHIDElementGetUsage(element);
    NSInteger value = IOHIDValueGetIntegerValue(valueRef);
    
    if (usagePage == kHIDPage_GenericDesktop)
    {
        if (usage == kHIDUsage_GD_X)
        {
            if ([_delegate respondsToSelector:@selector(gamepad:xChanged:center:)])
                [_delegate gamepad:self
                          xChanged:value
                            center:AXIS_CENTER];
        }
        else if (usage == kHIDUsage_GD_Y)
        {
            if ([_delegate respondsToSelector:@selector(gamepad:yChanged:center:)])
                [_delegate gamepad:self
                          yChanged:value
                            center:AXIS_CENTER];
        }
    }
    else if (usagePage == kHIDPage_Button)
    {
        if (!value)
        {
            if ([_delegate respondsToSelector:@selector(gamepad:buttonUp:)])
                [_delegate gamepad:self
                          buttonUp:usage];
        }
        else
        {
            if ([_delegate respondsToSelector:@selector(gamepad:buttonDown:)])
                [_delegate gamepad:self
                        buttonDown:usage];
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