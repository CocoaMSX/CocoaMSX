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
#import "CMMachine.h"

#import "NSString+CMExtensions.h"

#define CMUnknown   0
#define CMMsx       1
#define CMMsx2      2
#define CMMsx2Plus  3
#define CMMsxTurboR 4

NSString *const CMMsxMachine       = @"MSX";
NSString *const CMMsx2Machine      = @"MSX 2";
NSString *const CMMsx2PMachine     = @"MSX 2+";
NSString *const CMMsxTurboRMachine = @"MSX Turbo R";

@interface CMMachine ()

+ (NSInteger)systemNamed:(NSString *)systemName;

@end

@implementation CMMachine

@synthesize path = _path;
@synthesize name = _name;
@synthesize machineId = _machineId;
@synthesize installed = _installed;
@synthesize system = _system;

- (id)init
{
    if ((self = [super init]))
    {
        _name = nil;
        _path = nil;
        _machineId = nil;
        _installed = NO;
        _system = CMUnknown;
    }
    
    return self;
}
- (id)initWithPath:(NSString *)path
{
    if ((self = [self init]))
    {
        NSString *name = path;
        NSString *machineId = path;
        NSString *systemName = nil;
        
        NSRange occurrence = [path rangeOfString:@" - "];
        if (occurrence.location != NSNotFound)
        {
            name = [path substringFromIndex:occurrence.location + occurrence.length];
            systemName = [path substringToIndex:occurrence.location];
        }
        
        _path = [path copy];
        _machineId = [machineId copy];
        _name = [name copy];
        _installed = NO;
        _system = [CMMachine systemNamed:systemName];
    }
    
    return self;
}

- (id)initWithPath:(NSString *)path
         machineId:(NSString *)machineId
              name:(NSString *)name
        systemName:(NSString *)systemName
{
    if ((self = [self init]))
    {
        _path = [path copy];
        _machineId = [machineId copy];
        _name = [name copy];
        _installed = NO;
        _system = [CMMachine systemNamed:systemName];
    }
    
    return self;
}

- (void)dealloc
{
    [self setPath:nil];
    [self setName:nil];
    [self setMachineId:nil];
    
    [super dealloc];
}

+ (NSInteger)systemNamed:(NSString *)systemName
{
    if ([systemName isEqual:@"MSX"])
        return CMMsx;
    else if ([systemName isEqual:@"MSX2"])
        return CMMsx2;
    else if ([systemName isEqual:@"MSX2+"])
        return CMMsx2Plus;
    else if ([systemName isEqual:@"MSXturboR"])
        return CMMsxTurboR;
    
    return CMUnknown;
}

- (NSString *)systemName
{
    if (_system == CMMsx)
        return CMMsxMachine;
    if (_system == CMMsx2)
        return CMMsx2Machine;
    if (_system == CMMsx2Plus)
        return CMMsx2PMachine;
    if (_system == CMMsxTurboR)
        return CMMsxTurboRMachine;
    
    return nil;
}

- (NSUInteger)hash
{
    return [[self machineId] hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[CMMachine class]])
        return [[self machineId] isEqualToString:[object machineId]];
    if ([object isKindOfClass:[NSString class]])
        return [[self machineId] isEqualToString:object];
    
    return NO;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMMachine *copy = [[self class] allocWithZone:zone];
    
    [copy setPath:[self path]];
    [copy setName:[self name]];
    [copy setMachineId:[self machineId]];
    [copy setInstalled:[self installed]];
    [copy setSystem:[self system]];
    
    return copy;
}

@end

