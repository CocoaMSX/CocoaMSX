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
#import <AppKit/NSEvent.h>

#import "CMCocoaInput.h"

#import "CMKeyboardInput.h"
#import "CMInputDeviceLayout.h"
#import "CMPreferences.h"

#import "CMGamepadConfiguration.h"
#import "CMEmulatorController.h"

#include "Board.h"
#include "InputEvent.h"

//#define DEBUG_KEY_STATE
//#define DEBUG_JOY_STATE

NSString *const CMKeyPasteStarted = @"com.akop.CocoaMSX.KeyPasteStarted";
NSString *const CMKeyPasteEnded   = @"com.akop.CocoaMSX.KeyPasteEnded";

// These values should correspond to the matrix indices on Preferences.xib
#define CMPreferredMacDeviceJoystick             0
#define CMPreferredMacDeviceJoystickThenKeyboard 1
#define CMPreferredMacDeviceKeyboard             2

#define CMJoystickDeadzoneWidth 50

#define CMAutoPressHoldDuration    ((UInt64) 91480000000)
#define CMAutoPressReleaseDuration ((UInt64) 61480000000)

#define CMMakeMsxKeyInfo(d, s) \
    [CMMsxKeyInfo keyInfoWithDefaultStateLabel:d shiftedStateLabel:s]

#pragma mark - CMMsxKeyInfo

@interface CMMsxKeyInfo : NSObject

@property (nonatomic, copy) NSString *defaultStateLabel;
@property (nonatomic, copy) NSString *shiftedStateLabel;

@end

@implementation CMMsxKeyInfo

+ (CMMsxKeyInfo *)keyInfoWithDefaultStateLabel:(NSString *)defaultStateLabel
                             shiftedStateLabel:(NSString *)shiftedStateLabel
{
    CMMsxKeyInfo *info = [[CMMsxKeyInfo alloc] init];
    
    [info setDefaultStateLabel:defaultStateLabel];
    [info setShiftedStateLabel:shiftedStateLabel];
    
    return info;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NSString class]])
    {
        if ([_defaultStateLabel isEqualToString:object])
            return YES;
        if ([_shiftedStateLabel isEqualToString:object])
            return YES;
    }
    
    return [super isEqual:object];
}

@end

#pragma mark - CMCocoaInput

@interface CMCocoaInput ()

- (void)reloadConfigurations;
- (void)stopPasting;
- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;
- (NSInteger) virtualCodeMappedTo:(NSInteger) code
					configuration:(CMGamepadConfiguration *) config
							 port:(NSInteger) port;

@end

static NSArray<NSString *> *defaultsToObserve;

@implementation CMCocoaInput
{
	int virtualCodeMap[256];
	NSUInteger pollCounter;

	NSMutableArray *keysToPaste;
	int pasteIndex;
	BOOL pasteState;
	UInt64 timeOfAutoPress;
	
	NSInteger preferredDevices[2];
	NSMutableDictionary<NSNumber *, CMGamepadConfiguration *> *joypadConfigurations;
}

#define virtualCodeSet(eventCode) self->virtualCodeMap[eventCode] = 1
#define virtualCodeUnset(eventCode) self->virtualCodeMap[eventCode] = 0
#define virtualCodeClear() memset(self->virtualCodeMap, 0, sizeof(self->virtualCodeMap));

+ (void) initialize
{
	defaultsToObserve = @[ @"joypadConfigurations",
						   @"joystickPreferredMacDevicePort1",
						   @"joystickPreferredMacDevicePort2" ];
}

