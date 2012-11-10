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
#import <Carbon/Carbon.h>

#import "CMKeyLayout.h"

#include "InputEvent.h"

#define CMIntAsNumber(x) ([NSNumber numberWithInteger:x])
#define CMLocalized(x)   (NSLocalizedString(x, nil))

#pragma mark - CMKeyMapping

@interface CMKeyMapping ()

+ (NSArray *)numpadKeyCodes;
+ (NSDictionary *)virtualKeyNames;
+ (NSDictionary *)physicalKeyNames;

+ (CMKeyMapping *)virtualKey:(NSUInteger)virtualKey;

@end

@implementation CMKeyMapping

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.keyCode = [decoder decodeIntegerForKey:@"keyCode"];
        self.virtualCode = [(NSNumber*)[decoder decodeObjectForKey:@"virtualCode"] unsignedIntegerValue];
        self.keyModifier = [(NSNumber*)[decoder decodeObjectForKey:@"keyModifier"] unsignedIntegerValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:self.keyCode forKey:@"keyCode"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:self.virtualCode] forKey:@"virtualCode"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:self.keyModifier] forKey:@"keyModifier"];
}

+ (CMKeyMapping *)virtualKey:(NSUInteger)virtualKey
{
    CMKeyMapping *key = [[CMKeyMapping alloc] init];
    
    key.keyCode = CMKeyNoCode;
    key.keyModifier = CMKeyNoModifiers;
    key.virtualCode = virtualKey;
    
    return [key autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    CMKeyMapping *copy = [[CMKeyMapping allocWithZone:zone] init];
    
    copy.virtualCode = self.virtualCode;
    copy.keyCode = self.keyCode;
    copy.keyModifier = self.keyModifier;
    
    return copy;
}

+ (NSDictionary *)physicalKeyNames
{
    static NSDictionary *physicalKeyNames = nil;
    
    if (!physicalKeyNames)
        physicalKeyNames = [[NSDictionary dictionaryWithObjectsAndKeys:
                             @"F1",  [NSNumber numberWithInteger:122],
                             @"F2",  [NSNumber numberWithInteger:120],
                             @"F3",  [NSNumber numberWithInteger:99],
                             @"F4",  [NSNumber numberWithInteger:118],
                             @"F5",  [NSNumber numberWithInteger:96],
                             @"F6",  [NSNumber numberWithInteger:97],
                             @"F7",  [NSNumber numberWithInteger:98],
                             @"F8",  [NSNumber numberWithInteger:100],
                             @"F9",  [NSNumber numberWithInteger:101],
                             @"F10", [NSNumber numberWithInteger:109],
                             @"F11", [NSNumber numberWithInteger:103],
                             @"F12", [NSNumber numberWithInteger:111],
                             @"F13", [NSNumber numberWithInteger:105],
                             @"F14", [NSNumber numberWithInteger:107],
                             @"F15", [NSNumber numberWithInteger:113],
                             @"F16", [NSNumber numberWithInteger:106],
                             @"F17", [NSNumber numberWithInteger:64],
                             @"F18", [NSNumber numberWithInteger:79],
                             @"F19", [NSNumber numberWithInteger:80],
                             
                             NSLocalizedString(@"KeySpace", nil), [NSNumber numberWithInteger:49],
                             
                             // Glyphs
                             [NSString stringWithFormat:@"%C", (unsigned short)0x232b], [NSNumber numberWithInteger:51],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2326], [NSNumber numberWithInteger:117],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2327], [NSNumber numberWithInteger:71],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2190], [NSNumber numberWithInteger:123],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2192], [NSNumber numberWithInteger:124],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2191], [NSNumber numberWithInteger:126],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2193], [NSNumber numberWithInteger:125],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2198], [NSNumber numberWithInteger:119],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2196], [NSNumber numberWithInteger:115],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x238b], [NSNumber numberWithInteger:53],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x21df], [NSNumber numberWithInteger:121],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x21de], [NSNumber numberWithInteger:116],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x21a9], [NSNumber numberWithInteger:36],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x2305], [NSNumber numberWithInteger:76],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x21e5], [NSNumber numberWithInteger:48],
                             [NSString stringWithFormat:@"%C", (unsigned short)0x003f], [NSNumber numberWithInteger:114],
                             
                             nil] retain];
    
    return physicalKeyNames;
}

