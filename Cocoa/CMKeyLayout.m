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
#import "CMKeyLayout.h"

#include "InputEvent.h"

#define CMIntAsNumber(x) [NSNumber numberWithInteger:x]
#define CMLoc(x)         NSLocalizedString(x, nil)

#pragma mark - CMKeyMapping

@implementation CMKeyMapping

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder]))
    {
        self.keyCode = [decoder decodeIntegerForKey:@"keyCode"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeInteger:self.keyCode forKey:@"keyCode"];
}

- (id)copyWithZone:(NSZone *)zone
{
    CMKeyMapping *copy = [[super copyWithZone:zone] init];
    
    copy.keyCode = self.keyCode;
    
    return copy;
}

+ (CMKeyMapping *)keyMappingWithVirtualCode:(NSUInteger)virtualCode
{
    CMKeyMapping *key = [[CMKeyMapping alloc] initWithVirtualCode:virtualCode];
    
    key.keyCode = CMKeyNoCode;
    
    return [key autorelease];
}

- (BOOL)isMapped
{
    return self.keyCode != CMKeyNoCode;
}

- (BOOL)matchesKeyCode:(NSInteger)keyCode
{
    return self.keyCode != CMKeyNoCode && keyCode == self.keyCode;
}

@end

#pragma mark - CMKeyLayout

@implementation CMKeyLayout

- (id)init
{
    if ((self = [super init]))
    {
        keys = [[NSMutableArray alloc] init];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_LSHIFT]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_RSHIFT]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_CTRL]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_GRAPH]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_CODE]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_TORIKE]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JIKKOU]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_CAPS]];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_LEFT]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_UP]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_RIGHT]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_DOWN]];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_F1]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_F2]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_F3]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_F4]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_F5]];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_A]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_B]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_C]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_D]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_E]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_F]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_G]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_H]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_I]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_J]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_K]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_L]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_M]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_N]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_O]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_P]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_Q]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_R]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_S]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_T]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_U]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_V]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_W]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_X]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_Y]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_Z]];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_0]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_1]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_2]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_3]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_4]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_5]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_6]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_7]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_8]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_9]];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUMMUL]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUMADD]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUMDIV]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUMSUB]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUMPER]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUMCOM]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM0]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM1]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM2]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM3]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM4]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM5]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM6]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM7]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM8]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NUM9]];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_ESC]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_TAB]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_STOP]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_CLS]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_SELECT]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_INS]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_DEL]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_BKSPACE]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_RETURN]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_SPACE]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_PRINT]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_PAUSE]];
        
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_NEG]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_BKSLASH]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_AT]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_LBRACK]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_RBRACK]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_CIRCFLX]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_SEMICOL]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_COLON]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_COMMA]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_PERIOD]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_DIV]];
        [keys addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_UNDSCRE]];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        keys = [[NSMutableArray alloc] initWithArray:[decoder decodeObjectForKey:@"keys"]];
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
        CMKeyMapping *keyCopy = [[layout->keys objectAtIndex:i] copy];
        
        [keys setObject:keyCopy atIndexedSubscript:i];
        [keyCopy release];
    }
}

- (void)assignVirtualKey:(NSUInteger)virtualKey
             fromMapping:(CMKeyMapping*)fromMapping
{
    CMKeyMapping *toMapping = [self findMappingOfVirtualKey:virtualKey];
    
    toMapping.keyCode = fromMapping.keyCode;
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
         }
     }];
}

- (CMKeyMapping *)mappingAtIndex:(NSInteger)index
{
    return [keys objectAtIndex:index];
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

- (CMKeyMapping *)findMappingOfPhysicalKeyCode:(NSInteger)keyCode
{
    __block CMKeyMapping *foundMap = nil;
    
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMKeyMapping *key = obj;
         if ([key matchesKeyCode:keyCode])
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
    
    [defaultLayout assignVirtualKey:EC_LSHIFT toCode:CMKeyLeftShift];
    [defaultLayout assignVirtualKey:EC_RSHIFT toCode:CMKeyRightShift];
    [defaultLayout assignVirtualKey:EC_CTRL   toCode:CMKeyLeftControl];
    [defaultLayout assignVirtualKey:EC_GRAPH  toCode:CMKeyLeftAlt];
    [defaultLayout assignVirtualKey:EC_CODE   toCode:CMKeyRightAlt];
    //[defaultLayout assignVirtualKey:EC_TORIKE toModifier:CMLeftCommandKeyMask];
    //[defaultLayout assignVirtualKey:EC_JIKKOU toModifier:CMRightCommandKeyMask];
    [defaultLayout assignVirtualKey:EC_CAPS   toCode:CMKeyCapsLock];
    
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
    [defaultLayout assignVirtualKey:EC_UNDSCRE toCode:CMKeyRightControl];
    
    return [defaultLayout autorelease];
}   

- (NSArray *)keyMaps
{
    return keys;
}

@end

