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
    NSString *_name;
    NSString *_label;
    
    NSMutableDictionary *virtualCodeToKeyInfoMap;
    NSMutableDictionary *characterToVirtualCodeMap;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *label;

+ (NSArray *)availableLayoutNames;
+ (NSString *)defaultLayoutName;
+ (NSString *)layoutNameOfMachineWithIdentifier:(NSString *)machineId;
+ (CMMSXKeyboard *)keyboardWithLayoutName:(NSString *)layoutName;

+ (NSString *)categoryNameForVirtualCode:(NSInteger)keyCode;
+ (NSString *)categoryLabelForVirtualCode:(NSInteger)keyCode;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)asDictionary;

- (NSString *)presentationLabelForVirtualCode:(NSInteger)keyCode
                                     keyState:(CMMSXKeyState)keyState;

- (BOOL)supportsVirtualCode:(NSInteger)keyCode
                   forState:(CMMSXKeyState)keyState;

- (CMMSXKeyCombination *)keyCombinationForCharacter:(NSString *)character;

@end

