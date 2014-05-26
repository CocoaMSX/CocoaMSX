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

NSString *const CMKeyPasteStarted = @"com.akop.CocoaMSX.KeyPasteStarted";
NSString *const CMKeyPasteEnded   = @"com.akop.CocoaMSX.KeyPasteEnded";

// These values should correspond to the matrix indices on Preferences.xib
#define CMPreferredMacDeviceJoystick             0
#define CMPreferredMacDeviceJoystickThenKeyboard 1
#define CMPreferredMacDeviceKeyboard             2

#define CMJoystickDeadzoneWidth 50

#define CMAutoPressHoldDuration    1121480
#define CMAutoPressReleaseDuration 1121480
#define CMAutoPressTotalTimeSeconds \
    (CMAutoPressHoldDuration + CMAutoPressReleaseDuration)

#define CMMakeMsxKeyInfo(d, s) \
    [CMMsxKeyInfo keyInfoWithDefaultStateLabel:d shiftedStateLabel:s]

#pragma mark - CMMsxKeyInfo

@interface CMMsxKeyInfo : NSObject
{
    NSString *_defaultStateLabel;
    NSString *_shiftedStateLabel;
}

@property (nonatomic, copy) NSString *defaultStateLabel;
@property (nonatomic, copy) NSString *shiftedStateLabel;

@end

@implementation CMMsxKeyInfo

@synthesize defaultStateLabel = _defaultStateLabel;
@synthesize shiftedStateLabel = _shiftedStateLabel;

