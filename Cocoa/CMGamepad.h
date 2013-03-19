//
//  CMGamepad.h
//  CocoaMSX
//
//  Created by Akop Karapetyan on 3/18/13.
//  Copyright (c) 2013 Akop Karapetyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>

@interface CMGamepadEvent : NSObject
{
    NSInteger _usagePage;
    NSInteger _usage;
    NSInteger _value;
}

- (id)initWithUsagePage:(NSInteger)usagePage
                  usage:(NSInteger)usage
                  value:(NSInteger)value;

- (NSInteger)usagePage;
- (NSInteger)usage;
- (NSInteger)value;

@end

@interface CMGamepad : NSObject
{
    id _delegate;
    
    BOOL registeredForEvents;
    IOHIDDeviceRef hidDevice;
    NSMutableDictionary *deviceProperties;
}

@property (nonatomic, assign) id delegate;

+ (id)gamepadWithHidDevice:(IOHIDDeviceRef)device;

- (id)initWithHidDevice:(IOHIDDeviceRef)device;

- (NSString *)name;

@end

@protocol CMGamepadDelegate

@optional
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

@end
