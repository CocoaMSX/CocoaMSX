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

#pragma mark - CMMSXKeyCombination

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

#pragma mark - CMMSXKeyboard

@implementation CMMSXKeyboard

@synthesize name = _name;
@synthesize label = _label;

static NSArray *layoutNames;
static NSMutableDictionary *machineToLayoutMap;
static NSMutableDictionary *layoutToKeyboardMap;
static NSMutableDictionary *virtualCodeToCategoryMap;

+ (void)initialize
{
    machineToLayoutMap = [[NSMutableDictionary alloc] init];
    virtualCodeToCategoryMap = [[NSMutableDictionary alloc] init];
    layoutToKeyboardMap = [[NSMutableDictionary alloc] init];
    
    // Load the master layout map
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"MSXKeyLayouts"
                                                             ofType:@"plist"
                                                        inDirectory:@"Data"];
    NSDictionary *layoutDictionary = [NSDictionary dictionaryWithContentsOfFile:resourcePath];
    
    // Get a list of all layout names
    layoutNames = [[NSArray alloc] initWithArray:[layoutDictionary allKeys]];
    
    // Parse layout-specific information
    NSMutableDictionary *layoutPlists = [NSMutableDictionary dictionary];
    NSMutableDictionary *layoutLabels = [NSMutableDictionary dictionary];
    
    [layoutDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        NSString *layoutName = key;
        NSDictionary *layoutData = obj;
        
        // Build a dictionary of each layout's property list
        [layoutPlists setObject:[layoutData objectForKey:@"layoutPlist"]
                         forKey:layoutName];
        
        // Localization labels...
        [layoutLabels setObject:CMLoc([layoutData objectForKey:@"name"], @"")
                         forKey:layoutName];
        
        // Build a dictionary of each machine's layout
        NSArray *machines = [layoutData objectForKey:@"machines"];
        [machines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            [machineToLayoutMap setObject:layoutName forKey:obj];
        }];
    }];
    
    // Initialize individual layouts
    [layoutNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        // Load dictionary containing layout data
        NSString *layoutResourcePath = [[NSBundle mainBundle] pathForResource:[layoutPlists objectForKey:obj]
                                                                       ofType:@"plist"
                                                                  inDirectory:@"Data/Layouts"];
        NSDictionary *layoutDictionary = [NSDictionary dictionaryWithContentsOfFile:layoutResourcePath];
        
        // For each layout, initialize MSXKeyboard object with contents of dictionary
        CMMSXKeyboard *keyboard = [[[CMMSXKeyboard alloc] initWithDictionary:layoutDictionary] autorelease];
        [keyboard setName:obj];
        [keyboard setLabel:[layoutLabels objectForKey:obj]];
        
        [layoutToKeyboardMap setObject:keyboard
                                forKey:obj];
    }];
    
    // Initialize key category map
    resourcePath = [[NSBundle mainBundle] pathForResource:@"MSXKeyCategories"
                                                   ofType:@"plist"
                                              inDirectory:@"Data"];
    NSDictionary *keyCategoryDictionary = [[NSDictionary alloc] initWithContentsOfFile:resourcePath];
    [keyCategoryDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        NSString *categoryName = key;
        [obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            [virtualCodeToCategoryMap setObject:categoryName forKey:@([obj integerValue])];
        }];
    }];
}

- (id)init
{
    if ((self = [super init]))
    {
        _label = nil;
        _name = nil;
        
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
    [_name release];
    [_label release];
    
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

+ (NSString *)defaultLayoutName
{
    return @"european";
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

+ (NSString *)categoryNameForVirtualCode:(NSInteger)keyCode
{
    return [virtualCodeToCategoryMap objectForKey:@(keyCode)];
}

+ (NSString *)categoryLabelForVirtualCode:(NSInteger)keyCode
{
    NSString *categoryName = [virtualCodeToCategoryMap objectForKey:@(keyCode)];
    if (!categoryName)
        return nil;
    
    NSString *localizationId = [NSString stringWithFormat:@"KeyCategory%@", categoryName];
    return CMLoc(localizationId, @"");
}

+ (NSArray *)availableLayoutNames
{
    return layoutNames;
}

@end