+ (NSArray *)numpadKeyCodes
{
    static NSArray *numpadKeyCodes = nil;
    
    if (!numpadKeyCodes)
        numpadKeyCodes = [[NSArray alloc] initWithObjects:
                          
                          [NSNumber numberWithInteger:65], // ,
                          [NSNumber numberWithInteger:67], // *
                          [NSNumber numberWithInteger:69], // +
                          [NSNumber numberWithInteger:75], // /
                          [NSNumber numberWithInteger:78], // -
                          [NSNumber numberWithInteger:81], // =
                          [NSNumber numberWithInteger:82], // 0
                          [NSNumber numberWithInteger:83], // 1
                          [NSNumber numberWithInteger:84], // 2
                          [NSNumber numberWithInteger:85], // 3
                          [NSNumber numberWithInteger:86], // 4
                          [NSNumber numberWithInteger:87], // 5
                          [NSNumber numberWithInteger:88], // 6
                          [NSNumber numberWithInteger:89], // 7
                          [NSNumber numberWithInteger:91], // 8
                          [NSNumber numberWithInteger:92], // 9
                          
                          nil];
    
    return numpadKeyCodes;
}

+ (NSDictionary *)virtualKeyNames
{
    static NSDictionary *virtualKeyNames = nil;
    
    if (!virtualKeyNames)
    {
        NSString *numpadFormat = CMLocalized(@"KeyNumpad_f");
        
        virtualKeyNames = [[NSDictionary dictionaryWithObjectsAndKeys:
                            
                            // Modifiers
                            CMLocalized(@"KeyLeftShift"),  CMIntAsNumber(EC_LSHIFT),
                            CMLocalized(@"KeyRightShift"), CMIntAsNumber(EC_RSHIFT),
                            CMLocalized(@"KeyCtrl"),       CMIntAsNumber(EC_CTRL),
                            CMLocalized(@"KeyGraph"),      CMIntAsNumber(EC_GRAPH),
                            CMLocalized(@"KeyCode"),       CMIntAsNumber(EC_CODE),
                            CMLocalized(@"KeyTorike"),     CMIntAsNumber(EC_TORIKE),
                            CMLocalized(@"KeyJikkou"),     CMIntAsNumber(EC_JIKKOU),
                            CMLocalized(@"KeyCapsLock"),   CMIntAsNumber(EC_CAPS),
                            
                            // Directional
                            CMLocalized(@"KeyCursorLeft"),  CMIntAsNumber(EC_LEFT),
                            CMLocalized(@"KeyCursorUp"),    CMIntAsNumber(EC_UP),
                            CMLocalized(@"KeyCursorRight"), CMIntAsNumber(EC_RIGHT),
                            CMLocalized(@"KeyCursorDown"),  CMIntAsNumber(EC_DOWN),
                            
                            // Function
                            CMLocalized(@"KeyF1"), CMIntAsNumber(EC_F1),
                            CMLocalized(@"KeyF2"), CMIntAsNumber(EC_F2),
                            CMLocalized(@"KeyF3"), CMIntAsNumber(EC_F3),
                            CMLocalized(@"KeyF4"), CMIntAsNumber(EC_F4),
                            CMLocalized(@"KeyF5"), CMIntAsNumber(EC_F5),
                            
                            // Alpha
                            CMLocalized(@"KeyA"), CMIntAsNumber(EC_A),
                            CMLocalized(@"KeyB"), CMIntAsNumber(EC_B),
                            CMLocalized(@"KeyC"), CMIntAsNumber(EC_C),
                            CMLocalized(@"KeyD"), CMIntAsNumber(EC_D),
                            CMLocalized(@"KeyE"), CMIntAsNumber(EC_E),
                            CMLocalized(@"KeyF"), CMIntAsNumber(EC_F),
                            CMLocalized(@"KeyG"), CMIntAsNumber(EC_G),
                            CMLocalized(@"KeyH"), CMIntAsNumber(EC_H),
                            CMLocalized(@"KeyI"), CMIntAsNumber(EC_I),
                            CMLocalized(@"KeyJ"), CMIntAsNumber(EC_J),
                            CMLocalized(@"KeyK"), CMIntAsNumber(EC_K),
                            CMLocalized(@"KeyL"), CMIntAsNumber(EC_L),
                            CMLocalized(@"KeyM"), CMIntAsNumber(EC_M),
                            CMLocalized(@"KeyN"), CMIntAsNumber(EC_N),
                            CMLocalized(@"KeyO"), CMIntAsNumber(EC_O),
                            CMLocalized(@"KeyP"), CMIntAsNumber(EC_P),
                            CMLocalized(@"KeyQ"), CMIntAsNumber(EC_Q),
                            CMLocalized(@"KeyR"), CMIntAsNumber(EC_R),
                            CMLocalized(@"KeyS"), CMIntAsNumber(EC_S),
                            CMLocalized(@"KeyT"), CMIntAsNumber(EC_T),
                            CMLocalized(@"KeyU"), CMIntAsNumber(EC_U),
                            CMLocalized(@"KeyV"), CMIntAsNumber(EC_V),
                            CMLocalized(@"KeyW"), CMIntAsNumber(EC_W),
                            CMLocalized(@"KeyX"), CMIntAsNumber(EC_X),
                            CMLocalized(@"KeyY"), CMIntAsNumber(EC_Y),
                            CMLocalized(@"KeyZ"), CMIntAsNumber(EC_Z),
                            
                            // Numbers
                            CMLocalized(@"Key0"), CMIntAsNumber(EC_0),
                            CMLocalized(@"Key1"), CMIntAsNumber(EC_1),
                            CMLocalized(@"Key2"), CMIntAsNumber(EC_2),
                            CMLocalized(@"Key3"), CMIntAsNumber(EC_3),
                            CMLocalized(@"Key4"), CMIntAsNumber(EC_4),
                            CMLocalized(@"Key5"), CMIntAsNumber(EC_5),
                            CMLocalized(@"Key6"), CMIntAsNumber(EC_6),
                            CMLocalized(@"Key7"), CMIntAsNumber(EC_7),
                            CMLocalized(@"Key8"), CMIntAsNumber(EC_8),
                            CMLocalized(@"Key9"), CMIntAsNumber(EC_9),
                            
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
                            CMLocalized(@"KeyEscape"),    CMIntAsNumber(EC_ESC),
                            CMLocalized(@"KeyTab"),       CMIntAsNumber(EC_TAB),
                            CMLocalized(@"KeyStop"),      CMIntAsNumber(EC_STOP),
                            CMLocalized(@"KeyCls"),       CMIntAsNumber(EC_CLS),
                            CMLocalized(@"KeySelect"),    CMIntAsNumber(EC_SELECT),
                            CMLocalized(@"KeyInsert"),    CMIntAsNumber(EC_INS),
                            CMLocalized(@"KeyDelete"),    CMIntAsNumber(EC_DEL),
                            CMLocalized(@"KeyBackspace"), CMIntAsNumber(EC_BKSPACE),
                            CMLocalized(@"KeyReturn"),    CMIntAsNumber(EC_RETURN),
                            CMLocalized(@"KeySpace"),     CMIntAsNumber(EC_SPACE),
                            CMLocalized(@"KeyPrint"),     CMIntAsNumber(EC_PRINT),
                            CMLocalized(@"KeyPause"),     CMIntAsNumber(EC_PAUSE),
                            
                            // Symbols
                            CMLocalized(@"KeyMinus"),        CMIntAsNumber(EC_NEG),
                            CMLocalized(@"KeyBackslash"),    CMIntAsNumber(EC_BKSLASH),
                            CMLocalized(@"KeyAt"),           CMIntAsNumber(EC_AT),
                            CMLocalized(@"KeyLeftBracket"),  CMIntAsNumber(EC_LBRACK),
                            CMLocalized(@"KeyRightBracket"), CMIntAsNumber(EC_RBRACK),
                            CMLocalized(@"KeyCaret"),        CMIntAsNumber(EC_CIRCFLX),
                            CMLocalized(@"KeySemicolon"),    CMIntAsNumber(EC_SEMICOL),
                            CMLocalized(@"KeyColon"),        CMIntAsNumber(EC_COLON),
                            CMLocalized(@"KeyComma"),        CMIntAsNumber(EC_COMMA),
                            CMLocalized(@"KeyPeriod"),       CMIntAsNumber(EC_PERIOD),
                            CMLocalized(@"KeySlash"),        CMIntAsNumber(EC_DIV),
                            CMLocalized(@"KeyUnderscore"),   CMIntAsNumber(EC_UNDSCRE),
                            
                            nil] retain];
    }
    
    return virtualKeyNames;
}