- (id)init
{
    if ((self = [super init]))
    {
        keysToPaste = [[NSMutableArray alloc] init];
        joypadConfigurations = [[NSMutableDictionary alloc] init];
        timeOfAutoPress = 0;
		pasteIndex = 0;
        
        [[CMGamepadManager sharedInstance] addObserver:self];
        
        [self reloadConfigurations];
        [self resetState];
		
		[defaultsToObserve enumerateObjectsUsingBlock:^(NSString *keyPath, NSUInteger idx, BOOL * _Nonnull stop) {
			[[NSUserDefaults standardUserDefaults] addObserver:self
													forKeyPath:keyPath
													   options:0
													   context:NULL];
		}];
		
		preferredDevices[0] = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
		preferredDevices[1] = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
    return self;
}

- (void)dealloc
{
	[defaultsToObserve enumerateObjectsUsingBlock:^(NSString *keyPath, NSUInteger idx, BOOL * _Nonnull stop) {
		[[NSUserDefaults standardUserDefaults] removeObserver:self
												   forKeyPath:keyPath];
	}];
	
    [[CMGamepadManager sharedInstance] removeObserver:self];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
#ifdef DEBUG
    NSLog(@"CMCocoaInput: reloading configuration");
#endif
	if ([@"joypadConfigurations" isEqualToString:keyPath]) {
		[self reloadConfigurations];
	} else if ([@"joystickPreferredMacDevicePort1" isEqualToString:keyPath]) {
		preferredDevices[0] = [[NSUserDefaults standardUserDefaults] integerForKey:keyPath];
	} else if ([@"joystickPreferredMacDevicePort2" isEqualToString:keyPath]) {
		preferredDevices[1] = [[NSUserDefaults standardUserDefaults] integerForKey:keyPath];
	}
}

#pragma mark - Private methods

- (void)reloadConfigurations
{
    [joypadConfigurations removeAllObjects];
    
    NSDictionary *configurations = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"joypadConfigurations"];
    [configurations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        CMGamepadConfiguration *config = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
        [joypadConfigurations setObject:config
                                 forKey:@([config vendorProductId])];
    }];
#ifdef DEBUG
    NSLog(@"CMCocoaInput: Loaded %ld gamepad configurations",
          (NSInteger)[configurations count]);
#endif
}

#pragma mark - Public methods

- (BOOL) pasteText:(NSString *) text
		layoutName:(NSString *) layoutName
{
    CMMSXKeyboard *keyboardLayout = [CMMSXKeyboard keyboardWithLayoutName:layoutName];
	if (!keyboardLayout) {
        return NO; // Invalid key layout
	}
	
	// FIXME: stop paste if in process
#ifdef DEBUG
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
#endif
    
    NSMutableArray *textAsKeyCombinations = [NSMutableArray array];
    for (int i = 0, n = [text length]; i < n; i++) {
        NSString *character = [text substringWithRange:NSMakeRange(i, 1)];
        CMMSXKeyCombination *keyCombination = [keyboardLayout keyCombinationForCharacter:character];
		if (keyCombination) {
            [textAsKeyCombinations addObject:keyCombination];
		}
    }
    
    if ([textAsKeyCombinations count] > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CMKeyPasteStarted
                                                            object:self
                                                          userInfo:nil];
        
#ifdef DEBUG
    NSLog(@"Pasting %ld keys", [textAsKeyCombinations count]);
#endif
		
		timeOfAutoPress = boardSystemTime64();
		pasteIndex = 0;
		pasteState = YES;
		
		[keysToPaste removeAllObjects];
		[keysToPaste addObjectsFromArray:textAsKeyCombinations];
		
#ifdef DEBUG
    NSLog(@"pasteText: Took %.02fms",
          [NSDate timeIntervalSinceReferenceDate] - startTime);
#endif
    }
    
    return YES;
}

- (void)releaseAllKeys
{
    virtualCodeClear();
}

- (void)resetState
{
    [self releaseAllKeys];
    [self stopPasting];
    
    // Clear currently held keys
    timeOfAutoPress = 0;
    pollCounter = 0;
}

- (void)setEmulatorHasFocus:(BOOL)focus
{
    if (!focus)
    {
#ifdef DEBUG
        NSLog(@"CocoaKeyboard: -Focus");
#endif
        // Emulator has lost focus - release all virtual keys
        [self releaseAllKeys];
        
        // Stop listening for key events
        [[CMKeyboardManager sharedInstance] removeObserver:self];
    }
    else
    {
#ifdef DEBUG
        NSLog(@"CocoaKeyboard: +Focus");
#endif
        // Start listening for key events
        [[CMKeyboardManager sharedInstance] addObserver:self];
    }
}

#pragma mark - Private methods

