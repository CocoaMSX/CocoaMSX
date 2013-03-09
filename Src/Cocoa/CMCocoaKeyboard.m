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

#import "CMCocoaKeyboard.h"

#import "CMKeyboardInput.h"
#import "CMInputDeviceLayout.h"
#import "CMPreferences.h"

#import "CMEmulatorController.h"

#include "InputEvent.h"

#define CMAutoPressHoldDuration    0.05
#define CMAutoPressReleaseDuration 0.05
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
    
    info.defaultStateLabel = defaultStateLabel;
    info.shiftedStateLabel = shiftedStateLabel;
    
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
    self.defaultStateLabel = nil;
    self.shiftedStateLabel = nil;
    
    [super dealloc];
}

@end

//#define DEBUG_KEY_STATE

#pragma mark - CMCocoaKeyboard

static NSArray *orderOfAppearance = nil;

@interface CMCocoaKeyboard ()

- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;

@end

@implementation CMCocoaKeyboard

@synthesize keyCombinationToAutoPress = _keyCombinationToAutoPress;

+ (void)initialize
{
    orderOfAppearance = [[NSArray alloc] initWithObjects:
                         @EC_RBRACK,
                         @EC_1,
                         @EC_2,
                         @EC_3,
                         @EC_4,
                         @EC_5,
                         @EC_6,
                         @EC_7,
                         @EC_8,
                         @EC_9,
                         @EC_0,
                         @EC_NEG,
                         @EC_CIRCFLX,
                         @EC_Q,
                         @EC_W,
                         @EC_E,
                         @EC_R,
                         @EC_T,
                         @EC_Y,
                         @EC_U,
                         @EC_I,
                         @EC_O,
                         @EC_P,
                         @EC_A,
                         @EC_LBRACK,
                         @EC_A,
                         @EC_S,
                         @EC_D,
                         @EC_F,
                         @EC_G,
                         @EC_H,
                         @EC_J,
                         @EC_K,
                         @EC_L,
                         @EC_SEMICOL,
                         @EC_COLON,
                         @EC_BKSLASH,
                         @EC_Z,
                         @EC_X,
                         @EC_C,
                         @EC_V,
                         @EC_B,
                         @EC_N,
                         @EC_M,
                         @EC_COMMA,
                         @EC_PERIOD,
                         @EC_DIV,
                         @EC_UNDSCRE,
                         @EC_LSHIFT,
                         @EC_RSHIFT,
                         @EC_CTRL,
                         @EC_GRAPH,
                         @EC_CODE,
                         @EC_CAPS,
                         @EC_LEFT,
                         @EC_UP,
                         @EC_RIGHT,
                         @EC_DOWN,
                         @EC_F1,
                         @EC_F2,
                         @EC_F3,
                         @EC_F4,
                         @EC_F5,
                         @EC_NUM0,
                         @EC_NUM1,
                         @EC_NUM2,
                         @EC_NUM3,
                         @EC_NUM4,
                         @EC_NUM5,
                         @EC_NUM6,
                         @EC_NUM7,
                         @EC_NUM8,
                         @EC_NUM9,
                         @EC_NUMDIV,
                         @EC_NUMMUL,
                         @EC_NUMSUB,
                         @EC_NUMADD,
                         @EC_NUMPER,
                         @EC_NUMCOM,
                         @EC_ESC,
                         @EC_TAB,
                         @EC_STOP,
                         @EC_CLS,
                         @EC_SELECT,
                         @EC_INS,
                         @EC_DEL,
                         @EC_BKSPACE,
                         @EC_RETURN,
                         @EC_SPACE,
                         @EC_PRINT,
                         @EC_PAUSE,
                         @EC_TORIKE,
                         @EC_JIKKOU,
                         @EC_JOY1_UP,
                         @EC_JOY1_DOWN,
                         @EC_JOY1_LEFT,
                         @EC_JOY1_RIGHT,
                         @EC_JOY2_UP,
                         @EC_JOY2_DOWN,
                         @EC_JOY2_LEFT,
                         @EC_JOY2_RIGHT,
                         @EC_JOY1_BUTTON1,
                         @EC_JOY1_BUTTON2,
                         @EC_JOY2_BUTTON1,
                         @EC_JOY2_BUTTON2,
                         
                         nil];
}

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
        
        [self resetState];
    }
    
    return self;
}