- (NSString *)virtualKeyName
{
    return [CMKeyMapping.virtualKeyNames objectForKey:CMIntAsNumber(self.virtualCode)];
}

- (NSString *)physicalKeyName
{
    if ((self.keyModifier & CMLeftShiftKeyMask) == CMLeftShiftKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacLeftModifier_f"), kShiftUnicode];
    if ((self.keyModifier & CMRightShiftKeyMask) == CMRightShiftKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacRightModifier_f"), kShiftUnicode];
    if ((self.keyModifier & CMLeftAltKeyMask) == CMLeftAltKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacLeftModifier_f"), kOptionUnicode];
    if ((self.keyModifier & CMRightAltKeyMask) == CMRightAltKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacRightModifier_f"), kOptionUnicode];
    if ((self.keyModifier & CMLeftCommandKeyMask) == CMLeftCommandKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacLeftModifier_f"), kCommandUnicode];
    if ((self.keyModifier & CMRightCommandKeyMask) == CMRightCommandKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacRightModifier_f"), kCommandUnicode];
    if ((self.keyModifier & CMLeftControlKeyMask) == CMLeftControlKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacLeftModifier_f"), kControlUnicode];
    if ((self.keyModifier & CMRightControlKeyMask) == CMRightControlKeyMask)
        return [NSString stringWithFormat:CMLocalized(@"KeyMacRightModifier_f"), kControlUnicode];
    if ((self.keyModifier & NSAlphaShiftKeyMask) == NSAlphaShiftKeyMask)
        return CMLocalized(@"KeyCapsLock");
    
    if (self.keyCode == CMKeyNoCode)
        return nil;
    
    NSString *predefinedName = [[CMKeyMapping physicalKeyNames] objectForKey:[NSNumber numberWithInteger:self.keyCode]];
    if (predefinedName)
        return predefinedName;
    
    TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    if (!tisSource)
        return nil;
    
    CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    CFRelease(tisSource);
    
    // For non-Unicode layouts (e.g. Chinese, Japanese, Korean) get ASCII layout
    if (!layoutData)
    {
        tisSource = TISCopyCurrentASCIICapableKeyboardInputSource();
        layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
        CFRelease(tisSource);
    }
    
    if (!layoutData)
        return nil;
    
    const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(layoutData);
    
    UniCharCount length = 4;
    UniCharCount realLength;
    UniChar chars[4];
    UInt32 keysDown = 0;
    
    OSStatus err = UCKeyTranslate(keyLayout, self.keyCode, kUCKeyActionDisplay, 0,
                                  LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit,
                                  &keysDown, length, &realLength, chars);
    
    if (err != noErr)
        return nil;
    
    NSString *keyLabel = [[NSString stringWithCharacters:chars length:1] uppercaseString];
    
    BOOL isNumpadKey = [CMKeyMapping.numpadKeyCodes containsObject:[NSNumber numberWithInteger:self.keyCode]];
    if (isNumpadKey)
        return [NSString stringWithFormat:CMLocalized(@"KeyNumpad_f"), keyLabel];
    
    return keyLabel;
}

- (BOOL)isMapped
{
    return !(self.keyCode == CMKeyNoCode && self.keyModifier == CMKeyNoModifiers);
}

- (BOOL)matchesEventCode:(NSEvent *)event;
{
    if (self.keyModifier != CMKeyNoModifiers)
        return NO; // Mapped to a modifier
    
    return self.keyCode != CMKeyNoCode && event.keyCode == self.keyCode;
}

- (NSInteger)virtualKeyCategory
{
    switch (self.virtualCode)
    {
        case EC_LSHIFT:
        case EC_RSHIFT:
        case EC_CTRL:
        case EC_GRAPH:
        case EC_CODE:
        case EC_TORIKE:
        case EC_JIKKOU:
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

@end

#pragma mark - CMKeyLayout

@interface CMKeyLayout ()

@end

@implementation CMKeyLayout

- (id)init
{
    if ((self = [super init]))
    {
        keys = [[NSMutableArray alloc] init];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_LSHIFT]];
        [keys addObject:[CMKeyMapping virtualKey:EC_RSHIFT]];
        [keys addObject:[CMKeyMapping virtualKey:EC_CTRL]];
        [keys addObject:[CMKeyMapping virtualKey:EC_GRAPH]];
        [keys addObject:[CMKeyMapping virtualKey:EC_CODE]];
        [keys addObject:[CMKeyMapping virtualKey:EC_TORIKE]];
        [keys addObject:[CMKeyMapping virtualKey:EC_JIKKOU]];
        [keys addObject:[CMKeyMapping virtualKey:EC_CAPS]];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_LEFT]];
        [keys addObject:[CMKeyMapping virtualKey:EC_UP]];
        [keys addObject:[CMKeyMapping virtualKey:EC_RIGHT]];
        [keys addObject:[CMKeyMapping virtualKey:EC_DOWN]];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_F1]];
        [keys addObject:[CMKeyMapping virtualKey:EC_F2]];
        [keys addObject:[CMKeyMapping virtualKey:EC_F3]];
        [keys addObject:[CMKeyMapping virtualKey:EC_F4]];
        [keys addObject:[CMKeyMapping virtualKey:EC_F5]];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_A]];
        [keys addObject:[CMKeyMapping virtualKey:EC_B]];
        [keys addObject:[CMKeyMapping virtualKey:EC_C]];
        [keys addObject:[CMKeyMapping virtualKey:EC_D]];
        [keys addObject:[CMKeyMapping virtualKey:EC_E]];
        [keys addObject:[CMKeyMapping virtualKey:EC_F]];
        [keys addObject:[CMKeyMapping virtualKey:EC_G]];
        [keys addObject:[CMKeyMapping virtualKey:EC_H]];
        [keys addObject:[CMKeyMapping virtualKey:EC_I]];
        [keys addObject:[CMKeyMapping virtualKey:EC_J]];
        [keys addObject:[CMKeyMapping virtualKey:EC_K]];
        [keys addObject:[CMKeyMapping virtualKey:EC_L]];
        [keys addObject:[CMKeyMapping virtualKey:EC_M]];
        [keys addObject:[CMKeyMapping virtualKey:EC_N]];
        [keys addObject:[CMKeyMapping virtualKey:EC_O]];
        [keys addObject:[CMKeyMapping virtualKey:EC_P]];
        [keys addObject:[CMKeyMapping virtualKey:EC_Q]];
        [keys addObject:[CMKeyMapping virtualKey:EC_R]];
        [keys addObject:[CMKeyMapping virtualKey:EC_S]];
        [keys addObject:[CMKeyMapping virtualKey:EC_T]];
        [keys addObject:[CMKeyMapping virtualKey:EC_U]];
        [keys addObject:[CMKeyMapping virtualKey:EC_V]];
        [keys addObject:[CMKeyMapping virtualKey:EC_W]];
        [keys addObject:[CMKeyMapping virtualKey:EC_X]];
        [keys addObject:[CMKeyMapping virtualKey:EC_Y]];
        [keys addObject:[CMKeyMapping virtualKey:EC_Z]];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_0]];
        [keys addObject:[CMKeyMapping virtualKey:EC_1]];
        [keys addObject:[CMKeyMapping virtualKey:EC_2]];
        [keys addObject:[CMKeyMapping virtualKey:EC_3]];
        [keys addObject:[CMKeyMapping virtualKey:EC_4]];
        [keys addObject:[CMKeyMapping virtualKey:EC_5]];
        [keys addObject:[CMKeyMapping virtualKey:EC_6]];
        [keys addObject:[CMKeyMapping virtualKey:EC_7]];
        [keys addObject:[CMKeyMapping virtualKey:EC_8]];
        [keys addObject:[CMKeyMapping virtualKey:EC_9]];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_NUMMUL]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUMADD]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUMDIV]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUMSUB]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUMPER]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUMCOM]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM0]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM1]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM2]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM3]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM4]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM5]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM6]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM7]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM8]];
        [keys addObject:[CMKeyMapping virtualKey:EC_NUM9]];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_ESC]];
        [keys addObject:[CMKeyMapping virtualKey:EC_TAB]];
        [keys addObject:[CMKeyMapping virtualKey:EC_STOP]];
        [keys addObject:[CMKeyMapping virtualKey:EC_CLS]];
        [keys addObject:[CMKeyMapping virtualKey:EC_SELECT]];
        [keys addObject:[CMKeyMapping virtualKey:EC_INS]];
        [keys addObject:[CMKeyMapping virtualKey:EC_DEL]];
        [keys addObject:[CMKeyMapping virtualKey:EC_BKSPACE]];
        [keys addObject:[CMKeyMapping virtualKey:EC_RETURN]];
        [keys addObject:[CMKeyMapping virtualKey:EC_SPACE]];
        [keys addObject:[CMKeyMapping virtualKey:EC_PRINT]];
        [keys addObject:[CMKeyMapping virtualKey:EC_PAUSE]];
        
        [keys addObject:[CMKeyMapping virtualKey:EC_NEG]];
        [keys addObject:[CMKeyMapping virtualKey:EC_BKSLASH]];
        [keys addObject:[CMKeyMapping virtualKey:EC_AT]];
        [keys addObject:[CMKeyMapping virtualKey:EC_LBRACK]];
        [keys addObject:[CMKeyMapping virtualKey:EC_RBRACK]];
        [keys addObject:[CMKeyMapping virtualKey:EC_CIRCFLX]];
        [keys addObject:[CMKeyMapping virtualKey:EC_SEMICOL]];
        [keys addObject:[CMKeyMapping virtualKey:EC_COLON]];
        [keys addObject:[CMKeyMapping virtualKey:EC_COMMA]];
        [keys addObject:[CMKeyMapping virtualKey:EC_PERIOD]];
        [keys addObject:[CMKeyMapping virtualKey:EC_DIV]];
        [keys addObject:[CMKeyMapping virtualKey:EC_UNDSCRE]];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [self init]))
    {
        NSArray *decodedKeys = [decoder decodeObjectForKey:@"keys"];
        [decodedKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            CMKeyMapping *key = obj;
            [self assignVirtualKey:key.virtualCode fromMapping:key];
        }];
    }
    
    return self;
}

