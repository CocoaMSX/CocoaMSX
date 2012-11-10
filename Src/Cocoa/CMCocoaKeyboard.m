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
#import "CMEmulatorController.h"
#import "CMKeyLayout.h"
#import "CMPreferences.h"

#include "InputEvent.h"

// FIXME: this class needs to poll, and not just modify the virtual matrix
//        whenever a key is pressed

#pragma mark - CocoaKeyboard

@interface CMCocoaKeyboard ()

- (void)updateModifiersWithFlags:(NSUInteger)flags;
- (void)updateKeyboardState;

@end

@implementation CMCocoaKeyboard

- (id)init
{
    if ((self = [super init]))
    {
        [self resetState];
        
        currentLayout = [[[CMPreferences preferences] keyboardLayout] retain];
    }
    
    return self;
}

- (void)dealloc
{
    self.emulatorHasFocus = NO;
    
    [currentLayout release];
    
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
    
    CMKeyMapping *key = [currentLayout findMappingOfEvent:event];
    if (key && !inputEventGetState(key.virtualCode))
        inputEventSet(key.virtualCode);
}

- (void)keyUp:(NSEvent*)event
{
    if ([event isARepeat])
        return;
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"keyUp: %i", [event keyCode]);
#endif
    
    CMKeyMapping *key = [currentLayout findMappingOfEvent:event];
    if (key && inputEventGetState(key.virtualCode))
        inputEventUnset(key.virtualCode);
}

- (void)flagsChanged:(NSEvent *)event
{
#ifdef DEBUG_KEY_STATE
    NSLog(@"flagsChanged: %1$x; flags: %2$ld (0x%2$lx)",
          event.keyCode, event.modifierFlags);
#endif
    
    if (((event.modifierFlags & NSCommandKeyMask) == NSCommandKeyMask) ||
        isLCommandDown || isRCommandDown)
    {
        // If Command is toggled while another key is down, releasing the
        // other key no longer generates a keyUp event, and the virtual key
        // 'sticks'. Release all other virtual keys if Command is pressed.
        
        for (int virtualKey = 0; virtualKey < EC_KEYCOUNT; virtualKey++)
        {
            if (inputEventGetState(virtualKey))
            {
                CMKeyMapping *mapping = [currentLayout findMappingOfVirtualKey:virtualKey];
                if ((mapping.keyModifier & NSCommandKeyMask) != NSCommandKeyMask)
                {
                    // Release the virtual key
                    inputEventUnset(virtualKey);
                }
            }
        }
    }
    
    [self updateModifiersWithFlags:[event modifierFlags]];
}

#pragma mark - Public methods

- (void)releaseAllKeys
{
    for (int virtualKey = 0; virtualKey < EC_KEYCOUNT; virtualKey++)
        if (inputEventGetState(virtualKey))
            inputEventUnset(virtualKey);
}

- (BOOL)isAnyKeyDown
{
    for (int virtualKey = 0; virtualKey < EC_KEYCOUNT; virtualKey++)
        if (inputEventGetState(virtualKey))
            return YES;
    
    return NO;
}

- (CMKeyLayout *)currentLayout
{
    return currentLayout;
}

- (void)resetState
{
    inputEventReset();
    
    isRShiftDown = NO;
    isLShiftDown = NO;
    isLAltDown = NO;
    isRAltDown = NO;
    isLCommandDown = NO;
    isRCommandDown = NO;
    isLeftCtrlDown = NO;
    isRightCtrlDown = NO;
    isCapsLockOn = NO;
    
    [self updateModifiersWithFlags:[NSEvent modifierFlags]];
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
        // Emulator has gained focus - toggle Caps Lock
        [self updateModifiersWithFlags:[NSEvent modifierFlags]];
    }
}

#pragma mark - Private methods

- (void)updateKeyboardState
{
    // TODO: this is where we need to actually update the matrix
}

