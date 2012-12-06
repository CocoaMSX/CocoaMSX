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
#import "CMJoystickLayout.h"

#import "CMKeyLayout.h"

#include "InputEvent.h"

#define CMIntAsNumber(x) ([NSNumber numberWithInteger:x])
#define CMLoc(x)         (NSLocalizedString(x, nil))

#pragma mark - CMJoystickLayout

@interface CMJoystickLayout ()

- (NSInteger)findIndexOfVirtualCode:(NSUInteger)virtualCode;

@end

@implementation CMJoystickLayout

- (id)init
{
    if ((self = [super init]))
    {
        inputs = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initLayoutForJoystickOnPort:(NSInteger)port
{
    if ((self = [self init]))
    {
        if (port == 1)
        {
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY2_UP]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY2_DOWN]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY2_LEFT]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY2_RIGHT]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY2_BUTTON1]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY2_BUTTON2]];
        }
        else
        {
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY1_UP]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY1_DOWN]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY1_LEFT]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY1_RIGHT]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY1_BUTTON1]];
            [inputs addObject:[CMKeyMapping keyMappingWithVirtualCode:EC_JOY1_BUTTON2]];
        }
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [self init]))
    {
        [inputs addObjectsFromArray:[decoder decodeObjectForKey:@"inputs"]];
    }
    
    return self;
}

- (void)dealloc
{
    [inputs release];
    
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:inputs forKey:@"inputs"];
}

- (void)loadLayout:(CMJoystickLayout *)layout
{
    for (int i = layout->inputs.count - 1; i >= 0; i--)
    {
        CMInputMapping *inputCopy = [[layout->inputs objectAtIndex:i] copy];
        
        [inputs setObject:inputCopy atIndexedSubscript:i];
        [inputCopy release];
    }
}

- (BOOL)assignVirtualCode:(NSUInteger)virtualCode
                toKeyCode:(NSInteger)keyCode
{
    NSInteger index = [self findIndexOfVirtualCode:virtualCode];
    if (index == NSNotFound)
        return NO;
    
    CMKeyMapping *km = [CMKeyMapping keyMappingWithVirtualCode:virtualCode];
    km.keyCode = keyCode;
    
    [inputs setObject:km atIndexedSubscript:index];
    
    return YES;
}

- (CMInputMapping *)findMappingOfVirtualCode:(NSUInteger)virtualCode
{
    __block CMInputMapping *foundMap = nil;
    [inputs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMInputMapping *map = obj;
         if (map.virtualCode == virtualCode)
         {
             foundMap = map;
             *stop = YES;
         }
     }];
    
    return foundMap;
}

- (NSInteger)findIndexOfVirtualCode:(NSUInteger)virtualCode
{
    __block NSInteger index = NSNotFound;
    
    [inputs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMInputMapping *map = obj;
         if (map.virtualCode == virtualCode)
         {
             index = idx;
             *stop = YES;
         }
     }];
    
    return index;
}

+ (CMJoystickLayout *)defaultLayoutForJoystickOnPort:(NSInteger)port
{
    CMJoystickLayout *defaultLayout = [[CMJoystickLayout alloc] initLayoutForJoystickOnPort:port];
    
    if (port == 1)
    {
        [defaultLayout assignVirtualCode:EC_JOY2_UP      toKeyCode:CMKeyW];
        [defaultLayout assignVirtualCode:EC_JOY2_DOWN    toKeyCode:CMKeyS];
        [defaultLayout assignVirtualCode:EC_JOY2_LEFT    toKeyCode:CMKeyA];
        [defaultLayout assignVirtualCode:EC_JOY2_RIGHT   toKeyCode:CMKeyD];
        [defaultLayout assignVirtualCode:EC_JOY2_BUTTON1 toKeyCode:CMKeyLeftBracket];
        [defaultLayout assignVirtualCode:EC_JOY2_BUTTON2 toKeyCode:CMKeyRightBracket];
    }
    else
    {
        [defaultLayout assignVirtualCode:EC_JOY1_UP      toKeyCode:CMKeyUp];
        [defaultLayout assignVirtualCode:EC_JOY1_DOWN    toKeyCode:CMKeyDown];
        [defaultLayout assignVirtualCode:EC_JOY1_LEFT    toKeyCode:CMKeyLeft];
        [defaultLayout assignVirtualCode:EC_JOY1_RIGHT   toKeyCode:CMKeyRight];
        [defaultLayout assignVirtualCode:EC_JOY1_BUTTON1 toKeyCode:CMKeySpacebar];
        [defaultLayout assignVirtualCode:EC_JOY1_BUTTON2 toKeyCode:CMKeyLeftAlt];
    }
    
    return [defaultLayout autorelease];
}

- (NSArray *)inputMaps
{
    return inputs;
}

@end
