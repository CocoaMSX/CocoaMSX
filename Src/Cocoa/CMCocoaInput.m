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
#import <AppKit/NSEvent.h>

#import "CMCocoaInput.h"

#import "CMKeyboardInput.h"
#import "CMInputDeviceLayout.h"
#import "CMPreferences.h"

#import "CMEmulatorController.h"

#include "Board.h"
#include "InputEvent.h"

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

//#define DEBUG_KEY_STATE

#pragma mark - CMCocoaInput

@interface CMCocoaInput ()

- (void)stopPasting;
- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;

@end

@implementation CMCocoaInput

@synthesize keyCombinationToAutoPress = _keyCombinationToAutoPress;

- (id)init
{
    if ((self = [super init]))
    {
        keyLock = [[NSObject alloc] init];
        keysToPasteLock = [[NSObject alloc] init];
        
        keysDown = [[NSMutableSet alloc] init];
        keysToPaste = [[NSMutableArray alloc] init];
        
        _keyCombinationToAutoPress = nil;
        timeOfAutoPress = 0;
        
        joypadOneId = 0;
        joypadTwoId = 0;
        
        [[CMGamepadManager sharedInstance] addObserver:self];
        
        [self resetState];
    }
    
    return self;
}

- (void)dealloc
{
    [[CMGamepadManager sharedInstance] removeObserver:self];
    
    [keysDown release];
    [keysToPaste release];
    
    [keyLock release];
    [keysToPasteLock release];
    
    [self setKeyCombinationToAutoPress:nil];
    
    [super dealloc];
}

#pragma mark - Key event methods

- (void)keyDown:(NSEvent*)event
{
    if ([event isARepeat])
        return;
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"keyDown: %i", [event keyCode]);
#endif
    
    // Ignore keys while Command is pressed - they don't generate keyUp
    if (([event modifierFlags] & NSCommandKeyMask) != 0)
        return;
    
    if ([event keyCode] == 53) // Escape
        [self stopPasting];
    
    [self handleKeyEvent:[event keyCode] isDown:YES];
}

- (void)keyUp:(NSEvent*)event
{
    if ([event isARepeat])
        return;
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"keyUp: %i", [event keyCode]);
#endif
    
    [self handleKeyEvent:[event keyCode] isDown:NO];
}

- (void)flagsChanged:(NSEvent *)event
{
#ifdef DEBUG_KEY_STATE
    NSLog(@"flagsChanged: %1$x; flags: %2$ld (0x%2$lx)",
          event.keyCode, event.modifierFlags);
#endif
    
    if ([event keyCode] == CMKeyLeftShift)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftShiftKeyMask) == CMLeftShiftKeyMask)];
    else if ([event keyCode] == CMKeyRightShift)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightShiftKeyMask) == CMRightShiftKeyMask)];
    else if ([event keyCode] == CMKeyLeftAlt)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftAltKeyMask) == CMLeftAltKeyMask)];
    else if ([event keyCode] == CMKeyRightAlt)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightAltKeyMask) == CMRightAltKeyMask)];
    else if ([event keyCode] == CMKeyLeftControl)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftControlKeyMask) == CMLeftControlKeyMask)];
    else if ([event keyCode] == CMKeyRightControl)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightControlKeyMask) == CMRightControlKeyMask)];
    else if ([event keyCode] == CMKeyLeftCommand)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftCommandKeyMask) == CMLeftCommandKeyMask)];
    else if ([event keyCode] == CMKeyRightCommand)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightCommandKeyMask) == CMRightCommandKeyMask)];
    else if ([event keyCode] == CMKeyCapsLock)
    {
        // Mac Caps Lock has no up/down. When it's pressed, auto-press the key
        // (it will be released automatically)
        
        CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:[event keyCode]];
        NSInteger virtualCode = [[theEmulator keyboardLayout] virtualCodeForInputMethod:input];
        
        if (virtualCode != CMUnknownVirtualCode)
        {
            CMMSXKeyCombination *keyCombination = [CMMSXKeyCombination combinationWithVirtualCode:virtualCode
                                                                                 stateFlags:CMMSXKeyStateDefault];
            
            [self setKeyCombinationToAutoPress:keyCombination];
            timeOfAutoPress = [NSDate timeIntervalSinceReferenceDate];
        }
    }
    
    if ([event keyCode] == CMKeyLeftCommand || [event keyCode] == CMKeyRightCommand)
    {
        // If Command is toggled while another key is down, releasing the
        // other key no longer generates a keyUp event, and the virtual key
        // 'sticks'. Release all virtual keys if Command is pressed.
        
        [self releaseAllKeys];
    }
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
    // Release the keys currently held
    @synchronized (keyLock)
    {
        [keysDown removeAllObjects];
    }
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
    }
    else
    {
#ifdef DEBUG
        NSLog(@"CocoaKeyboard: +Focus");
#endif
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
        @synchronized (keyLock)
        {
            if (isDown)
                [keysDown addObject:@(virtualCode)];
            else
                [keysDown removeObject:@(virtualCode)];
        }
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
        (joyPort1PreferredDevice == CMPreferredMacDeviceJoystickThenKeyboard && joypadOneId == 0))
    {
        [self handleKeyEventForInput:input
                              layout:[theEmulator joystickOneLayout]
                              isDown:isDown];
    }
    
    NSInteger joyPort2PreferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    
    if (joyPort2PreferredDevice == CMPreferredMacDeviceKeyboard ||
        (joyPort2PreferredDevice == CMPreferredMacDeviceJoystickThenKeyboard && joypadTwoId == 0))
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
    inputEventReset();
    
    // Create a copy for the keys currently down (so that we can enumerate them)
    NSArray *keysDownNow;
    @synchronized(keyLock)
    {
        keysDownNow = [keysDown allObjects];
    }
    
    // Update the matrix for the keys currently down
    [keysDownNow enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        inputEventSet([obj integerValue]);
    }];
    
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
                inputEventSet(EC_LSHIFT);
            
            inputEventSet([[self keyCombinationToAutoPress] virtualCode]);
        }
    }
}