- (void)dealloc
{
    [keys release];
    
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:keys forKey:@"keys"];
}

- (void)loadLayout:(CMKeyLayout *)layout
{
    for (int i = layout->keys.count - 1; i >= 0; i--)
    {
        CMKeyMapping *source = [layout->keys objectAtIndex:i];
        CMKeyMapping *destination = [keys objectAtIndex:i];
        
        destination.keyCode = source.keyCode;
        destination.keyModifier = source.keyModifier;
    }
}

- (void)assignVirtualKey:(NSUInteger)virtualKey
             fromMapping:(CMKeyMapping*)fromMapping
{
    CMKeyMapping *toMapping = [self findMappingOfVirtualKey:virtualKey];
    
    toMapping.keyCode = fromMapping.keyCode;
    toMapping.keyModifier = fromMapping.keyModifier;
}

- (void)assignVirtualKey:(NSUInteger)virtualKey
              toModifier:(NSUInteger)keyModifier
{
    [self findMappingOfVirtualKey:virtualKey].keyModifier = keyModifier;
}

- (void)assignVirtualKey:(NSUInteger)virtualKey
                  toCode:(NSInteger)keyCode
{
    [self findMappingOfVirtualKey:virtualKey].keyCode = keyCode;
}

- (void)unassignAllMatchingPhysicalCode:(NSInteger)physicalCode
{
    if (physicalCode == CMKeyNoCode)
        return;
    
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMKeyMapping *km = obj;
         if (km.keyCode == physicalCode)
         {
             // Unassign existing assignment
             km.keyCode = CMKeyNoCode;
             km.keyModifier = CMKeyNoModifiers;
         }
     }];
}

