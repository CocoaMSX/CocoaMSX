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
#import <Foundation/Foundation.h>

enum
{
    // State Flags
    CMMSXKeyStateDefault = 0,
    CMMSXKeyStateShift   = 1,
    CMMSXKeyStateGraph   = 2,
    CMMSXKeyStateControl = 4,
};

typedef NSUInteger CMMSXKeyState;

enum
{
    CMMSXKeyboardUnknown   = 0,
    CMMSXKeyboardArabic    = 1,
    CMMSXKeyboardBrazilian = 2,
    CMMSXKeyboardEstonian  = 3,
    CMMSXKeyboardEuropean  = 4,
    CMMSXKeyboardFrench    = 5,
    CMMSXKeyboardGerman    = 6,
    CMMSXKeyboardJapanese  = 7,
    CMMSXKeyboardKorean    = 8,
    CMMSXKeyboardRussian   = 9,
    CMMSXKeyboardSpanish   = 10,
    CMMSXKeyboardSwedish   = 11,
};

typedef NSUInteger CMMSXKeyboardLayout;

@interface CMMSXKeyCombination : NSObject
{
    NSInteger _virtualCode;
    CMMSXKeyState _stateFlags;
}

@property (nonatomic, assign) NSInteger virtualCode;
@property (nonatomic, assign) CMMSXKeyState stateFlags;

- (id)initWithVirtualCode:(NSInteger)virtualCode
               stateFlags:(CMMSXKeyState)stateFlags;
+ (CMMSXKeyCombination *)combinationWithVirtualCode:(NSInteger)virtualCode
                                         stateFlags:(CMMSXKeyState)stateFlags;

@end

@interface CMMSXKeyboard : NSObject
{
    NSMutableDictionary *virtualCodeToKeyInfoMap;
    NSMutableDictionary *characterToVirtualCodeMap;
}

+ (CMMSXKeyboardLayout)layoutOfMachineWithIdentifier:(NSString *)machineId;

- (NSString *)presentationLabelForVirtualCode:(NSInteger)keyCode
                                     keyState:(CMMSXKeyState)keyState;

- (BOOL)supportsVirtualCode:(NSInteger)keyCode
                   forState:(CMMSXKeyState)keyState;

- (CMMSXKeyCombination *)keyCombinationForCharacter:(NSString *)character;

+ (CMMSXKeyboard *)keyboardWithLayout:(CMMSXKeyboardLayout)layout;

@end