+ (CMMsxKeyInfo *)keyInfoWithDefaultStateLabel:(NSString *)defaultStateLabel
                             shiftedStateLabel:(NSString *)shiftedStateLabel
{
    CMMsxKeyInfo *info = [[CMMsxKeyInfo alloc] init];
    
    [info setDefaultStateLabel:defaultStateLabel];
    [info setShiftedStateLabel:shiftedStateLabel];
    
    return [info autorelease];
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

- (void)dealloc
{
    [self setDefaultStateLabel:nil];
    [self setShiftedStateLabel:nil];
    
    [super dealloc];
}

@end

#pragma mark - CMCocoaInput

@interface CMCocoaInput ()

- (void)reloadConfigurations;
- (void)stopPasting;
- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;

@end

@implementation CMCocoaInput

@synthesize keyCombinationToAutoPress = _keyCombinationToAutoPress;
@synthesize joypadOneId = _joypadOneId;
@synthesize joypadTwoId = _joypadTwoId;

#define virtualCodeSet(eventCode) self->virtualCodeMap[eventCode] = 1
#define virtualCodeUnset(eventCode) self->virtualCodeMap[eventCode] = 0
#define virtualCodeClear() memset(self->virtualCodeMap, 0, sizeof(self->virtualCodeMap));

- (id)init
{
    if ((self = [super init]))
    {
        keysToPasteLock = [[NSObject alloc] init];
        
        keysToPaste = [[NSMutableArray alloc] init];
        joypadConfigurations = [[NSMutableDictionary alloc] init];
        
        _keyCombinationToAutoPress = nil;
        timeOfAutoPress = 0;
        
        _joypadOneId = 0;
        _joypadTwoId = 0;
        
        [[CMGamepadManager sharedInstance] addObserver:self];
        
        [self reloadConfigurations];
        [self resetState];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"joypadConfigurations"
                                                   options:0
                                                   context:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:@"joypadConfigurations"];
    
    [[CMGamepadManager sharedInstance] removeObserver:self];
    
    [joypadConfigurations release];
    [keysToPaste release];
    
    [keysToPasteLock release];
    
    [self setKeyCombinationToAutoPress:nil];
    
    [super dealloc];
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
    [self reloadConfigurations];
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

- (BOOL)pasteText:(NSString *)text
       layoutName:(NSString *)layoutName
{
    CMMSXKeyboard *keyboardLayout = [CMMSXKeyboard keyboardWithLayoutName:layoutName];
    if (!keyboardLayout)
        return NO; // Invalid key layout
    
#ifdef DEBUG
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
#endif
    
    NSMutableArray *textAsKeyCombinations = [NSMutableArray array];
    for (int i = 0, n = [text length]; i < n; i++)
    {
        NSString *character = [text substringWithRange:NSMakeRange(i, 1)];
        CMMSXKeyCombination *keyCombination = [keyboardLayout keyCombinationForCharacter:character];
        
        if (keyCombination)
            [textAsKeyCombinations addObject:keyCombination];
    }
    
    if ([textAsKeyCombinations count] > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CMKeyPasteStarted
                                                            object:self
                                                          userInfo:nil];
        
#ifdef DEBUG
    NSLog(@"Pasting %ld keys", [textAsKeyCombinations count]);
#endif
        
        @synchronized(keysToPasteLock)
        {
            [keysToPaste addObjectsFromArray:textAsKeyCombinations];
        }
        
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
    [self setKeyCombinationToAutoPress:nil];
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

- (void)stopPasting
{
    if ([keysToPaste count] > 0 || autoKeyPressPasted)
    {
        @synchronized(keysToPasteLock)
        {
            [keysToPaste removeAllObjects];
        }
        
        autoKeyPressPasted = NO;
        timeOfAutoPress = 0;
        
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
    
    if (virtualCode != CMUnknownVirtualCode)
    {
        if (isDown)
            virtualCodeSet(virtualCode);
        else
            virtualCodeUnset(virtualCode);
    }
}

- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown
{
    CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:keyCode];
    
    [self handleKeyEventForInput:input
                          layout:[theEmulator keyboardLayout]
                          isDown:isDown];
    
    NSInteger joyPort1PreferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    
    if (joyPort1PreferredDevice == CMPreferredMacDeviceKeyboard ||
        (joyPort1PreferredDevice == CMPreferredMacDeviceJoystickThenKeyboard && _joypadOneId == 0))
    {
        [self handleKeyEventForInput:input
                              layout:[theEmulator joystickOneLayout]
                              isDown:isDown];
    }
    
    NSInteger joyPort2PreferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    
    if (joyPort2PreferredDevice == CMPreferredMacDeviceKeyboard ||
        (joyPort2PreferredDevice == CMPreferredMacDeviceJoystickThenKeyboard && _joypadTwoId == 0))
    {
        [self handleKeyEventForInput:input
                              layout:[theEmulator joystickTwoLayout]
                              isDown:isDown];
    }
}

- (void)updateKeyboardState
{
    pollCounter++;
    
    // Reset the key matrix
    
    memcpy(eventMap, self->virtualCodeMap, sizeof(self->virtualCodeMap));
    
    NSTimeInterval timeNow = boardSystemTime(); //[NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval autoKeyPressInterval = timeNow - timeOfAutoPress;
    BOOL autoKeypressExpired = autoKeyPressInterval > CMAutoPressTotalTimeSeconds;
    
    // Check the paste queue, if there are no pending auto-keypresses
    if ([keysToPaste count] > 0 && autoKeypressExpired)
    {
        @synchronized(keysToPasteLock)
        {
            [self setKeyCombinationToAutoPress:[keysToPaste objectAtIndex:0]];
            [keysToPaste removeObjectAtIndex:0];
        }
        
        autoKeyPressPasted = YES;
        timeOfAutoPress = timeNow;
        
        autoKeypressExpired = NO;
    }
    
    // Check for programmatically depressed keys
    if ([self keyCombinationToAutoPress])
    {
        // A key is programmatically depressed
        if (autoKeypressExpired)
        {
            // Keypress has expired - release it
            [self setKeyCombinationToAutoPress:nil];
            
            if (autoKeyPressPasted && [keysToPaste count] < 1)
            {
                // Post 'pasting ended' notification
                [[NSNotificationCenter defaultCenter] postNotificationName:CMKeyPasteEnded
                                                                    object:self
                                                                  userInfo:nil];
            }
            
            timeOfAutoPress = 0;
            autoKeyPressPasted = NO;
        }
        else if (autoKeyPressInterval < CMAutoPressHoldDuration)
        {
            if ([[self keyCombinationToAutoPress] stateFlags] & CMMSXKeyStateShift)
                virtualCodeSet(EC_LSHIFT);
            
            virtualCodeSet([[self keyCombinationToAutoPress] virtualCode]);
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

- (void)gamepadDidConnect:(CMGamepad *)gamepad
{
    if (_joypadOneId == 0)
    {
#if DEBUG
        NSLog(@"Gamepad \"%@\" connected to port 1", [gamepad name]);
#endif
        _joypadOneId = [gamepad gamepadId];
        
        virtualCodeUnset(EC_JOY1_UP);
        virtualCodeUnset(EC_JOY1_DOWN);
        virtualCodeUnset(EC_JOY1_LEFT);
        virtualCodeUnset(EC_JOY1_RIGHT);
        virtualCodeUnset(EC_JOY1_BUTTON1);
        virtualCodeUnset(EC_JOY1_BUTTON2);
    }
    else if (_joypadTwoId == 0)
    {
#if DEBUG
        NSLog(@"Gamepad \"%@\" connected to port 2", [gamepad name]);
#endif
        _joypadTwoId = [gamepad gamepadId];
        
        virtualCodeUnset(EC_JOY2_UP);
        virtualCodeUnset(EC_JOY2_DOWN);
        virtualCodeUnset(EC_JOY2_LEFT);
        virtualCodeUnset(EC_JOY2_RIGHT);
        virtualCodeUnset(EC_JOY2_BUTTON1);
        virtualCodeUnset(EC_JOY2_BUTTON2);
    }
}

- (void)gamepadDidDisconnect:(CMGamepad *)gamepad
{
#if DEBUG
    NSLog(@"Gamepad \"%@\" disconnected", [gamepad name]);
#endif
    
    if (_joypadOneId == [gamepad gamepadId])
    {
        _joypadOneId = 0;
        
        virtualCodeUnset(EC_JOY1_UP);
        virtualCodeUnset(EC_JOY1_DOWN);
        virtualCodeUnset(EC_JOY1_LEFT);
        virtualCodeUnset(EC_JOY1_RIGHT);
        virtualCodeUnset(EC_JOY1_BUTTON1);
        virtualCodeUnset(EC_JOY1_BUTTON2);
    }
    else if (_joypadTwoId == [gamepad gamepadId])
    {
        _joypadTwoId = 0;
        
        virtualCodeUnset(EC_JOY2_UP);
        virtualCodeUnset(EC_JOY2_DOWN);
        virtualCodeUnset(EC_JOY2_LEFT);
        virtualCodeUnset(EC_JOY2_RIGHT);
        virtualCodeUnset(EC_JOY2_BUTTON1);
        virtualCodeUnset(EC_JOY2_BUTTON2);
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       xChanged:(NSInteger)newValue
         center:(NSInteger)center
      eventData:(CMGamepadEventData *)eventData
{
    NSInteger preferredDevice = -1;
    NSInteger leftVirtualCode;
    NSInteger rightVirtualCode;
    
    CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
    if (config)
        center = [config centerX];
    
    if (_joypadOneId == [gamepad gamepadId])
    {
        leftVirtualCode = EC_JOY1_LEFT;
        rightVirtualCode = EC_JOY1_RIGHT;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (_joypadTwoId == [gamepad gamepadId])
    {
        leftVirtualCode = EC_JOY2_LEFT;
        rightVirtualCode = EC_JOY2_RIGHT;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"Joystick X: %ld (center: %ld) on gamepad %@",
          newValue, center, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        virtualCodeUnset(leftVirtualCode);
        virtualCodeUnset(rightVirtualCode);
        
        if (center - newValue > CMJoystickDeadzoneWidth)
            virtualCodeSet(leftVirtualCode);
        else if (newValue - center > CMJoystickDeadzoneWidth)
            virtualCodeSet(rightVirtualCode);
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
      eventData:(CMGamepadEventData *)eventData
{
    NSInteger preferredDevice = -1;
    NSInteger upVirtualCode;
    NSInteger downVirtualCode;
    
    CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
    if (config)
        center = [config centerY];
    
    if (_joypadOneId == [gamepad gamepadId])
    {
        upVirtualCode = EC_JOY1_UP;
        downVirtualCode = EC_JOY1_DOWN;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (_joypadTwoId == [gamepad gamepadId])
    {
        upVirtualCode = EC_JOY2_UP;
        downVirtualCode = EC_JOY2_DOWN;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"Joystick Y: %ld (center: %ld) on gamepad %@",
          newValue, center, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        virtualCodeUnset(upVirtualCode);
        virtualCodeUnset(downVirtualCode);
        
        if (center - newValue > CMJoystickDeadzoneWidth)
            virtualCodeSet(upVirtualCode);
        else if (newValue - center > CMJoystickDeadzoneWidth)
            virtualCodeSet(downVirtualCode);
    }
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
      eventData:(CMGamepadEventData *)eventData
{
    NSInteger preferredDevice = -1;
    NSInteger button1VirtualCode;
    NSInteger button2VirtualCode;
    
    CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
    
    if (_joypadOneId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY1_BUTTON1;
        button2VirtualCode = EC_JOY1_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (_joypadTwoId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY2_BUTTON1;
        button2VirtualCode = EC_JOY2_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"Pressed button %ld on gamepad %@", index, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        NSInteger button1Index = (config) ? [config buttonAIndex] : 1;
        NSInteger button2Index = (config) ? [config buttonBIndex] : 2;
        
        if (index == button1Index)
            virtualCodeSet(button1VirtualCode);
        else if (index == button2Index)
            virtualCodeSet(button2VirtualCode);
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
      eventData:(CMGamepadEventData *)eventData
{
    NSInteger preferredDevice = -1;
    NSInteger button1VirtualCode;
    NSInteger button2VirtualCode;
    CMGamepadConfiguration *config = [joypadConfigurations objectForKey:@([gamepad vendorProductId])];
    
    if (_joypadOneId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY1_BUTTON1;
        button2VirtualCode = EC_JOY1_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (_joypadTwoId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY2_BUTTON1;
        button2VirtualCode = EC_JOY2_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"Released button %ld on gamepad %@", index, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        NSInteger button1Index = (config) ? [config buttonAIndex] : 1;
        NSInteger button2Index = (config) ? [config buttonBIndex] : 2;
        
        if (index == button1Index)
            virtualCodeUnset(button1VirtualCode);
        else if (index == button2Index)
            virtualCodeUnset(button2VirtualCode);
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