#pragma mark - CMGamepadDelegate

- (void)gamepadDidConnect:(CMGamepad *)gamepad
{
    if (joypadOneId == 0)
    {
#if DEBUG
        NSLog(@"Gamepad \"%@\" connected to port 1", [gamepad name]);
#endif
        joypadOneId = [gamepad gamepadId];
        
        [keysDown removeObject:@(EC_JOY1_UP)];
        [keysDown removeObject:@(EC_JOY1_DOWN)];
        [keysDown removeObject:@(EC_JOY1_LEFT)];
        [keysDown removeObject:@(EC_JOY1_RIGHT)];
        [keysDown removeObject:@(EC_JOY1_BUTTON1)];
        [keysDown removeObject:@(EC_JOY1_BUTTON2)];
    }
    else if (joypadTwoId == 0)
    {
#if DEBUG
        NSLog(@"Gamepad \"%@\" connected to port 2", [gamepad name]);
#endif
        joypadTwoId = [gamepad gamepadId];
        
        [keysDown removeObject:@(EC_JOY2_UP)];
        [keysDown removeObject:@(EC_JOY2_DOWN)];
        [keysDown removeObject:@(EC_JOY2_LEFT)];
        [keysDown removeObject:@(EC_JOY2_RIGHT)];
        [keysDown removeObject:@(EC_JOY2_BUTTON1)];
        [keysDown removeObject:@(EC_JOY2_BUTTON2)];
    }
}

