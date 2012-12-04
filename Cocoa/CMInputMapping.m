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
#import "CMInputMapping.h"

#include "InputEvent.h"

#define CMIntAsNumber(x) [NSNumber numberWithInteger:x]
#define CMLoc(x)         NSLocalizedString(x, nil)

@interface CMInputMapping ()

+ (NSDictionary *)virtualInputNames;

@end

@implementation CMInputMapping

- (id)initWithVirtualCode:(NSUInteger)virtualCode
{
    if ((self = [super init]))
    {
        self.virtualCode = virtualCode;
    }
    
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.virtualCode = [(NSNumber*)[decoder decodeObjectForKey:@"virtualCode"] unsignedIntegerValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:self.virtualCode] forKey:@"virtualCode"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMInputMapping *copy = [[CMInputMapping allocWithZone:zone] init];
    
    copy.virtualCode = self.virtualCode;
    
    return copy;
}

#pragma mark - Etc.

+ (NSDictionary *)virtualInputNames
{
    static NSDictionary *virtualKeyNames = nil;
    
    if (!virtualKeyNames)
    {
        NSString *numpadFormat = CMLoc(@"KeyNumpad_f");
        
        virtualKeyNames = [[NSDictionary dictionaryWithObjectsAndKeys:
                            
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
                            CMLoc(@"KeyF1"), CMIntAsNumber(EC_F1),
                            CMLoc(@"KeyF2"), CMIntAsNumber(EC_F2),
                            CMLoc(@"KeyF3"), CMIntAsNumber(EC_F3),
                            CMLoc(@"KeyF4"), CMIntAsNumber(EC_F4),
                            CMLoc(@"KeyF5"), CMIntAsNumber(EC_F5),
                            
                            // Alpha
                            CMLoc(@"KeyA"), CMIntAsNumber(EC_A),
                            CMLoc(@"KeyB"), CMIntAsNumber(EC_B),
                            CMLoc(@"KeyC"), CMIntAsNumber(EC_C),
                            CMLoc(@"KeyD"), CMIntAsNumber(EC_D),
                            CMLoc(@"KeyE"), CMIntAsNumber(EC_E),
                            CMLoc(@"KeyF"), CMIntAsNumber(EC_F),
                            CMLoc(@"KeyG"), CMIntAsNumber(EC_G),
                            CMLoc(@"KeyH"), CMIntAsNumber(EC_H),
                            CMLoc(@"KeyI"), CMIntAsNumber(EC_I),
                            CMLoc(@"KeyJ"), CMIntAsNumber(EC_J),
                            CMLoc(@"KeyK"), CMIntAsNumber(EC_K),
                            CMLoc(@"KeyL"), CMIntAsNumber(EC_L),
                            CMLoc(@"KeyM"), CMIntAsNumber(EC_M),
                            CMLoc(@"KeyN"), CMIntAsNumber(EC_N),
                            CMLoc(@"KeyO"), CMIntAsNumber(EC_O),
                            CMLoc(@"KeyP"), CMIntAsNumber(EC_P),
                            CMLoc(@"KeyQ"), CMIntAsNumber(EC_Q),
                            CMLoc(@"KeyR"), CMIntAsNumber(EC_R),
                            CMLoc(@"KeyS"), CMIntAsNumber(EC_S),
                            CMLoc(@"KeyT"), CMIntAsNumber(EC_T),
                            CMLoc(@"KeyU"), CMIntAsNumber(EC_U),
                            CMLoc(@"KeyV"), CMIntAsNumber(EC_V),
                            CMLoc(@"KeyW"), CMIntAsNumber(EC_W),
                            CMLoc(@"KeyX"), CMIntAsNumber(EC_X),
                            CMLoc(@"KeyY"), CMIntAsNumber(EC_Y),
                            CMLoc(@"KeyZ"), CMIntAsNumber(EC_Z),
                            
                            // Numbers
                            CMLoc(@"Key0"), CMIntAsNumber(EC_0),
                            CMLoc(@"Key1"), CMIntAsNumber(EC_1),
                            CMLoc(@"Key2"), CMIntAsNumber(EC_2),
                            CMLoc(@"Key3"), CMIntAsNumber(EC_3),
                            CMLoc(@"Key4"), CMIntAsNumber(EC_4),
                            CMLoc(@"Key5"), CMIntAsNumber(EC_5),
                            CMLoc(@"Key6"), CMIntAsNumber(EC_6),
                            CMLoc(@"Key7"), CMIntAsNumber(EC_7),
                            CMLoc(@"Key8"), CMIntAsNumber(EC_8),
                            CMLoc(@"Key9"), CMIntAsNumber(EC_9),
                            
                            // Numpad
                            [NSString stringWithFormat:numpadFormat, @"*"], CMIntAsNumber(EC_NUMMUL),
                            [NSString stringWithFormat:numpadFormat, @"+"], CMIntAsNumber(EC_NUMADD),
                            [NSString stringWithFormat:numpadFormat, @"/"], CMIntAsNumber(EC_NUMDIV),
                            [NSString stringWithFormat:numpadFormat, @"-"], CMIntAsNumber(EC_NUMSUB),
                            [NSString stringWithFormat:numpadFormat, @"."], CMIntAsNumber(EC_NUMPER),
                            [NSString stringWithFormat:numpadFormat, @","], CMIntAsNumber(EC_NUMCOM),
                            [NSString stringWithFormat:numpadFormat, @"0"], CMIntAsNumber(EC_NUM0),
                            [NSString stringWithFormat:numpadFormat, @"1"], CMIntAsNumber(EC_NUM1),
                            [NSString stringWithFormat:numpadFormat, @"2"], CMIntAsNumber(EC_NUM2),
                            [NSString stringWithFormat:numpadFormat, @"3"], CMIntAsNumber(EC_NUM3),
                            [NSString stringWithFormat:numpadFormat, @"4"], CMIntAsNumber(EC_NUM4),
                            [NSString stringWithFormat:numpadFormat, @"5"], CMIntAsNumber(EC_NUM5),
                            [NSString stringWithFormat:numpadFormat, @"6"], CMIntAsNumber(EC_NUM6),
                            [NSString stringWithFormat:numpadFormat, @"7"], CMIntAsNumber(EC_NUM7),
                            [NSString stringWithFormat:numpadFormat, @"8"], CMIntAsNumber(EC_NUM8),
                            [NSString stringWithFormat:numpadFormat, @"9"], CMIntAsNumber(EC_NUM9),
                            
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
                            
                            // Symbols
                            CMLoc(@"KeyMinus"),        CMIntAsNumber(EC_NEG),
                            CMLoc(@"KeyBackslash"),    CMIntAsNumber(EC_BKSLASH),
                            CMLoc(@"KeyAt"),           CMIntAsNumber(EC_AT),
                            CMLoc(@"KeyLeftBracket"),  CMIntAsNumber(EC_LBRACK),
                            CMLoc(@"KeyRightBracket"), CMIntAsNumber(EC_RBRACK),
                            CMLoc(@"KeyCaret"),        CMIntAsNumber(EC_CIRCFLX),
                            CMLoc(@"KeySemicolon"),    CMIntAsNumber(EC_SEMICOL),
                            CMLoc(@"KeyColon"),        CMIntAsNumber(EC_COLON),
                            CMLoc(@"KeyComma"),        CMIntAsNumber(EC_COMMA),
                            CMLoc(@"KeyPeriod"),       CMIntAsNumber(EC_PERIOD),
                            CMLoc(@"KeySlash"),        CMIntAsNumber(EC_DIV),
                            CMLoc(@"KeyUnderscore"),   CMIntAsNumber(EC_UNDSCRE),
                            
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
                            
                            nil] retain];
    }
    
    return virtualKeyNames;
}