- (void)unassignAllMatchingPhysicalModifier:(NSUInteger)physicalModifier
{
    if (physicalModifier == CMKeyNoModifiers)
        return;
    
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMKeyMapping *km = obj;
         if (km.keyModifier == physicalModifier)
         {
             // Unassign existing assignment
             km.keyCode = CMKeyNoCode;
             km.keyModifier = CMKeyNoModifiers;
         }
     }];
}

- (CMKeyMapping *)mappingAtIndex:(NSInteger)index
{
    return [keys objectAtIndex:index];
}

- (CMKeyMapping *)findMappingOfPhysicalModifier:(NSUInteger)physicalModifier
{
    __block CMKeyMapping *foundMap = nil;
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMKeyMapping *map = obj;
         if (map.keyModifier == physicalModifier)
         {
             foundMap = map;
             *stop = YES;
         }
     }];
    
    return foundMap;
}

- (CMKeyMapping *)findMappingOfVirtualKey:(NSUInteger)virtualKey
{
    __block CMKeyMapping *foundMap = nil;
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMKeyMapping *map = obj;
         if (map.virtualCode == virtualKey)
         {
             foundMap = map;
             *stop = YES;
         }
     }];
    
    return foundMap;
}

- (CMKeyMapping *)findMappingOfEvent:(NSEvent *)event
{
    __block CMKeyMapping *foundMap = nil;
    
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMKeyMapping *key = obj;
         if ([key matchesEventCode:event])
         {
             foundMap = key;
             *stop = YES;
         }
     }];
    
    return foundMap;
}

