/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012 Akop Karapetyan
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

// FIXME: this class needs to poll, and not just modify the virtual matrix
//        whenever a key is pressed

//#define DEBUG_KEY_STATE
#define CMIntAsNumber(x) [NSNumber numberWithInteger:x]

static NSDictionary *virtualCodeNames = nil;

#pragma mark - CocoaKeyboard

@interface CMCocoaKeyboard ()

- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;

@end

@implementation CMCocoaKeyboard

+ (void)initialize
{
    virtualCodeNames = [[NSDictionary alloc] initWithObjectsAndKeys:
                         
                         // Modifiers
                         CMLoc(@"KeyLeftShift"),  CMIntAsNumber(EC_LSHIFT),
                         CMLoc(@"KeyRightShift"), CMIntAsNumber(EC_RSHIFT),
                         CMLoc(@"KeyCtrl"),       CMIntAsNumber(EC_CTRL),
                         CMLoc(@"KeyGraph"),      CMIntAsNumber(EC_GRAPH),
                         CMLoc(@"KeyCode"),       CMIntAsNumber(EC_CODE),
                         CMLoc(@"KeyTorike"),     CMIntAsNumber(EC_TORIKE),
                         CMLoc(@"KeyJikkou"),     CMIntAsNumber(EC_JIKKOU),
                         CMLoc(@"KeyCapsLock"),   CMIntAsNumber(EC_CAPS),
                         
                         // Directional
                         CMLoc(@"KeyCursorLeft"),  CMIntAsNumber(EC_LEFT),
                         CMLoc(@"KeyCursorUp"),    CMIntAsNumber(EC_UP),
                         CMLoc(@"KeyCursorRight"), CMIntAsNumber(EC_RIGHT),
                         CMLoc(@"KeyCursorDown"),  CMIntAsNumber(EC_DOWN),
                         
                         // Function
                         @"F1", CMIntAsNumber(EC_F1),
                         @"F2", CMIntAsNumber(EC_F2),
                         @"F3", CMIntAsNumber(EC_F3),
                         @"F4", CMIntAsNumber(EC_F4),
                         @"F5", CMIntAsNumber(EC_F5),
                         
                         // Alpha
                         @"A", CMIntAsNumber(EC_A),
                         @"B", CMIntAsNumber(EC_B),
                         @"C", CMIntAsNumber(EC_C),
                         @"D", CMIntAsNumber(EC_D),
                         @"E", CMIntAsNumber(EC_E),
                         @"F", CMIntAsNumber(EC_F),
                         @"G", CMIntAsNumber(EC_G),
                         @"H", CMIntAsNumber(EC_H),
                         @"I", CMIntAsNumber(EC_I),
                         @"J", CMIntAsNumber(EC_J),
                         @"K", CMIntAsNumber(EC_K),
                         @"L", CMIntAsNumber(EC_L),
                         @"M", CMIntAsNumber(EC_M),
                         @"N", CMIntAsNumber(EC_N),
                         @"O", CMIntAsNumber(EC_O),
                         @"P", CMIntAsNumber(EC_P),
                         @"Q", CMIntAsNumber(EC_Q),
                         @"R", CMIntAsNumber(EC_R),
                         @"S", CMIntAsNumber(EC_S),
                         @"T", CMIntAsNumber(EC_T),
                         @"U", CMIntAsNumber(EC_U),
                         @"V", CMIntAsNumber(EC_V),
                         @"W", CMIntAsNumber(EC_W),
                         @"X", CMIntAsNumber(EC_X),
                         @"Y", CMIntAsNumber(EC_Y),
                         @"Z", CMIntAsNumber(EC_Z),
                         @"0", CMIntAsNumber(EC_0),
                         @"1", CMIntAsNumber(EC_1),
                         @"2", CMIntAsNumber(EC_2),
                         @"3", CMIntAsNumber(EC_3),
                         @"4", CMIntAsNumber(EC_4),
                         @"5", CMIntAsNumber(EC_5),
                         @"6", CMIntAsNumber(EC_6),
                         @"7", CMIntAsNumber(EC_7),
                         @"8", CMIntAsNumber(EC_8),
                         @"-", CMIntAsNumber(EC_NEG),
                         @"\\", CMIntAsNumber(EC_BKSLASH),
                         @"@", CMIntAsNumber(EC_AT),
                         @"[", CMIntAsNumber(EC_LBRACK),
                         @"]", CMIntAsNumber(EC_RBRACK),
                         @"^", CMIntAsNumber(EC_CIRCFLX),
                         @";", CMIntAsNumber(EC_SEMICOL),
                         @":", CMIntAsNumber(EC_COLON),
                         @",", CMIntAsNumber(EC_COMMA),
                         @".", CMIntAsNumber(EC_PERIOD),
                         @"/", CMIntAsNumber(EC_DIV),
                         @"_", CMIntAsNumber(EC_UNDSCRE),
                         
                         @"9", CMIntAsNumber(EC_9),
                         
                         // Numpad
                         @"*", CMIntAsNumber(EC_NUMMUL),
                         @"+", CMIntAsNumber(EC_NUMADD),
                         @"/", CMIntAsNumber(EC_NUMDIV),
                         @"-", CMIntAsNumber(EC_NUMSUB),
                         @".", CMIntAsNumber(EC_NUMPER),
                         @",", CMIntAsNumber(EC_NUMCOM),
                         @"0", CMIntAsNumber(EC_NUM0),
                         @"1", CMIntAsNumber(EC_NUM1),
                         @"2", CMIntAsNumber(EC_NUM2),
                         @"3", CMIntAsNumber(EC_NUM3),
                         @"4", CMIntAsNumber(EC_NUM4),
                         @"5", CMIntAsNumber(EC_NUM5),
                         @"6", CMIntAsNumber(EC_NUM6),
                         @"7", CMIntAsNumber(EC_NUM7),
                         @"8", CMIntAsNumber(EC_NUM8),
                         @"9", CMIntAsNumber(EC_NUM9),
                        
                         // Special
                         CMLoc(@"KeyEscape"),    CMIntAsNumber(EC_ESC),
                         CMLoc(@"KeyTab"),       CMIntAsNumber(EC_TAB),
                         CMLoc(@"KeyStop"),      CMIntAsNumber(EC_STOP),
                         CMLoc(@"KeyCls"),       CMIntAsNumber(EC_CLS),
                         CMLoc(@"KeySelect"),    CMIntAsNumber(EC_SELECT),
                         CMLoc(@"KeyInsert"),    CMIntAsNumber(EC_INS),
                         CMLoc(@"KeyDelete"),    CMIntAsNumber(EC_DEL),
                         CMLoc(@"KeyBackspace"), CMIntAsNumber(EC_BKSPACE),
                         CMLoc(@"KeyReturn"),    CMIntAsNumber(EC_RETURN),
                         CMLoc(@"KeySpace"),     CMIntAsNumber(EC_SPACE),
                         CMLoc(@"KeyPrint"),     CMIntAsNumber(EC_PRINT),
                         CMLoc(@"KeyPause"),     CMIntAsNumber(EC_PAUSE),
                         
                         // Joystick
                         CMLoc(@"JoyButtonOne"), CMIntAsNumber(EC_JOY1_BUTTON1),
                         CMLoc(@"JoyButtonTwo"), CMIntAsNumber(EC_JOY1_BUTTON2),
                         CMLoc(@"JoyUp"),        CMIntAsNumber(EC_JOY1_UP),
                         CMLoc(@"JoyDown"),      CMIntAsNumber(EC_JOY1_DOWN),
                         CMLoc(@"JoyLeft"),      CMIntAsNumber(EC_JOY1_LEFT),
                         CMLoc(@"JoyRight"),     CMIntAsNumber(EC_JOY1_RIGHT),
                         
                         CMLoc(@"JoyButtonOne"), CMIntAsNumber(EC_JOY2_BUTTON1),
                         CMLoc(@"JoyButtonTwo"), CMIntAsNumber(EC_JOY2_BUTTON2),
                         CMLoc(@"JoyUp"),        CMIntAsNumber(EC_JOY2_UP),
                         CMLoc(@"JoyDown"),      CMIntAsNumber(EC_JOY2_DOWN),
                         CMLoc(@"JoyLeft"),      CMIntAsNumber(EC_JOY2_LEFT),
                         CMLoc(@"JoyRight"),     CMIntAsNumber(EC_JOY2_RIGHT),
                         
                         nil];
}

