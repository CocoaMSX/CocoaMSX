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
#import "CMMSXKeyboard.h"

#include "InputEvent.h"

#pragma mark - CMMSXKey

@interface CMMSXKey : NSObject
{
    NSInteger _virtualCode;
    NSString *_label;
    NSString *_defaultChar;
    NSString *_shiftChar;
}

- (id)initWithVirtualCode:(NSInteger)virtualCode
               dictionary:(NSDictionary *)dictionary;
- (NSDictionary *)asDictionary;

@property (nonatomic, assign) NSInteger virtualCode;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *defaultChar;
@property (nonatomic, retain) NSString *shiftChar;

- (NSString *)presentationLabelForState:(CMMSXKeyState)keyState;
- (NSString *)charForState:(CMMSXKeyState)keyState;
- (BOOL)availableForState:(CMMSXKeyState)keyState;

@end

@implementation CMMSXKey

@synthesize virtualCode = _virtualCode;
@synthesize label = _label;
@synthesize defaultChar = _defaultChar;
@synthesize shiftChar = _shiftChar;

- (id)initWithVirtualCode:(NSInteger)virtualCode
               dictionary:(NSDictionary *)dictionary
{
    if ((self = [self init]))
    {
        [self setVirtualCode:virtualCode];
        
        [self setLabel:[dictionary objectForKey:@"label"]];
        [self setDefaultChar:[dictionary objectForKey:@"default"]];
        [self setShiftChar:[dictionary objectForKey:@"shift"]];
    }
    
    return self;
}

- (void)dealloc
{
    [self setDefaultChar:nil];
    [self setShiftChar:nil];
    [self setLabel:nil];
    
    [super dealloc];
}

- (NSString *)presentationLabelForState:(CMMSXKeyState)keyState
{
    // Explicit labels take precedence
    if ([self label])
        return [self label];
    
    return [self charForState:keyState];
}

- (NSString *)charForState:(CMMSXKeyState)keyState
{
    if (keyState == CMMSXKeyStateDefault)
        return [self defaultChar];
    if (keyState == CMMSXKeyStateShift)
        return [self shiftChar];
    
    return nil;
}

- (BOOL)availableForState:(CMMSXKeyState)keyState
{
    // If a state char is explicitly defined, then it's available
    NSString *stateChar = [self charForState:keyState];
    if (stateChar)
        return YES;
    
    // Else, it's available if there are no explicitly defined states
    return ![self defaultChar] && ![self shiftChar];
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if ([self label]) [dict setObject:[self label] forKey:@"label"];
    if ([self defaultChar]) [dict setObject:[self defaultChar] forKey:@"default"];
    if ([self shiftChar]) [dict setObject:[self shiftChar] forKey:@"shift"];
    
    return dict;
}

@end

#pragma mark - CMKeyCombination

@implementation CMMSXKeyCombination

@synthesize virtualCode = _virtualCode;
@synthesize stateFlags = _stateFlags;

- (id)initWithVirtualCode:(NSInteger)virtualCode
               stateFlags:(CMMSXKeyState)stateFlags
{
    if ((self = [super init]))
    {
        _virtualCode = virtualCode;
        _stateFlags = stateFlags;
    }
    
    return self;
}

+ (CMMSXKeyCombination *)combinationWithVirtualCode:(NSInteger)virtualCode
                                         stateFlags:(CMMSXKeyState)stateFlags
{
    CMMSXKeyCombination *keyCombination = [[CMMSXKeyCombination alloc] initWithVirtualCode:virtualCode
                                                                                stateFlags:stateFlags];
    
    return [keyCombination autorelease];
}

@end

#pragma mark - CMKeyboardLayout

NSString *const CMMSXKeyboardArabic = @"arabic";
NSString *const CMMSXKeyboardBrazilian = @"brazilian";
NSString *const CMMSXKeyboardEstonian = @"estonian";
NSString *const CMMSXKeyboardEuropean = @"european";
NSString *const CMMSXKeyboardFrench = @"french";
NSString *const CMMSXKeyboardGerman = @"german";
NSString *const CMMSXKeyboardJapanese = @"japanese";
NSString *const CMMSXKeyboardKorean = @"korean";
NSString *const CMMSXKeyboardRussian = @"russian";
NSString *const CMMSXKeyboardSpanish = @"spanish";
NSString *const CMMSXKeyboardSwedish = @"swedish";

@implementation CMMSXKeyboard

static NSDictionary *machineToLayoutMap;
static NSMutableDictionary *layoutToKeyboardMap;

