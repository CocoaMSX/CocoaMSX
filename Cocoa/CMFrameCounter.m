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
#import "CMFrameCounter.h"

@interface CMFrameCounter ()

- (CGFloat)average:(NSInteger)newTick;

@end

@implementation CMFrameCounter

#define MAX_SAMPLES 100

- (id)init
{
    if ((self = [super init]))
    {
        tickList = calloc(MAX_SAMPLES, sizeof(NSInteger));
        tickIndex = 0;
        tickSum = 0;
        lastTick = [[NSDate date] retain];
    }
    
    return self;
}

- (CGFloat)update;
{
    NSDate *now = [NSDate date];
    CGFloat freq = 1.0 / [now timeIntervalSinceDate:lastTick];
    [lastTick release];
    lastTick = [now retain];
    
    return [self average:(NSInteger)freq];
}

- (CGFloat)average:(NSInteger)newTick
{
    tickSum -= tickList[tickIndex];
    tickSum += newTick;
    tickList[tickIndex] = newTick;
    
    if (++tickIndex == MAX_SAMPLES)
        tickIndex = 0;
    
    return (CGFloat)tickSum / MAX_SAMPLES;
}

- (void)dealloc
{
    free(tickList);
    [lastTick release];
    
    [super dealloc];
}

@end
