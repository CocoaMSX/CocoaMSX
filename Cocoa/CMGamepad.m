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
#import "CMGamepad.h"

#import "CMGamepadManager.h"

#import <IOKit/hid/IOHIDLib.h>

#define AXIS_CENTER 127

#pragma mark - CMGamepad

static void gamepadInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value);

@interface CMGamepad()

- (void)unregisterFromEvents;

- (void)didReceiveInputValue:(IOHIDValueRef)valueRef;

@end

@implementation CMGamepad

@synthesize delegate = _delegate;
@synthesize gamepadId = _gamepadId;
@synthesize vendorId = _vendorId;
@synthesize productId = _productId;
@synthesize locationId = _locationId;
@synthesize name = _name;

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
        
        _vendorId = 0;
        _productId = 0;
        
        CFTypeRef tCFTypeRef;
        CFTypeID numericTypeId = CFNumberGetTypeID();
        
        tCFTypeRef = IOHIDDeviceGetProperty(hidDevice, CFSTR(kIOHIDVendorIDKey));
		if (tCFTypeRef && CFGetTypeID(tCFTypeRef) == numericTypeId)
            CFNumberGetValue((CFNumberRef)tCFTypeRef, kCFNumberSInt32Type, &_vendorId);
        
        tCFTypeRef = IOHIDDeviceGetProperty(hidDevice, CFSTR(kIOHIDProductIDKey));
		if (tCFTypeRef && CFGetTypeID(tCFTypeRef) == numericTypeId)
            CFNumberGetValue((CFNumberRef)tCFTypeRef, kCFNumberSInt32Type, &_productId);
        
        tCFTypeRef = IOHIDDeviceGetProperty(hidDevice, CFSTR(kIOHIDLocationIDKey));
		if (tCFTypeRef && CFGetTypeID(tCFTypeRef) == numericTypeId)
            CFNumberGetValue((CFNumberRef)tCFTypeRef, kCFNumberSInt32Type, &_locationId);
        
        _name = [(NSString *)IOHIDDeviceGetProperty(hidDevice, CFSTR(kIOHIDProductKey)) retain];
    }
    
    return self;
}

- (void)dealloc
{
    [self unregisterFromEvents];
    
    IOObjectRelease(hidDevice);
    
    [_name release];
    
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

- (NSString *)vendorProductString
{
    return [NSString stringWithFormat:@"%04lx:%04lx",
            (long)[self vendorId], (long)[self productId]];
}

- (NSInteger)vendorProductId
{
    return (_vendorId << 16) | _productId;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (0x%04lx:0x%04lx)",
            [self name], (long)[self vendorId], (long)[self productId]];
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
            if ([_delegate respondsToSelector:@selector(gamepad:xChanged:center:eventData:)])
            {
                CMGamepadEventData *eventData = [[[CMGamepadEventData alloc] init] autorelease];
                [eventData setSourceId:IOHIDElementGetCookie(element)];
                
                [_delegate gamepad:self
                          xChanged:value
                            center:AXIS_CENTER
                         eventData:eventData];
            }
        }
        else if (usage == kHIDUsage_GD_Y)
        {
            if ([_delegate respondsToSelector:@selector(gamepad:yChanged:center:eventData:)])
            {
                CMGamepadEventData *eventData = [[[CMGamepadEventData alloc] init] autorelease];
                [eventData setSourceId:IOHIDElementGetCookie(element)];
                
                [_delegate gamepad:self
                          yChanged:value
                            center:AXIS_CENTER
                         eventData:eventData];
            }
        }
    }
    else if (usagePage == kHIDPage_Button)
    {
        if (!value)
        {
            if ([_delegate respondsToSelector:@selector(gamepad:buttonUp:eventData:)])
            {
                CMGamepadEventData *eventData = [[[CMGamepadEventData alloc] init] autorelease];
                [eventData setSourceId:IOHIDElementGetCookie(element)];
                
                [_delegate gamepad:self
                          buttonUp:usage
                         eventData:eventData];
            }
        }
        else
        {
            if ([_delegate respondsToSelector:@selector(gamepad:buttonDown:eventData:)])
            {
                CMGamepadEventData *eventData = [[[CMGamepadEventData alloc] init] autorelease];
                [eventData setSourceId:IOHIDElementGetCookie(element)];
                
                [_delegate gamepad:self
                        buttonDown:usage
                         eventData:eventData];
            }
        }
    }
}

- (NSMutableDictionary *)currentAxisValues
{
    CFArrayRef elements = IOHIDDeviceCopyMatchingElements(hidDevice, NULL, kIOHIDOptionsTypeNone);
    NSArray *elementArray = (NSArray *)elements;
    
    NSMutableDictionary *axesAndValues = [[[NSMutableDictionary alloc] init] autorelease];
    
    [elementArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         IOHIDElementRef element = (IOHIDElementRef)obj;
         
         NSInteger usagePage = IOHIDElementGetUsagePage(element);
         if (usagePage == kHIDPage_GenericDesktop)
         {
             IOHIDElementType type = IOHIDElementGetType(element);
             if (type == kIOHIDElementTypeInput_Misc ||
                 type == kIOHIDElementTypeInput_Axis)
             {
                 NSInteger usage = IOHIDElementGetUsage(element);
                 if (usage == kHIDUsage_GD_X || usage == kHIDUsage_GD_Y)
                 {
                     IOHIDValueRef tIOHIDValueRef;
                     if (IOHIDDeviceGetValue(hidDevice, element, &tIOHIDValueRef) == kIOReturnSuccess)
                     {
                         IOHIDElementCookie cookie = IOHIDElementGetCookie(element);
                         NSInteger integerValue = IOHIDValueGetIntegerValue(tIOHIDValueRef);
                         
                         [axesAndValues setObject:@(integerValue)
                                           forKey:@((NSInteger)cookie)];
                     }
                 }
             }
         }
     }];
    
    return axesAndValues;
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