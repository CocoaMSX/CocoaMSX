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
#import "CMKeyboardManager.h"

static CMKeyboardManager *_keyboardManager = nil;

void keyWasToggled(void *context, IOReturn result, void *sender, IOHIDValueRef value);

@implementation CMKeyboardManager

+ (CMKeyboardManager *)sharedInstance
{
    if (!_keyboardManager)
        _keyboardManager = [[CMKeyboardManager alloc] init];
    
    return _keyboardManager;
}

- (id)init
{
    if ((self = [super init]))
    {
        observerLock = [[NSObject alloc] init];
        observers = [[NSMutableArray alloc] init];
        
        // Init keyboard hid management
        keyboardHidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        
        NSMutableDictionary *keyboardCriterion = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                  @(kHIDPage_GenericDesktop), (NSString *)CFSTR(kIOHIDDeviceUsagePageKey),
                                                  @(kHIDUsage_GD_Keyboard), (NSString *)CFSTR(kIOHIDDeviceUsageKey),
                                                  nil];
        NSMutableDictionary *keypadCriterion = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                @(kHIDPage_GenericDesktop), (NSString *)CFSTR(kIOHIDDeviceUsagePageKey),
                                                @(kHIDUsage_GD_Keypad), (NSString *)CFSTR(kIOHIDDeviceUsageKey),
                                                nil];
        
        IOHIDManagerSetDeviceMatchingMultiple(keyboardHidManager, (CFArrayRef)[NSArray arrayWithObjects:keyboardCriterion,
                                                                              keypadCriterion, nil]);
        
//        NSMutableDictionary *inputValueFilter = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                                  @(4), (NSString *)CFSTR(kIOHIDElementUsageMinKey),
//                                                  @(231), (NSString *)CFSTR(kIOHIDElementUsageMaxKey),
//                                                  nil];
//        IOHIDManagerSetInputValueMatching(keyboardHidManager, (CFDictionaryRef)inputValueFilter);
        IOHIDManagerRegisterInputValueCallback(keyboardHidManager, keyWasToggled, (void *)self);

        IOHIDManagerScheduleWithRunLoop(keyboardHidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDManagerOpen(keyboardHidManager, kIOHIDOptionsTypeNone);
    }
    
    return self;
}

- (void)dealloc
{
    @synchronized (observerLock)
    {
        [observers release];
    }
    
    [observerLock release];
    
    IOHIDManagerClose(keyboardHidManager, kIOHIDOptionsTypeNone);
    IOHIDManagerUnscheduleFromRunLoop(keyboardHidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(keyboardHidManager);

    [super dealloc];
}

#pragma mark - CMKeyboardEventDelegate

- (void)keyboardKeyDown:(NSInteger)scanCode
{
    @synchronized (observerLock)
    {
        [observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             if ([obj respondsToSelector:_cmd])
                 [obj keyboardKeyDown:scanCode];
         }];
    }
}

- (void)keyboardKeyUp:(NSInteger)scanCode
{
    @synchronized (observerLock)
    {
        [observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             if ([obj respondsToSelector:_cmd])
                 [obj keyboardKeyUp:scanCode];
         }];
    }
}

- (void)addObserver:(id<CMKeyboardEventDelegate>)observer
{
    @synchronized (observerLock)
    {
        [observers addObject:observer];
    }
}

- (void)removeObserver:(id<CMKeyboardEventDelegate>)observer
{
    @synchronized (observerLock)
    {
        [observers removeObject:observer];
    }
}

@end

#pragma mark - IOHID C Callbacks

void keyWasToggled(void *context, IOReturn result, void *sender,
                   IOHIDValueRef value) {
    IOHIDElementRef elem = IOHIDValueGetElement(value);
    NSInteger pressed = IOHIDValueGetIntegerValue(value);
    NSInteger scanCode = IOHIDElementGetUsage(elem);
    
    if (scanCode >= 4 && scanCode <= 231)
    {
        CMKeyboardManager *mgr = (CMKeyboardManager *)context;
        
        @autoreleasepool
        {
            if (pressed)
                [mgr keyboardKeyDown:scanCode];
            else
                [mgr keyboardKeyUp:scanCode];
        }
    }
}
