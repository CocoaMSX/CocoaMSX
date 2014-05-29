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
#import "CMMachine.h"

#import "NSString+CMExtensions.h"
#import "CMPreferences.h"

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
@synthesize system = _system;
@synthesize status = _status;
@synthesize active = _active;

+ (CMMachine *)machineWithPath:(NSString *)path
{
    return [[[CMMachine alloc] initWithPath:path] autorelease];
}

- (id)init
{
    if ((self = [super init]))
    {
        _name = nil;
        _path = nil;
        _machineId = nil;
        _machineUrl = nil;
        _checksum = nil;
        _system = CMUnknown;
        _status = CMMachineDownloadable;
        _active = NO;
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

- (void)setActive:(BOOL)active
{
    _active = active;
    
    // Set this machine as the active machine in preferences
    if (active)
        CMSetObjPref(@"machineConfiguration", _machineId);
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
        _system = [aDecoder decodeIntegerForKey:@"system"];
        _status = [aDecoder decodeIntegerForKey:@"status"];
        _active = [aDecoder decodeBoolForKey:@"active"];
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
    [aCoder encodeInteger:_system forKey:@"system"];
    [aCoder encodeInteger:_status forKey:@"status"];
    [aCoder encodeBool:_active forKey:@"active"];
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
 
    copy->_status = _status;
    copy->_system = _system;
    copy->_active = _active;
    
    return copy;
}

- (NSComparisonResult)compare:(CMMachine *)machine
{
    if (_system < machine->_system)
        return NSOrderedAscending;
    else if (_system > machine->_system)
        return NSOrderedDescending;
    
    return [_name caseInsensitiveCompare:machine->_name];
}

@end