- (void)dealloc
{
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
      keyLayoutId:(CMMSXKeyboardLayout)keyLayoutId
{
    CMMSXKeyboard *keyboardLayout = [CMMSXKeyboard keyboardWithLayout:keyLayoutId];
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

- (BOOL)isAnyKeyDown
{
    @synchronized(keyLock)
    {
        return [keysDown count] > 0;
    }
}

- (void)resetState
{
    [self releaseAllKeys];
    
    // Clear the paste queue
    @synchronized (keysToPasteLock)
    {
        [keysToPaste removeAllObjects];
    }
    
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

+ (NSInteger)compareKeysByOrderOfAppearance:(NSNumber *)one
                                 keyCodeTwo:(NSNumber *)two
{
    NSInteger index1 = [orderOfAppearance indexOfObject:one];
    NSInteger index2 = [orderOfAppearance indexOfObject:two];
    
    if (index1 < index2)
        return NSOrderedAscending;
    else if (index1 > index2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (NSInteger)categoryForVirtualCode:(NSUInteger)virtualCode
{
    switch (virtualCode)
    {
        case EC_RBRACK:
        case EC_1:
        case EC_2:
        case EC_3:
        case EC_4:
        case EC_5:
        case EC_6:
        case EC_7:
        case EC_8:
        case EC_9:
        case EC_0:
        case EC_NEG:
        case EC_CIRCFLX:
            return CMKeyCategoryTypewriterRowOne;
        case EC_Q:
        case EC_W:
        case EC_E:
        case EC_R:
        case EC_T:
        case EC_Y:
        case EC_U:
        case EC_I:
        case EC_O:
        case EC_P:
        case EC_AT:
        case EC_LBRACK:
            return CMKeyCategoryTypewriterRowTwo;
        case EC_A:
        case EC_S:
        case EC_D:
        case EC_F:
        case EC_G:
        case EC_H:
        case EC_J:
        case EC_K:
        case EC_L:
        case EC_SEMICOL:
        case EC_COLON:
        case EC_BKSLASH:
            return CMKeyCategoryTypewriterRowThree;
        case EC_Z:
        case EC_X:
        case EC_C:
        case EC_V:
        case EC_B:
        case EC_N:
        case EC_M:
        case EC_COMMA:
        case EC_PERIOD:
        case EC_DIV:
        case EC_UNDSCRE:
            return CMKeyCategoryTypewriterRowFour;
        case EC_LSHIFT:
        case EC_RSHIFT:
        case EC_CTRL:
        case EC_GRAPH:
        case EC_CODE:
        case EC_CAPS:
            return CMKeyCategoryModifier;
        case EC_LEFT:
        case EC_UP:
        case EC_RIGHT:
        case EC_DOWN:
            return CMKeyCategoryDirectional;
        case EC_F1:
        case EC_F2:
        case EC_F3:
        case EC_F4:
        case EC_F5:
            return CMKeyCategoryFunction;
        case EC_NUMMUL:
        case EC_NUMADD:
        case EC_NUMDIV:
        case EC_NUMSUB:
        case EC_NUMPER:
        case EC_NUMCOM:
        case EC_NUM0:
        case EC_NUM1:
        case EC_NUM2:
        case EC_NUM3:
        case EC_NUM4:
        case EC_NUM5:
        case EC_NUM6:
        case EC_NUM7:
        case EC_NUM8:
        case EC_NUM9:
            return CMKeyCategoryNumericPad;
        case EC_ESC:
        case EC_TAB:
        case EC_STOP:
        case EC_CLS:
        case EC_SELECT:
        case EC_INS:
        case EC_DEL:
        case EC_BKSPACE:
        case EC_RETURN:
        case EC_SPACE:
        case EC_PRINT:
        case EC_PAUSE:
        case EC_TORIKE:
        case EC_JIKKOU:
            return CMKeyCategorySpecial;
        case EC_JOY1_UP:
        case EC_JOY1_DOWN:
        case EC_JOY1_LEFT:
        case EC_JOY1_RIGHT:
        case EC_JOY2_UP:
        case EC_JOY2_DOWN:
        case EC_JOY2_LEFT:
        case EC_JOY2_RIGHT:
            return CMKeyCategoryJoyDirections;
        case EC_JOY1_BUTTON1:
        case EC_JOY1_BUTTON2:
        case EC_JOY2_BUTTON1:
        case EC_JOY2_BUTTON2:
            return CMKeyCategoryJoyButtons;
        default:
            return 0;
    }
}

- (NSString *)nameForCategory:(NSInteger)category
{
    switch (category)
    {
        case CMKeyCategoryModifier:
            return CMLoc(@"KeyCategoryModifier");
        case CMKeyCategoryDirectional:
            return CMLoc(@"KeyCategoryDirectional");
        case CMKeyCategoryFunction:
            return CMLoc(@"KeyCategoryFunction");
        case CMKeyCategoryTypewriterRowOne:
            return CMLoc(@"KeyCategoryTypewriterRowOne");
        case CMKeyCategoryTypewriterRowTwo:
            return CMLoc(@"KeyCategoryTypewriterRowTwo");
        case CMKeyCategoryTypewriterRowThree:
            return CMLoc(@"KeyCategoryTypewriterRowThree");
        case CMKeyCategoryTypewriterRowFour:
            return CMLoc(@"KeyCategoryTypewriterRowFour");
        case CMKeyCategoryNumericPad:
            return CMLoc(@"KeyCategoryNumericPad");
        case CMKeyCategorySpecial:
            return CMLoc(@"KeyCategorySpecial");
        case CMKeyCategoryJoyButtons:
            return CMLoc(@"KeyCategoryJoystickButtons");
        case CMKeyCategoryJoyDirections:
            return CMLoc(@"KeyCategoryJoystickDirectional");
    }
    
    return nil;
}

#pragma mark - Private methods

- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown
{
    CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:keyCode];
    
    [[theEmulator inputDeviceLayouts] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMInputDeviceLayout *layout = obj;
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
    }];
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
    
    NSTimeInterval timeNow = [NSDate timeIntervalSinceReferenceDate];
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
            timeOfAutoPress = 0;
        }
        else if (autoKeyPressInterval < CMAutoPressHoldDuration)
        {
            if ([[self keyCombinationToAutoPress] stateFlags] & CMMSXKeyStateShift)
                inputEventSet(EC_LSHIFT);
            
            inputEventSet([[self keyCombinationToAutoPress] virtualCode]);
        }
    }
}

#pragma mark - BlueMSX Callbacks

extern CMEmulatorController *theEmulator;

void archPollInput()
{
    @autoreleasepool
    {
        [[theEmulator keyboard] updateKeyboardState];
    }
}

void archKeyboardSetSelectedKey(int keyCode) {}

@end