- (id)init
{
    if ((self = [super init]))
    {
        [self resetState];
    }
    
    return self;
}

- (void)dealloc
{
    self.emulatorHasFocus = NO;
    
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
    
    [self handleKeyEvent:event.keyCode isDown:YES];
}

- (void)keyUp:(NSEvent*)event
{
    if ([event isARepeat])
        return;
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"keyUp: %i", [event keyCode]);
#endif
    
    [self handleKeyEvent:event.keyCode isDown:NO];
}

- (void)flagsChanged:(NSEvent *)event
{
#ifdef DEBUG_KEY_STATE
    NSLog(@"flagsChanged: %1$x; flags: %2$ld (0x%2$lx)",
          event.keyCode, event.modifierFlags);
#endif
    
    if (event.keyCode == CMKeyLeftShift)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftShiftKeyMask) == CMLeftShiftKeyMask)];
    else if (event.keyCode == CMKeyRightShift)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightShiftKeyMask) == CMRightShiftKeyMask)];
    else if (event.keyCode == CMKeyLeftAlt)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftAltKeyMask) == CMLeftAltKeyMask)];
    else if (event.keyCode == CMKeyRightAlt)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightAltKeyMask) == CMRightAltKeyMask)];
    else if (event.keyCode == CMKeyLeftControl)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftControlKeyMask) == CMLeftControlKeyMask)];
    else if (event.keyCode == CMKeyRightControl)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightControlKeyMask) == CMRightControlKeyMask)];
    else if (event.keyCode == CMKeyLeftCommand)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftCommandKeyMask) == CMLeftCommandKeyMask)];
    else if (event.keyCode == CMKeyRightCommand)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightCommandKeyMask) == CMRightCommandKeyMask)];
    else if (event.keyCode == CMKeyCapsLock)
    {
        // Caps Lock has no up/down - just toggle state
        CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:event.keyCode];
        NSInteger virtualCode = [theEmulator.keyboardLayout virtualCodeForInputMethod:input];
        
        if (virtualCode != CMUnknownVirtualCode)
        {
            if (!inputEventGetState(virtualCode))
                inputEventSet(virtualCode);
            else
                inputEventUnset(virtualCode);
        }
    }
    
    if (event.keyCode == CMKeyLeftCommand || event.keyCode == CMKeyRightCommand)
    {
        // If Command is toggled while another key is down, releasing the
        // other key no longer generates a keyUp event, and the virtual key
        // 'sticks'. Release all virtual keys if Command is pressed.
        
        [self releaseAllKeys];
    }
}

