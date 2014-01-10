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
#import "CMGamepadConfiguration.h"

@implementation CMGamepadConfiguration

@synthesize vendorProductId = _vendorProductId;

@synthesize minX = _minX;
@synthesize centerX = _centerX;
@synthesize maxX = _maxX;
@synthesize minY = _minY;
@synthesize centerY = _centerY;
@synthesize maxY = _maxY;

@synthesize buttonAIndex = _buttonAIndex;
@synthesize buttonBIndex = _buttonBIndex;

- (id)init
{
    if ((self = [super init]))
    {
        [self setCenterX:NSIntegerMin];
        [self setCenterY:NSIntegerMin];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - Etc

- (void)clear
{
    [self setMinX:0];
    [self setCenterX:NSIntegerMin];
    [self setMaxX:0];
    
    [self setMinY:0];
    [self setCenterY:NSIntegerMin];
    [self setMaxY:0];
    
    [self setButtonAIndex:0];
    [self setButtonBIndex:0];
    
    [self setVendorProductId:0];
}

- (void)dump
{
#ifdef DEBUG
    NSLog(@"X: %ld < %ld > %ld",
          (long)[self minX], (long)[self centerX], (long)[self maxX]);
    NSLog(@"Y: %ld < %ld > %ld",
          (long)[self minY], (long)[self centerY], (long)[self maxY]);
    
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
        
        [self setMinX:[decoder decodeIntegerForKey:@"minX"]];
        [self setCenterX:[decoder decodeIntegerForKey:@"centerX"]];
        [self setMaxX:[decoder decodeIntegerForKey:@"maxX"]];
        
        [self setMinY:[decoder decodeIntegerForKey:@"minY"]];
        [self setCenterY:[decoder decodeIntegerForKey:@"centerY"]];
        [self setMaxY:[decoder decodeIntegerForKey:@"maxY"]];
        
        [self setButtonAIndex:[decoder decodeIntegerForKey:@"buttonAIndex"]];
        [self setButtonBIndex:[decoder decodeIntegerForKey:@"buttonBIndex"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:[self vendorProductId] forKey:@"vendorProductId"];
    
    [encoder encodeInteger:[self minX] forKey:@"minX"];
    [encoder encodeInteger:[self centerX] forKey:@"centerX"];
    [encoder encodeInteger:[self maxX] forKey:@"maxX"];
    
    [encoder encodeInteger:[self minY] forKey:@"minY"];
    [encoder encodeInteger:[self centerY] forKey:@"centerY"];
    [encoder encodeInteger:[self maxY] forKey:@"maxY"];
    
    [encoder encodeInteger:[self buttonAIndex] forKey:@"buttonAIndex"];
    [encoder encodeInteger:[self buttonBIndex] forKey:@"buttonBIndex"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMGamepadConfiguration *copy = [[[self class] allocWithZone:zone] init];
    
    [copy setVendorProductId:[self vendorProductId]];
    
    [copy setMinX:[self minX]];
    [copy setCenterX:[self centerX]];
    [copy setMaxX:[self maxX]];
    
    [copy setMinY:[self minY]];
    [copy setCenterY:[self centerY]];
    [copy setMaxY:[self maxY]];
    
    [copy setButtonAIndex:[self buttonAIndex]];
    [copy setButtonBIndex:[self buttonBIndex]];
    
    return copy;
}

@end