- (NSInteger) virtualCodeMappedTo:(NSInteger) code
					configuration:(CMGamepadConfiguration *) config
							 port:(NSInteger) port
{
	if ([config up] == code) {
		return port == 0 ? EC_JOY1_UP : EC_JOY2_UP;
	} else if ([config down] == code) {
		return port == 0 ? EC_JOY1_DOWN : EC_JOY2_DOWN;
	} else if ([config left] == code) {
		return port == 0 ? EC_JOY1_LEFT : EC_JOY2_LEFT;
	} else if ([config right] == code) {
		return port == 0 ? EC_JOY1_RIGHT : EC_JOY2_RIGHT;
	} else if ([config buttonA] == code) {
		return port == 0 ? EC_JOY1_BUTTON1 : EC_JOY2_BUTTON1;
	} else if ([config buttonB] == code) {
		return port == 0 ? EC_JOY1_BUTTON2 : EC_JOY2_BUTTON2;
	}
	
	return EC_NONE;
}

- (void)stopPasting
{
	if (pasteIndex < [keysToPaste count]) {
		pasteIndex = 0;
		timeOfAutoPress = 0;
		[keysToPaste removeAllObjects];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:CMKeyPasteEnded
															object:self
														  userInfo:nil];
	}
}

- (void)handleKeyEventForInput:(CMKeyboardInput *)input
                        layout:(CMInputDeviceLayout *)layout
                        isDown:(BOOL)isDown
{
    NSInteger virtualCode = [layout virtualCodeForInputMethod:input];
    if (virtualCode != CMUnknownVirtualCode) {
		if (isDown) {
            virtualCodeSet(virtualCode);
		} else {
            virtualCodeUnset(virtualCode);
		}
    }
}

- (void) handleKeyEvent:(NSInteger) keyCode
				 isDown:(BOOL) isDown
{
    CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:keyCode];
    
    [self handleKeyEventForInput:input
                          layout:[theEmulator keyboardLayout]
                          isDown:isDown];
	
	CMGamepadConfiguration *config;
	NSInteger vc;
	
	if (preferredDevices[0] == CMPreferredMacDeviceKeyboard ||
		(preferredDevices[0] == CMPreferredMacDeviceJoystickThenKeyboard &&
		 [[CMGamepadManager sharedInstance] gamepadCount] < 1)) {
		if (!(config = [joypadConfigurations objectForKey:@CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_1])) {
			config = [CMGamepadConfiguration defaultKeyboardPlayerOneConfiguration];
		}
		if ((vc = [self virtualCodeMappedTo:CMMakeKey(keyCode)
							  configuration:config
									   port:0]) != EC_NONE) {
			if (isDown) {
				virtualCodeSet(vc);
			} else {
				virtualCodeUnset(vc);
			}
		}
	}
	
	if (preferredDevices[1] == CMPreferredMacDeviceKeyboard ||
		(preferredDevices[1] == CMPreferredMacDeviceJoystickThenKeyboard &&
		 [[CMGamepadManager sharedInstance] gamepadCount] < 2)) {
			if (!(config = [joypadConfigurations objectForKey:@CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_2])) {
				config = [CMGamepadConfiguration defaultKeyboardPlayerTwoConfiguration];
			}
			if ((vc = [self virtualCodeMappedTo:CMMakeKey(keyCode)
								  configuration:config
										   port:1]) != EC_NONE) {
				if (isDown) {
					virtualCodeSet(vc);
				} else {
					virtualCodeUnset(vc);
				}
			}
	}
}

- (void)updateKeyboardState
{
    pollCounter++;
    
    // Reset the key matrix
    
    memcpy(eventMap, self->virtualCodeMap, sizeof(self->virtualCodeMap));
	
	if (pasteIndex < [keysToPaste count]) {
		UInt64 now = boardSystemTime64();
		UInt64 autoKeyPressInterval = now - timeOfAutoPress;
		
		CMMSXKeyCombination *kc = [keysToPaste objectAtIndex:pasteIndex];
		if (pasteState) {
			if ([kc stateFlags] & CMMSXKeyStateShift) {
				inputEventSet(EC_LSHIFT);
			}
			inputEventSet([kc virtualCode]);
			
			if (autoKeyPressInterval > CMAutoPressHoldDuration) {
				pasteState = !pasteState;
				timeOfAutoPress = now;
			}
		} else if (autoKeyPressInterval > CMAutoPressReleaseDuration) {
			pasteState = !pasteState;
			timeOfAutoPress = now;
			pasteIndex++;
		}
	}
}

