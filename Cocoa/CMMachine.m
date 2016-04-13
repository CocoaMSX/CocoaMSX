/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2016 Akop Karapetyan
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
NSString *const CMMsx2Machine      = @"MSX₂";
NSString *const CMMsx2PMachine     = @"MSX₂₊";
NSString *const CMMsxTurboRMachine = @"MSX Turbo R";

@interface CMMachine ()

+ (NSInteger)systemNamed:(NSString *)systemName;

@end

@implementation CMMachine

+ (CMMachine *)machineWithPath:(NSString *)path
{
    return [[CMMachine alloc] initWithPath:path];
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
        _name = [aDecoder decodeObjectForKey:@"name"];
        _path = [aDecoder decodeObjectForKey:@"path"];
        _machineId = [aDecoder decodeObjectForKey:@"machineId"];
        _machineUrl = [aDecoder decodeObjectForKey:@"machineUrl"];
        _checksum = [aDecoder decodeObjectForKey:@"checksum"];
        _system = [aDecoder decodeIntegerForKey:@"system"];
        _status = [aDecoder decodeIntegerForKey:@"status"];
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
    
    return copy;
}

- (NSComparisonResult) compare:(CMMachine *)machine
{
	if (_system != machine->_system) {
		return _system - machine->_system;
	}
	
    return [_name caseInsensitiveCompare:machine->_name];
}

@end

