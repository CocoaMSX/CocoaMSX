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
#import "CMKeyboardInput.h"

@implementation CMKeyboardInput

@synthesize keyCode = _keyCode;

+ (CMKeyboardInput *)keyboardInputWithKeyCode:(NSInteger)keyCode
{
    CMKeyboardInput *key = [[CMKeyboardInput alloc] init];
    [key setKeyCode:keyCode];
    
    return [key autorelease];
}

#pragma mark - init & dealloc

- (id)init
{
    if ((self = [super init]))
    {
        [self setKeyCode:CMKeyNoCode];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder]))
    {
        [self setKeyCode:[decoder decodeIntegerForKey:@"keyCode"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];

    [encoder encodeInteger:[self keyCode] forKey:@"keyCode"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMKeyboardInput *copy = [[super copyWithZone:zone] init];
    [copy setKeyCode:[self keyCode]];
    
    return copy;
}

#pragma mark - CMInputMethod

- (BOOL)isEqualToInputMethod:(CMInputMethod *)inputMethod
{
    if (![inputMethod isKindOfClass:[CMKeyboardInput class]])
        return NO;
    
    return [((CMKeyboardInput *)inputMethod) keyCode] == [self keyCode];
}

@end
