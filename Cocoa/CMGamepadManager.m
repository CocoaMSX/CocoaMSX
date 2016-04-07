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
#import "CMGamepadManager.h"
#import "CMGamepad.h"

#pragma mark - CMGamepadManager

void gamepadWasAdded(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef device);
void gamepadWasRemoved(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef device);

@interface CMGamepadManager ()

- (void) deviceDidConnect:(IOHIDDeviceRef) device;
- (void) deviceDidDisconnect:(IOHIDDeviceRef) device;
- (void) renumber:(BOOL) sort;

@end

@implementation CMGamepadManager
{
	IOHIDManagerRef _hidManager;
	NSMutableDictionary<NSNumber *, CMGamepad *> *_gamepadsByDeviceId;
	NSMutableArray<CMGamepad *> *_allGamepads;
	NSMutableArray *_observers;
}

+ (instancetype) sharedInstance
{
	static dispatch_once_t once;
	static id sharedInstance;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	
	return sharedInstance;
}

- (id)init
{
    if ((self = [super init]))
    {
		_gamepadsByDeviceId = [NSMutableDictionary dictionary];
		_allGamepads = [NSMutableArray array];
        _observers = [NSMutableArray array];
        _hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        
		NSMutableDictionary *gamepadCriterion = [@{ (NSString *) CFSTR(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
													(NSString *) CFSTR(kIOHIDDeviceUsageKey):  @(kHIDUsage_GD_GamePad) } mutableCopy];
		NSMutableDictionary *joystickCriterion = [@{ (NSString *) CFSTR(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
													(NSString *) CFSTR(kIOHIDDeviceUsageKey):  @(kHIDUsage_GD_Joystick) } mutableCopy];
		
        IOHIDManagerSetDeviceMatchingMultiple(_hidManager, (__bridge CFArrayRef) @[ gamepadCriterion, joystickCriterion ]);
        IOHIDManagerRegisterDeviceMatchingCallback(_hidManager, gamepadWasAdded, (__bridge void *) self);
        IOHIDManagerRegisterDeviceRemovalCallback(_hidManager, gamepadWasRemoved, (__bridge void *) self);
        
        IOHIDManagerScheduleWithRunLoop(_hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    
    return self;
}

- (void) dealloc
{
    IOHIDManagerUnscheduleFromRunLoop(_hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(_hidManager);
}

- (void) deviceDidConnect:(IOHIDDeviceRef) device
{
	CMGamepad *gamepad;
	@synchronized (_gamepadsByDeviceId) {
		gamepad = [[CMGamepad alloc] initWithHidDevice:device];
		[_gamepadsByDeviceId setObject:gamepad
								forKey:@([gamepad gamepadId])];
		
		[_allGamepads addObject:gamepad];
		[self renumber:YES];
		
		[gamepad setDelegate:self];
	}
	
	[gamepad registerForEvents];
}

- (void) deviceDidDisconnect:(IOHIDDeviceRef) device
{
	@synchronized (_gamepadsByDeviceId) {
		CMGamepad *gamepad = [_gamepadsByDeviceId objectForKey:@((NSInteger) device)];
		if (gamepad) {
			[_gamepadsByDeviceId removeObjectForKey:@([gamepad gamepadId])];
			[_allGamepads removeObjectAtIndex:[gamepad index]];
			[self renumber:NO];
		}
	}
}

- (CMGamepad *) gamepadWithId:(NSInteger) gamepadId
{
    return [_gamepadsByDeviceId objectForKey:@(gamepadId)];
}

- (CMGamepad *) gamepadAtIndex:(NSUInteger) index
{
	CMGamepad *gp = nil;
	if (index < [_allGamepads count]) {
		gp = [_allGamepads objectAtIndex:index];
	}
	
	return gp;
}

#pragma mark - CMGamepadDelegate

- (void)gamepadDidConnect:(CMGamepad *)gamepad
{
    [_observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
		 if ([obj respondsToSelector:_cmd]) {
             [obj gamepadDidConnect:gamepad];
		 }
     }];
}

- (void)gamepadDidDisconnect:(CMGamepad *)gamepad
{
    [_observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
		 if ([obj respondsToSelector:_cmd]) {
             [obj gamepadDidDisconnect:gamepad];
		 }
     }];
}

- (void)gamepad:(CMGamepad *)gamepad
       xChanged:(NSInteger)newValue
         center:(NSInteger)center
      eventData:(CMGamepadEventData *)eventData
{
    [_observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
		 if ([obj respondsToSelector:_cmd]) {
             [obj gamepad:gamepad
                 xChanged:newValue
                   center:center
                eventData:eventData];
		 }
     }];
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
      eventData:(CMGamepadEventData *)eventData
{
    [_observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
		 if ([obj respondsToSelector:_cmd]) {
             [obj gamepad:gamepad
                 yChanged:newValue
                   center:center
                eventData:eventData];
		 }
     }];
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
      eventData:(CMGamepadEventData *)eventData
{
    [_observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
		 if ([obj respondsToSelector:_cmd]) {
             [obj gamepad:gamepad
               buttonDown:index
                eventData:eventData];
		 }
     }];
}

- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
      eventData:(CMGamepadEventData *)eventData
{
    [_observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
		 if ([obj respondsToSelector:_cmd]) {
             [obj gamepad:gamepad
                 buttonUp:index
                eventData:eventData];
		 }
     }];
}

- (void) addObserver:(id<CMGamepadEventDelegate>) observer
{
    [_observers addObject:observer];
}

- (void) removeObserver:(id<CMGamepadEventDelegate>) observer
{
    [_observers removeObject:observer];
}

#pragma mark - Private

- (void) renumber:(BOOL) sort
{
	@synchronized (_allGamepads) {
		if (sort) {
			[_allGamepads sortUsingComparator:^NSComparisonResult(CMGamepad *gp1, CMGamepad *gp2) {
				return [gp1 locationId] - [gp2 locationId];
			}];
		}
		[_allGamepads enumerateObjectsUsingBlock:^(CMGamepad *gp, NSUInteger idx, BOOL * _Nonnull stop) {
			[gp setIndex:idx];
		}];
	}
}

@end

#pragma mark - IOHID C Callbacks

void gamepadWasAdded(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef device)
{
    @autoreleasepool {
        [((__bridge CMGamepadManager *) inContext) deviceDidConnect:device];
    }
}

void gamepadWasRemoved(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef device)
{
    @autoreleasepool {
        [((__bridge CMGamepadManager *) inContext) deviceDidDisconnect:device];
    }
}