+ (void)initialize
{
    // Load the "machine->layout" map
    
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"MSXMachineLayouts"
                                                                   ofType:@"plist"
                                                              inDirectory:@"Data"];
    machineToLayoutMap = [[NSDictionary alloc] initWithContentsOfFile:bundleResourcePath];
    
    // Get a list of all layouts
    
    NSArray *layoutNames = [[machineToLayoutMap allValues] valueForKeyPath:@"@distinctUnionOfObjects.self"];
    
    // Initialize individual layouts
    
    layoutToKeyboardMap = [[NSMutableDictionary alloc] init];
    [layoutNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *layoutResourcePath = [[NSBundle mainBundle] pathForResource:obj
                                                                       ofType:@"plist"
                                                                  inDirectory:@"Data/Layouts"];
        NSDictionary *layoutDictionary = [NSDictionary dictionaryWithContentsOfFile:layoutResourcePath];
        
        CMMSXKeyboard *keyboard = [[[CMMSXKeyboard alloc] initWithDictionary:layoutDictionary] autorelease];
        [layoutToKeyboardMap setObject:keyboard
                                forKey:obj];
    }];
}

- (id)init
{
    if ((self = [super init]))
    {
        virtualCodeToKeyInfoMap = [[NSMutableDictionary alloc] init];
        characterToVirtualCodeMap = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [self init]))
    {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
        {
            NSNumber *virtualCode = @([key integerValue]);
            CMMSXKey *msxKey = [[[CMMSXKey alloc] initWithVirtualCode:[virtualCode integerValue]
                                                           dictionary:obj] autorelease];
            
            NSString *defaultChar = [msxKey charForState:CMMSXKeyStateDefault];
            NSString *shiftChar = [msxKey charForState:CMMSXKeyStateShift];
            
            [virtualCodeToKeyInfoMap setObject:msxKey forKey:virtualCode];
            
            if (defaultChar)
                [characterToVirtualCodeMap setObject:msxKey forKey:defaultChar];
            if (shiftChar)
                [characterToVirtualCodeMap setObject:msxKey forKey:shiftChar];
        }];
    }
    
    return self;
}

- (void)dealloc
{
    [virtualCodeToKeyInfoMap release];
    [characterToVirtualCodeMap release];
    
    [super dealloc];
}

- (NSDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [virtualCodeToKeyInfoMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        [dictionary setObject:[obj asDictionary]
                       forKey:[key stringValue]];
    }];
    
    return dictionary;
}

+ (NSString *)layoutNameOfMachineWithIdentifier:(NSString *)machineId
{
    return [machineToLayoutMap objectForKey:machineId];
}

- (NSString *)presentationLabelForVirtualCode:(NSInteger)keyCode
                                     keyState:(CMMSXKeyState)keyState
{
    CMMSXKey *msxKey = [virtualCodeToKeyInfoMap objectForKey:@(keyCode)];
    return [msxKey presentationLabelForState:keyState];
}

- (BOOL)supportsVirtualCode:(NSInteger)keyCode
                   forState:(CMMSXKeyState)keyState
{
    CMMSXKey *msxKey = [virtualCodeToKeyInfoMap objectForKey:@(keyCode)];
    if (!msxKey)
        return NO;
    
    return [msxKey availableForState:keyState];
}

- (CMMSXKeyCombination *)keyCombinationForCharacter:(NSString *)character
{
    CMMSXKey *msxKey = [characterToVirtualCodeMap objectForKey:character];
    
    if (msxKey)
    {
        if ([character isEqual:[msxKey charForState:CMMSXKeyStateDefault]])
            return [CMMSXKeyCombination combinationWithVirtualCode:[msxKey virtualCode]
                                                        stateFlags:CMMSXKeyStateDefault];
        if ([character isEqual:[msxKey charForState:CMMSXKeyStateShift]])
            return [CMMSXKeyCombination combinationWithVirtualCode:[msxKey virtualCode]
                                                        stateFlags:CMMSXKeyStateShift];
    }
    
    return nil;
}

- (NSInteger)virtualCodeForCharacter:(NSString *)character
{
    CMMSXKey *msxKey = [characterToVirtualCodeMap objectForKey:character];
    if (!msxKey)
        return EC_NONE;
    
    return [msxKey virtualCode];
}

+ (CMMSXKeyboard *)keyboardWithLayoutName:(NSString *)layoutName
{
    return [layoutToKeyboardMap objectForKey:layoutName];
}

@end