#pragma mark - CMKeyboardEventDelegate

- (void)keyStateChanged:(CMKeyEventData *)event
                 isDown:(BOOL)isDown
{
#ifdef DEBUG_KEY_STATE
    if (isDown)
        NSLog(@"keyboardKeyDown:%lx", [event keyCode]);
    else
        NSLog(@"keyboardKeyUp:%lx", [event keyCode]);
#endif
    
    if (isDown)
    {
        if ([event keyCode] == 53) // Escape
            [self stopPasting];
    }
    
    // Don't generate a KeyDown if Command is pressed
    if (([NSEvent modifierFlags] & NSCommandKeyMask) == 0 || !isDown)
    {
        [self handleKeyEvent:[event keyCode]
                      isDown:isDown];
    }
}

#pragma mark - CMGamepadDelegate

- (void) gamepadDidConnect:(CMGamepad *) gamepad
{
#if DEBUG
	NSLog(@"Gamepad \"%@\" connected to port %i",
		  [gamepad name], (int) [gamepad index]);
#endif
	switch ([gamepad index]) {
		case 0:
			virtualCodeUnset(EC_JOY1_UP);
			virtualCodeUnset(EC_JOY1_DOWN);
			virtualCodeUnset(EC_JOY1_LEFT);
			virtualCodeUnset(EC_JOY1_RIGHT);
			virtualCodeUnset(EC_JOY1_BUTTON1);
			virtualCodeUnset(EC_JOY1_BUTTON2);
			break;
		case 1:
			virtualCodeUnset(EC_JOY2_UP);
			virtualCodeUnset(EC_JOY2_DOWN);
			virtualCodeUnset(EC_JOY2_LEFT);
			virtualCodeUnset(EC_JOY2_RIGHT);
			virtualCodeUnset(EC_JOY2_BUTTON1);
			virtualCodeUnset(EC_JOY2_BUTTON2);
			break;
	}
}

- (void) gamepadDidDisconnect:(CMGamepad *) gamepad
{
#if DEBUG
	NSLog(@"Gamepad \"%@\" disconnected from port %i",
		  [gamepad name], (int) [gamepad index]);
#endif
	switch ([gamepad index]) {
		case 0:
			virtualCodeUnset(EC_JOY1_UP);
			virtualCodeUnset(EC_JOY1_DOWN);
			virtualCodeUnset(EC_JOY1_LEFT);
			virtualCodeUnset(EC_JOY1_RIGHT);
			virtualCodeUnset(EC_JOY1_BUTTON1);
			virtualCodeUnset(EC_JOY1_BUTTON2);
			break;
		case 1:
			virtualCodeUnset(EC_JOY2_UP);
			virtualCodeUnset(EC_JOY2_DOWN);
			virtualCodeUnset(EC_JOY2_LEFT);
			virtualCodeUnset(EC_JOY2_RIGHT);
			virtualCodeUnset(EC_JOY2_BUTTON1);
			virtualCodeUnset(EC_JOY2_BUTTON2);
			break;
	}
}

- (void) gamepad:(CMGamepad *) gamepad
		xChanged:(NSInteger) newValue
		  center:(NSInteger) center
	   eventData:(CMGamepadEventData *) eventData
{
	NSUInteger gpIndex = [gamepad index];
	if (gpIndex > 1) {
		return;
	}
	
#ifdef DEBUG_JOY_STATE
    NSLog(@"Joystick X: %ld (center: %ld) on gamepad %@",
          newValue, center, gamepad);
#endif
    
    if (preferredDevices[gpIndex] == CMPreferredMacDeviceJoystick ||
        preferredDevices[gpIndex] == CMPreferredMacDeviceJoystickThenKeyboard) {
		CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
		if (!config) {
			config = [CMGamepadConfiguration defaultGamepadConfiguration];
		}
		
		NSInteger leftCode = [self virtualCodeMappedTo:CMMakeAnalog(CM_DIR_LEFT)
										 configuration:config
												  port:gpIndex];
		NSInteger rightCode = [self virtualCodeMappedTo:CMMakeAnalog(CM_DIR_RIGHT)
										  configuration:config
												   port:gpIndex];
		
		virtualCodeUnset(leftCode);
		virtualCodeUnset(rightCode);
		
		if (center - newValue > CMJoystickDeadzoneWidth) {
			// left
			virtualCodeSet(leftCode);
		} else if (newValue - center > CMJoystickDeadzoneWidth) {
			// right
			virtualCodeSet(rightCode);
		}
    }
}

