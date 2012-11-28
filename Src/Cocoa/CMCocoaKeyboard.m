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

//#define DEBUG_KEY_STATE

#pragma mark - CocoaKeyboard

@interface CMCocoaKeyboard ()

- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;

@end

@implementation CMCocoaKeyboard

- (id)init
{
    if ((self = [super init]))
    {
        [self resetState];
        
        currentLayout = [[[CMPreferences preferences] keyboardLayout] retain];
        isCommandDown = NO;
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
        CMKeyMapping *key = [currentLayout findMappingOfPhysicalKeyCode:event.keyCode];
        if (key)
        {
            if (!inputEventGetState(key.virtualCode))
                inputEventSet(key.virtualCode);
            else
                inputEventUnset(key.virtualCode);
        }
    }
    
    if (((event.modifierFlags & NSCommandKeyMask) == NSCommandKeyMask) || isCommandDown)
    {
        // If Command is toggled while another key is down, releasing the
        // other key no longer generates a keyUp event, and the virtual key
        // 'sticks'. Release all other virtual keys if Command is pressed.
        
        for (int virtualKey = 0; virtualKey < EC_KEYCOUNT; virtualKey++)
        {
            if (inputEventGetState(virtualKey))
            {
                CMKeyMapping *mapping = [currentLayout findMappingOfVirtualKey:virtualKey];
                if (mapping.keyCode != CMKeyLeftCommand && mapping.keyCode != CMKeyRightCommand)
                {
                    // Release the virtual key
                    inputEventUnset(virtualKey);
                }
            }
        }
    }
    
    isCommandDown = ((event.modifierFlags & NSCommandKeyMask) == NSCommandKeyMask);
    
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

#pragma mark - Private methods

- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown
{
    if (isDown)
    {
        CMKeyMapping *key = [currentLayout findMappingOfPhysicalKeyCode:keyCode];
        if (key && !inputEventGetState(key.virtualCode))
            inputEventSet(key.virtualCode);
    }
    else
    {
        CMKeyMapping *key = [currentLayout findMappingOfPhysicalKeyCode:keyCode];
        if (key && inputEventGetState(key.virtualCode))
            inputEventUnset(key.virtualCode);
    }
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
char* archGetSelectedKey() { return ""; }
char* archGetMappedKey() { return ""; }

int archKeyboardIsKeyConfigured(int msxKeyCode) { return 0; }
int archKeyboardIsKeySelected(int msxKeyCode) { return 0; }
char* archKeyconfigSelectedKeyTitle() { return ""; }
char* archKeyconfigMappedToTitle() { return ""; }
char* archKeyconfigMappingSchemeTitle() { return ""; }

@end
