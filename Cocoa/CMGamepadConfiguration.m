/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2015 Akop Karapetyan
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
#import "CMGamepadConfiguration.h"

@implementation CMGamepadConfiguration

@synthesize vendorProductId = _vendorProductId;

- (id)init
{
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - Etc

- (void) clear
{
    [self setButtonAIndex:0];
    [self setButtonBIndex:1];
    
    [self setVendorProductId:0];
}

- (void)dump
{
#ifdef DEBUG
    NSLog(@"Buttons: A (%ld) B (%ld)",
          (long)[self buttonAIndex], (long)[self buttonBIndex]);
#endif
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [self init]))
    {
        [self setVendorProductId:[decoder decodeIntegerForKey:@"vendorProductId"]];
        
        [self setButtonAIndex:[decoder decodeIntegerForKey:@"buttonAIndex"]];
        [self setButtonBIndex:[decoder decodeIntegerForKey:@"buttonBIndex"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:[self vendorProductId] forKey:@"vendorProductId"];
    
    [encoder encodeInteger:[self buttonAIndex] forKey:@"buttonAIndex"];
    [encoder encodeInteger:[self buttonBIndex] forKey:@"buttonBIndex"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMGamepadConfiguration *copy = [[[self class] allocWithZone:zone] init];
    
    [copy setVendorProductId:[self vendorProductId]];
    
    [copy setButtonAIndex:[self buttonAIndex]];
    [copy setButtonBIndex:[self buttonBIndex]];
    
    return copy;
}

@end
