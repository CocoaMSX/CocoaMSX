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

@implementation CMMachine

@synthesize path = _path;
@synthesize name = _name;

+ (CMMachine *)machineWithPath:(NSString *)path
{
    CMMachine *machine = [[CMMachine alloc] init];
    
    [machine setPath:path];
    [machine setName:path];
    machine->system = CMUnknown;
    
    NSRange occurrence = [path rangeOfString:@" - "];
    if (occurrence.location != NSNotFound)
    {
        NSString *name = [path substringFromIndex:occurrence.location + occurrence.length];
        NSString *system = [path substringToIndex:occurrence.location];
        
        if ([system isEqual:@"MSX"])
            machine->system = CMMsx;
        else if ([system isEqual:@"MSX2"])
            machine->system = CMMsx2;
        else if ([system isEqual:@"MSX2+"])
            machine->system = CMMsx2Plus;
        else if ([system isEqual:@"MSXturboR"])
            machine->system = CMMsxTurboR;
        
        [machine setName:name];
    }
    
    return [machine autorelease];
}

- (void)dealloc
{
    [_path release];
    [_name release];
    
    [super dealloc];
}

- (NSString *)systemName
{
    if (system == CMMsx)
        return CMMsxMachine;
    if (system == CMMsx2)
        return CMMsx2Machine;
    if (system == CMMsx2Plus)
        return CMMsx2PMachine;
    if (system == CMMsxTurboR)
        return CMMsxTurboRMachine;
    
    return nil;
}


- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[CMMachine class]])
        return [[self path] isEqualToString:[object path]];
    if ([object isKindOfClass:[NSString class]])
        return [[self path] isEqualToString:object];
    
    return NO;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMMachine *copy = [[self class] allocWithZone:zone];
    
    copy->_path = [_path retain];
    copy->_name = [_name retain];
    copy->system = system;
    
    return copy;
}

@end