#pragma mark - Public methods

- (void)releaseAllKeys
{
    inputEventReset();
}

- (BOOL)areAnyKeysDown
{
    for (int virtualKey = 0; virtualKey < EC_KEYCOUNT; virtualKey++)
        if (inputEventGetState(virtualKey))
            return YES;
    
    return NO;
}

- (void)resetState
{
    [self releaseAllKeys];
}

- (void)setEmulatorHasFocus:(BOOL)focus
{
    if (!focus)
    {
#if DEBUG
        NSLog(@"CMCocoaKeyboard: -Focus");
#endif
        // Emulator has lost focus - release all virtual keys
        [self resetState];
    }
    else
    {
#if DEBUG
        NSLog(@"CMCocoaKeyboard: +Focus");
#endif
    }
}

- (NSString *)inputNameForVirtualCode:(NSUInteger)virtualCode
{
    return [virtualCodeNames objectForKey:CMIntAsNumber(virtualCode)];
}

- (NSInteger)categoryForVirtualCode:(NSUInteger)virtualCode
{
    switch (virtualCode)
    {
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
        case EC_A:
        case EC_B:
        case EC_C:
        case EC_D:
        case EC_E:
        case EC_F:
        case EC_G:
        case EC_H:
        case EC_I:
        case EC_J:
        case EC_K:
        case EC_L:
        case EC_M:
        case EC_N:
        case EC_O:
        case EC_P:
        case EC_Q:
        case EC_R:
        case EC_S:
        case EC_T:
        case EC_U:
        case EC_V:
        case EC_W:
        case EC_X:
        case EC_Y:
        case EC_Z:
        case EC_0:
        case EC_1:
        case EC_2:
        case EC_3:
        case EC_4:
        case EC_5:
        case EC_6:
        case EC_7:
        case EC_8:
        case EC_9:
            return CMKeyCategoryCharacters;
        case EC_NEG:
        case EC_BKSLASH:
        case EC_AT:
        case EC_LBRACK:
        case EC_RBRACK:
        case EC_CIRCFLX:
        case EC_SEMICOL:
        case EC_COLON:
        case EC_COMMA:
        case EC_PERIOD:
        case EC_DIV:
        case EC_UNDSCRE:
            return CMKeyCategorySymbols;
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
        case CMKeyCategoryCharacters:
            return CMLoc(@"KeyCategoryCharacters");
        case CMKeyCategorySymbols:
            return CMLoc(@"KeyCategorySymbols");
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
    
    [theEmulator.inputDeviceLayouts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMInputDeviceLayout *layout = obj;
        NSInteger virtualCode = [layout virtualCodeForInputMethod:input];
        
        if (virtualCode != CMUnknownVirtualCode)
        {
            if (isDown)
            {
                if (!inputEventGetState(virtualCode))
                    inputEventSet(virtualCode);
            }
            else
            {
                if (inputEventGetState(virtualCode))
                    inputEventUnset(virtualCode);
            }
        }
    }];
}

- (void)updateKeyboardState
{
    // FIXME: this is where we need to actually update the matrix
}

#pragma mark - BlueMSX Callbacks

extern CMEmulatorController *theEmulator;

void archPollInput()
{
    @autoreleasepool
    {
        [theEmulator.keyboard updateKeyboardState];
    }
}

void archKeyboardSetSelectedKey(int keyCode) {}

@end