- (void)gamepadDidDisconnect:(CMGamepad *)gamepad
{
#if DEBUG
    NSLog(@"Gamepad \"%@\" disconnected", [gamepad name]);
#endif
    
    if (joypadOneId == [gamepad gamepadId])
    {
        joypadOneId = 0;
        
        [keysDown removeObject:@(EC_JOY1_UP)];
        [keysDown removeObject:@(EC_JOY1_DOWN)];
        [keysDown removeObject:@(EC_JOY1_LEFT)];
        [keysDown removeObject:@(EC_JOY1_RIGHT)];
        [keysDown removeObject:@(EC_JOY1_BUTTON1)];
        [keysDown removeObject:@(EC_JOY1_BUTTON2)];
    }
    else if (joypadTwoId == [gamepad gamepadId])
    {
        joypadTwoId = 0;
        
        [keysDown removeObject:@(EC_JOY2_UP)];
        [keysDown removeObject:@(EC_JOY2_DOWN)];
        [keysDown removeObject:@(EC_JOY2_LEFT)];
        [keysDown removeObject:@(EC_JOY2_RIGHT)];
        [keysDown removeObject:@(EC_JOY2_BUTTON1)];
        [keysDown removeObject:@(EC_JOY2_BUTTON2)];
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       xChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event
{
    NSInteger preferredDevice = -1;
    NSInteger leftVirtualCode;
    NSInteger rightVirtualCode;
    
    if (joypadOneId == [gamepad gamepadId])
    {
        leftVirtualCode = EC_JOY1_LEFT;
        rightVirtualCode = EC_JOY1_RIGHT;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (joypadTwoId == [gamepad gamepadId])
    {
        leftVirtualCode = EC_JOY2_LEFT;
        rightVirtualCode = EC_JOY2_RIGHT;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#if DEBUG
    NSLog(@"Joystick X: %ld (center: %ld) on gamepad %@",
          newValue, center, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        [keysDown removeObject:@(leftVirtualCode)];
        [keysDown removeObject:@(rightVirtualCode)];
        
        if (center - newValue > CMJoystickDeadzoneWidth)
            [keysDown addObject:@(leftVirtualCode)];
        else if (newValue - center > CMJoystickDeadzoneWidth)
            [keysDown addObject:@(rightVirtualCode)];
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       yChanged:(NSInteger)newValue
         center:(NSInteger)center
          event:(CMGamepadEvent *)event
{
    NSInteger preferredDevice = -1;
    NSInteger upVirtualCode;
    NSInteger downVirtualCode;
    
    if (joypadOneId == [gamepad gamepadId])
    {
        upVirtualCode = EC_JOY1_UP;
        downVirtualCode = EC_JOY1_DOWN;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (joypadTwoId == [gamepad gamepadId])
    {
        upVirtualCode = EC_JOY2_UP;
        downVirtualCode = EC_JOY2_DOWN;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#if DEBUG
    NSLog(@"Joystick Y: %ld (center: %ld) on gamepad %@",
          newValue, center, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        [keysDown removeObject:@(upVirtualCode)];
        [keysDown removeObject:@(downVirtualCode)];
        
        if (center - newValue > CMJoystickDeadzoneWidth)
            [keysDown addObject:@(upVirtualCode)];
        else if (newValue - center > CMJoystickDeadzoneWidth)
            [keysDown addObject:@(downVirtualCode)];
    }
}

- (void)gamepad:(CMGamepad *)gamepad
     buttonDown:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    NSInteger preferredDevice = -1;
    NSInteger button1VirtualCode;
    NSInteger button2VirtualCode;
    
    if (joypadOneId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY1_BUTTON1;
        button2VirtualCode = EC_JOY1_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (joypadTwoId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY2_BUTTON1;
        button2VirtualCode = EC_JOY2_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#if DEBUG
    NSLog(@"Pressed button %ld on gamepad %@", index, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        if (index == 1)
            [keysDown addObject:@(button1VirtualCode)];
        else if (index == 2)
            [keysDown addObject:@(button2VirtualCode)];
    }
}

- (void)gamepad:(CMGamepad *)gamepad
       buttonUp:(NSInteger)index
          event:(CMGamepadEvent *)event
{
    NSInteger preferredDevice = -1;
    NSInteger button1VirtualCode;
    NSInteger button2VirtualCode;
    
    if (joypadOneId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY1_BUTTON1;
        button2VirtualCode = EC_JOY1_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort1"];
    }
    else if (joypadTwoId == [gamepad gamepadId])
    {
        button1VirtualCode = EC_JOY2_BUTTON1;
        button2VirtualCode = EC_JOY2_BUTTON2;
        
        preferredDevice = [[NSUserDefaults standardUserDefaults] integerForKey:@"joystickPreferredMacDevicePort2"];
    }
    
#if DEBUG
    NSLog(@"Released button %ld on gamepad %@", index, gamepad);
#endif
    
    if (preferredDevice == CMPreferredMacDeviceJoystick ||
        preferredDevice == CMPreferredMacDeviceJoystickThenKeyboard)
    {
        if (index == 1)
            [keysDown removeObject:@(button1VirtualCode)];
        else if (index == 2)
            [keysDown removeObject:@(button2VirtualCode)];
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
