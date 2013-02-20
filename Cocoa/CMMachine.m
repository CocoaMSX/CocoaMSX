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
#import "CMPreferences.h"

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
@synthesize machineUrl = _machineUrl;
@synthesize checksum = _checksum;
@synthesize installed = _installed;
@synthesize system = _system;

- (id)init
{
    if ((self = [super init]))
    {
        _name = nil;
        _path = nil;
        _machineId = nil;
        _machineUrl = nil;
        _checksum = nil;
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
    [self setMachineUrl:nil];
    [self setChecksum:nil];
    
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

- (NSString *)downloadPath
{
    if (![self path])
        return nil;
    
    CMPreferences *prefs = [CMPreferences preferences];
    return [[prefs machineDirectory] stringByAppendingPathComponent:[[self machineUrl] lastPathComponent]];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [self init]))
    {
        _name = [[aDecoder decodeObjectForKey:@"name"] retain];
        _path = [[aDecoder decodeObjectForKey:@"path"] retain];
        _machineId = [[aDecoder decodeObjectForKey:@"machineId"] retain];
        _machineUrl = [[aDecoder decodeObjectForKey:@"machineUrl"] retain];
        _checksum = [[aDecoder decodeObjectForKey:@"checksum"] retain];
        _installed = [aDecoder decodeBoolForKey:@"installed"];
        _system = [aDecoder decodeIntegerForKey:@"system"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_path forKey:@"path"];
    [aCoder encodeObject:_machineId forKey:@"machineId"];
    [aCoder encodeObject:_machineUrl forKey:@"machineUrl"];
    [aCoder encodeObject:_checksum forKey:@"checksum"];
    [aCoder encodeBool:_installed forKey:@"installed"];
    [aCoder encodeInteger:_system forKey:@"system"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMMachine *copy = [[self class] allocWithZone:zone];
    
    [copy setName:_name];
    [copy setPath:_path];
    [copy setMachineId:_machineId];
    [copy setMachineUrl:_machineUrl];
    [copy setChecksum:_checksum];
    [copy setInstalled:_installed];
    [copy setSystem:_system];
    
    return copy;
}

@end