- (void) gamepad:(CMGamepad *) gamepad
		yChanged:(NSInteger) newValue
		  center:(NSInteger) center
	   eventData:(CMGamepadEventData *) eventData
{
	NSUInteger gpIndex = [gamepad index];
	if (gpIndex > 1) {
		return;
	}
	
#ifdef DEBUG_JOY_STATE
    NSLog(@"Joystick Y: %ld (center: %ld) on gamepad %@",
          newValue, center, gamepad);
#endif
    
	if (preferredDevices[gpIndex] == CMPreferredMacDeviceJoystick ||
		preferredDevices[gpIndex] == CMPreferredMacDeviceJoystickThenKeyboard) {
		CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
		if (!config) {
			config = [CMGamepadConfiguration defaultGamepadConfiguration];
		}
		
		NSInteger upCode = [self virtualCodeMappedTo:CMMakeAnalog(CM_DIR_UP)
									   configuration:config
												port:gpIndex];
		NSInteger downCode = [self virtualCodeMappedTo:CMMakeAnalog(CM_DIR_DOWN)
										 configuration:config
												  port:gpIndex];
		
		virtualCodeUnset(upCode);
		virtualCodeUnset(downCode);
		
		if (center - newValue > CMJoystickDeadzoneWidth) {
			// up
			virtualCodeSet(upCode);
		} else if (newValue - center > CMJoystickDeadzoneWidth) {
			// down
			virtualCodeSet(downCode);
		}
    }
}

- (void) gamepad:(CMGamepad *) gamepad
	  buttonDown:(NSInteger) index
	   eventData:(CMGamepadEventData *) eventData
{
	NSUInteger gpIndex = [gamepad index];
	if (gpIndex > 1) {
		return;
	}
	
#ifdef DEBUG_JOY_STATE
    NSLog(@"Pressed button %ld on gamepad %@",
          index, gamepad);
#endif
    
	if (preferredDevices[gpIndex] == CMPreferredMacDeviceJoystick ||
		preferredDevices[gpIndex] == CMPreferredMacDeviceJoystickThenKeyboard) {
		CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
		if (!config) {
			config = [CMGamepadConfiguration defaultGamepadConfiguration];
		}
		
		NSInteger code = [self virtualCodeMappedTo:CMMakeButton(index)
									 configuration:config
											  port:gpIndex];
		
		if (code != 0) {
			virtualCodeSet(code);
		}
    }
}

- (void) gamepad:(CMGamepad *) gamepad
		buttonUp:(NSInteger) index
	   eventData:(CMGamepadEventData *) eventData
{
	NSUInteger gpIndex = [gamepad index];
	if (gpIndex > 1) {
		return;
	}
	
	CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
	if (!config) {
		config = [CMGamepadConfiguration defaultGamepadConfiguration];
	}
	
	NSInteger preferredDevice = -1;
	switch (gpIndex) {
		case 0:
			preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
			break;
		case 1:
			preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
			break;
	}
	
#ifdef DEBUG_JOY_STATE
    NSLog(@"Released button %ld on gamepad %@", index, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
		NSInteger code = [self virtualCodeMappedTo:CMMakeButton(index)
									 configuration:config
											  port:gpIndex];
		
		if (code != 0) {
			virtualCodeUnset(code);
		}
    }
}

#pragma mark - blueMSX Callbacks

extern CMEmulatorController *theEmulator;

void archPollInput()
{
    @autoreleasepool
    {
        [[theEmulator input] updateKeyboardState];
    }
}

UInt8 archJoystickGetState(int joystickNo)
{
    return 0; // Coleco-specific; unused
}

void archKeyboardSetSelectedKey(int keyCode)
{
}

@end