- (NSString *)inputName
{
    return [[CMInputMapping virtualInputNames] objectForKey:CMIntAsNumber(self.virtualCode)];
}

- (NSInteger)category
{
    switch (self.virtualCode)
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
            return CMKeyCategoryAlpha;
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
            return CMKeyCategoryNumeric;
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
        default:
            return 0;
    }
}

- (NSString *)categoryName
{
    switch ([self category])
    {
        case CMKeyCategoryModifier:
            return NSLocalizedString(@"KeyCategoryModifier", nil);
        case CMKeyCategoryDirectional:
            return NSLocalizedString(@"KeyCategoryDirectional", nil);
        case CMKeyCategoryFunction:
            return NSLocalizedString(@"KeyCategoryFunction", nil);
        case CMKeyCategoryAlpha:
            return NSLocalizedString(@"KeyCategoryAlpha", nil);
        case CMKeyCategoryNumeric:
            return NSLocalizedString(@"KeyCategoryNumeric", nil);
        case CMKeyCategoryNumericPad:
            return NSLocalizedString(@"KeyCategoryNumericPad", nil);
        case CMKeyCategorySpecial:
            return NSLocalizedString(@"KeyCategorySpecial", nil);
        case CMKeyCategorySymbols:
            return NSLocalizedString(@"KeyCategorySymbols", nil);
    }
    
    return nil;
}

#pragma mark - "Abstract"

- (BOOL)isMapped
{
    return NO;
}

@end