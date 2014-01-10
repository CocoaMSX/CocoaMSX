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
#import "CMInputDeviceLayout.h"

@implementation CMInputDeviceLayout

#pragma mark - init & dealloc

- (id)init
{
    if ((self = [super init]))
    {
        inputs = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [inputs release];
    
    [super dealloc];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [self init]))
    {
        [inputs addEntriesFromDictionary:[decoder decodeObjectForKey:@"inputs"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:inputs forKey:@"inputs"];
}

#pragma mark - CMInputDeviceLayout

- (void)loadLayout:(CMInputDeviceLayout *)layout
{
    [inputs removeAllObjects];
    
    [layout->inputs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        CMInputMethod *copy = [((CMInputMethod *)obj) copy];
        [inputs setObject:copy forKey:key];
        
        [copy release];
    }];
}

- (void)assignInputMethod:(CMInputMethod *)inputMethod
            toVirtualCode:(NSUInteger)virtualCode
{
    [inputs setObject:(inputMethod) ? inputMethod : [NSNull null]
               forKey:[NSNumber numberWithUnsignedInteger:virtualCode]];
}

- (CMInputMethod *)inputMethodForVirtualCode:(NSUInteger)virtualCode
{
    id inputMethod = [inputs objectForKey:[NSNumber numberWithUnsignedInteger:virtualCode]];
    
    if (inputMethod == [NSNull null])
        return nil;
    
    return inputMethod;
}

- (NSInteger)virtualCodeForInputMethod:(CMInputMethod *)inputMethod
{
    // TODO: Add a reverse-lookup dictionary
    
    __block NSInteger foundCode = CMUnknownVirtualCode;
    
    [inputs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        if (obj == [NSNull null])
            return;
        
        NSUInteger virtualCode = [((NSNumber *)key) unsignedIntegerValue];
        CMInputMethod *im = (CMInputMethod *)obj;
        
        if ([im isEqualToInputMethod:inputMethod])
        {
            foundCode = virtualCode;
            *stop = YES;
        }
    }];
    
    return foundCode;
}

- (void)enumerateMappingsUsingBlock:(CMMappingEnumeratorBlock)block
{
    [inputs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        NSUInteger virtualCode = [((NSNumber *)key) unsignedIntegerValue];
        CMInputMethod *im = nil;
        
        if (obj != [NSNull null])
            im = (CMInputMethod *)obj;
        
        block(virtualCode, im, stop);
    }];
}

@end