+ (CMKeyLayout *)defaultLayout
{
    CMKeyLayout *defaultLayout = [[CMKeyLayout alloc] init];
    
    defaultLayout = [[CMKeyLayout alloc] init];
    [defaultLayout assignVirtualKey:EC_LSHIFT toModifier:CMLeftShiftKeyMask];
    [defaultLayout assignVirtualKey:EC_RSHIFT toModifier:CMRightShiftKeyMask];
    [defaultLayout assignVirtualKey:EC_CTRL   toModifier:CMLeftControlKeyMask];
    [defaultLayout assignVirtualKey:EC_GRAPH  toModifier:CMLeftAltKeyMask];
    [defaultLayout assignVirtualKey:EC_CODE   toModifier:CMRightAltKeyMask];
    //[defaultLayout assignVirtualKey:EC_TORIKE toModifier:CMLeftCommandKeyMask];
    //[defaultLayout assignVirtualKey:EC_JIKKOU toModifier:CMRightCommandKeyMask];
    [defaultLayout assignVirtualKey:EC_CAPS   toModifier:CMCapsLockKeyMask];
    
    [defaultLayout assignVirtualKey:EC_LEFT  toCode:CMKeyLeft];
    [defaultLayout assignVirtualKey:EC_UP    toCode:CMKeyUp];
    [defaultLayout assignVirtualKey:EC_RIGHT toCode:CMKeyRight];
    [defaultLayout assignVirtualKey:EC_DOWN  toCode:CMKeyDown];
    [defaultLayout assignVirtualKey:EC_F1 toCode:CMKeyF1];
    [defaultLayout assignVirtualKey:EC_F2 toCode:CMKeyF2];
    [defaultLayout assignVirtualKey:EC_F3 toCode:CMKeyF3];
    [defaultLayout assignVirtualKey:EC_F4 toCode:CMKeyF4];
    [defaultLayout assignVirtualKey:EC_F5 toCode:CMKeyF5];
    [defaultLayout assignVirtualKey:EC_A toCode:CMKeyA];
    [defaultLayout assignVirtualKey:EC_B toCode:CMKeyB];
    [defaultLayout assignVirtualKey:EC_C toCode:CMKeyC];
    [defaultLayout assignVirtualKey:EC_D toCode:CMKeyD];
    [defaultLayout assignVirtualKey:EC_E toCode:CMKeyE];
    [defaultLayout assignVirtualKey:EC_F toCode:CMKeyF];
    [defaultLayout assignVirtualKey:EC_G toCode:CMKeyG];
    [defaultLayout assignVirtualKey:EC_H toCode:CMKeyH];
    [defaultLayout assignVirtualKey:EC_I toCode:CMKeyI];
    [defaultLayout assignVirtualKey:EC_J toCode:CMKeyJ];
    [defaultLayout assignVirtualKey:EC_K toCode:CMKeyK];
    [defaultLayout assignVirtualKey:EC_L toCode:CMKeyL];
    [defaultLayout assignVirtualKey:EC_M toCode:CMKeyM];
    [defaultLayout assignVirtualKey:EC_N toCode:CMKeyN];
    [defaultLayout assignVirtualKey:EC_O toCode:CMKeyO];
    [defaultLayout assignVirtualKey:EC_P toCode:CMKeyP];
    [defaultLayout assignVirtualKey:EC_Q toCode:CMKeyQ];
    [defaultLayout assignVirtualKey:EC_R toCode:CMKeyR];
    [defaultLayout assignVirtualKey:EC_S toCode:CMKeyS];
    [defaultLayout assignVirtualKey:EC_T toCode:CMKeyT];
    [defaultLayout assignVirtualKey:EC_U toCode:CMKeyU];
    [defaultLayout assignVirtualKey:EC_V toCode:CMKeyV];
    [defaultLayout assignVirtualKey:EC_W toCode:CMKeyW];
    [defaultLayout assignVirtualKey:EC_X toCode:CMKeyX];
    [defaultLayout assignVirtualKey:EC_Y toCode:CMKeyY];
    [defaultLayout assignVirtualKey:EC_Z toCode:CMKeyZ];
    [defaultLayout assignVirtualKey:EC_0 toCode:CMKey0];
    [defaultLayout assignVirtualKey:EC_1 toCode:CMKey1];
    [defaultLayout assignVirtualKey:EC_2 toCode:CMKey2];
    [defaultLayout assignVirtualKey:EC_3 toCode:CMKey3];
    [defaultLayout assignVirtualKey:EC_4 toCode:CMKey4];
    [defaultLayout assignVirtualKey:EC_5 toCode:CMKey5];
    [defaultLayout assignVirtualKey:EC_6 toCode:CMKey6];
    [defaultLayout assignVirtualKey:EC_7 toCode:CMKey7];
    [defaultLayout assignVirtualKey:EC_8 toCode:CMKey8];
    [defaultLayout assignVirtualKey:EC_9 toCode:CMKey9];
    [defaultLayout assignVirtualKey:EC_NUMMUL toCode:CMKeyNumpadAsterisk];
    [defaultLayout assignVirtualKey:EC_NUMADD toCode:CMKeyNumpadPlus];
    [defaultLayout assignVirtualKey:EC_NUMDIV toCode:CMKeyNumpadSlash];
    [defaultLayout assignVirtualKey:EC_NUMSUB toCode:CMKeyNumpadMinus];
    [defaultLayout assignVirtualKey:EC_NUMPER toCode:CMKeyNumpadDecimal];
    [defaultLayout assignVirtualKey:EC_NUMCOM toCode:CMKeyPageDown];
    [defaultLayout assignVirtualKey:EC_NUM0 toCode:CMKeyNumpad0];
    [defaultLayout assignVirtualKey:EC_NUM1 toCode:CMKeyNumpad1];
    [defaultLayout assignVirtualKey:EC_NUM2 toCode:CMKeyNumpad2];
    [defaultLayout assignVirtualKey:EC_NUM3 toCode:CMKeyNumpad3];
    [defaultLayout assignVirtualKey:EC_NUM4 toCode:CMKeyNumpad4];
    [defaultLayout assignVirtualKey:EC_NUM5 toCode:CMKeyNumpad5];
    [defaultLayout assignVirtualKey:EC_NUM6 toCode:CMKeyNumpad6];
    [defaultLayout assignVirtualKey:EC_NUM7 toCode:CMKeyNumpad7];
    [defaultLayout assignVirtualKey:EC_NUM8 toCode:CMKeyNumpad8];
    [defaultLayout assignVirtualKey:EC_NUM9 toCode:CMKeyNumpad9];
    [defaultLayout assignVirtualKey:EC_ESC  toCode:CMKeyEscape];
    [defaultLayout assignVirtualKey:EC_TAB  toCode:CMKeyTab];
    [defaultLayout assignVirtualKey:EC_STOP    toCode:CMKeyPageUp];
    [defaultLayout assignVirtualKey:EC_CLS     toCode:CMKeyHome];
    [defaultLayout assignVirtualKey:EC_SELECT  toCode:CMKeyEnd];
    //[defaultLayout assignVirtualKey:EC_INS     toCode:CMKeyNoCode];
    [defaultLayout assignVirtualKey:EC_DEL     toCode:CMKeyDelete];
    [defaultLayout assignVirtualKey:EC_BKSPACE toCode:CMKeyBackspace];
    [defaultLayout assignVirtualKey:EC_RETURN  toCode:CMKeyEnter];
    [defaultLayout assignVirtualKey:EC_SPACE   toCode:CMKeySpacebar];
    [defaultLayout assignVirtualKey:EC_PRINT   toCode:CMKeyPrintScreen];
    [defaultLayout assignVirtualKey:EC_PAUSE   toCode:CMKeyNumpadEnter];
    [defaultLayout assignVirtualKey:EC_NEG     toCode:CMKeyMinus];
    [defaultLayout assignVirtualKey:EC_BKSLASH toCode:CMKeyBackslash];
    [defaultLayout assignVirtualKey:EC_AT      toCode:CMKeyLeftBracket];
    [defaultLayout assignVirtualKey:EC_LBRACK  toCode:CMKeyRightBracket];
    [defaultLayout assignVirtualKey:EC_RBRACK  toCode:CMKeyBacktick];
    [defaultLayout assignVirtualKey:EC_CIRCFLX toCode:CMKeyEquals];
    [defaultLayout assignVirtualKey:EC_SEMICOL toCode:CMKeySemicolon];
    [defaultLayout assignVirtualKey:EC_COLON   toCode:CMKeyQuote];
    [defaultLayout assignVirtualKey:EC_COMMA   toCode:CMKeyComma];
    [defaultLayout assignVirtualKey:EC_PERIOD  toCode:CMKeyPeriod];
    [defaultLayout assignVirtualKey:EC_DIV     toCode:CMKeySlash];
    [defaultLayout assignVirtualKey:EC_UNDSCRE toModifier:CMRightControlKeyMask];
    
    return [defaultLayout autorelease];
}   

- (NSArray *)keyMaps
{
    return keys;
}

@end