- (void)updateModifiersWithFlags:(NSUInteger)flags
{
    CMKeyMapping *leftShiftMap = [currentLayout findMappingOfPhysicalModifier:CMLeftShiftKeyMask];
    CMKeyMapping *rightShiftMap = [currentLayout findMappingOfPhysicalModifier:CMRightShiftKeyMask];
    CMKeyMapping *leftAltMap = [currentLayout findMappingOfPhysicalModifier:CMLeftAltKeyMask];
    CMKeyMapping *rightAltMap = [currentLayout findMappingOfPhysicalModifier:CMRightAltKeyMask];
    CMKeyMapping *leftCommandMap = [currentLayout findMappingOfPhysicalModifier:CMLeftCommandKeyMask];
    CMKeyMapping *rightCommandMap = [currentLayout findMappingOfPhysicalModifier:CMRightCommandKeyMask];
    CMKeyMapping *leftCtrlMap = [currentLayout findMappingOfPhysicalModifier:CMLeftControlKeyMask];
    CMKeyMapping *rightCtrlMap = [currentLayout findMappingOfPhysicalModifier:CMRightControlKeyMask];
    CMKeyMapping *capsLockMap = [currentLayout findMappingOfPhysicalModifier:CMCapsLockKeyMask];
    
    BOOL isLShiftDownNow = (flags & CMLeftShiftKeyMask) == CMLeftShiftKeyMask ? YES : NO;
    BOOL isRShiftDownNow = (flags & CMRightShiftKeyMask) == CMRightShiftKeyMask ? YES : NO;
    BOOL isLAltDownNow = (flags & CMLeftAltKeyMask) == CMLeftAltKeyMask ? YES : NO;
    BOOL isRAltDownNow = (flags & CMRightAltKeyMask) == CMRightAltKeyMask ? YES : NO;
    BOOL isLCommandDownNow = (flags & CMLeftCommandKeyMask) == CMLeftCommandKeyMask ? YES : NO;
    BOOL isRCommandDownNow = (flags & CMRightCommandKeyMask) == CMRightCommandKeyMask ? YES : NO;
    BOOL isLeftCtrlDownNow =  (flags & CMLeftControlKeyMask) == CMLeftControlKeyMask ? YES : NO;
    BOOL isRightCtrlDownNow =  (flags & CMRightControlKeyMask) == CMRightControlKeyMask ? YES : NO;
    BOOL isCapsLockOnNow = (flags & CMCapsLockKeyMask) == CMCapsLockKeyMask ? YES : NO;
    
    if (isLShiftDown != isLShiftDownNow)
    {
        isLShiftDown = isLShiftDownNow;
        if (isLShiftDownNow)
            inputEventSet(leftShiftMap.virtualCode);
        else
            inputEventUnset(leftShiftMap.virtualCode);
    }
    
    if (isRShiftDown != isRShiftDownNow)
    {
        isRShiftDown = isRShiftDownNow;
        if (isRShiftDownNow)
            inputEventSet(rightShiftMap.virtualCode);
        else
            inputEventUnset(rightShiftMap.virtualCode);
    }
    
    if (isLeftCtrlDown != isLeftCtrlDownNow)
    {
        isLeftCtrlDown = isLeftCtrlDownNow;
        if (isLeftCtrlDownNow)
            inputEventSet(leftCtrlMap.virtualCode);
        else
            inputEventUnset(leftCtrlMap.virtualCode);
    }
    
    if (isRightCtrlDown != isRightCtrlDownNow)
    {
        isRightCtrlDown = isRightCtrlDownNow;
        if (isRightCtrlDownNow)
            inputEventSet(rightCtrlMap.virtualCode);
        else
            inputEventUnset(rightCtrlMap.virtualCode);
    }
    
    if (isLAltDown != isLAltDownNow)
    {
        isLAltDown = isLAltDownNow;
        if (isLAltDownNow)
            inputEventSet(leftAltMap.virtualCode);
        else
            inputEventUnset(leftAltMap.virtualCode);
    }
    
    if (isRAltDown != isRAltDownNow)
    {
        isRAltDown = isRAltDownNow;
        if (isRAltDownNow)
            inputEventSet(rightAltMap.virtualCode);
        else
            inputEventUnset(rightAltMap.virtualCode);
    }
    
    if (isLCommandDown != isLCommandDownNow)
    {
        isLCommandDown = isLCommandDownNow;
        if (isLCommandDownNow)
            inputEventSet(leftCommandMap.virtualCode);
        else
            inputEventUnset(leftCommandMap.virtualCode);
    }
    
    if (isRCommandDown != isRCommandDownNow)
    {
        isRCommandDown = isRCommandDownNow;
        if (isRCommandDownNow)
            inputEventSet(rightCommandMap.virtualCode);
        else
            inputEventUnset(rightCommandMap.virtualCode);
    }
    
    if (isCapsLockOn != isCapsLockOnNow)
    {
        // FIXME seems to toggle off by itself?
        isCapsLockOn = isCapsLockOnNow;
        if (isCapsLockOnNow)
            inputEventSet(capsLockMap.virtualCode);
        else
            inputEventUnset(capsLockMap.virtualCode);
    }
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
char* archGetSelectedKey() { return ""; }
char* archGetMappedKey() { return ""; }

int archKeyboardIsKeyConfigured(int msxKeyCode) { return 0; }
int archKeyboardIsKeySelected(int msxKeyCode) { return 0; }
char* archKeyconfigSelectedKeyTitle() { return ""; }
char* archKeyconfigMappedToTitle() { return ""; }
char* archKeyconfigMappingSchemeTitle() { return ""; }

@end
