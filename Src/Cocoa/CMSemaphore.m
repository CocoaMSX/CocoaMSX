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
#import "CMSemaphore.h"

#pragma mark - CMSemaphore

@implementation CMSemaphore

- (id)initWithCount:(NSInteger)initialCount
{
    if ((self = [super init]))
    {
        cond = [[NSCondition alloc] init];
        count = initialCount;
    }
    
    return self;
}

- (void)dealloc
{
    [cond release];
    
    [super dealloc];
}

- (void)signal
{
    [cond lock];
    
    if (++count > 0)
        [cond signal];
    
    [cond unlock];
}

- (void)wait
{
    [cond lock];
    
    while (count <= 0)
        [cond wait];
    
    --count;
    
    [cond unlock];
}

@end

#pragma mark - blueMSX Semaphore Callbacks

void* archSemaphoreCreate(int initCount)
{
    return [[CMSemaphore alloc] initWithCount:initCount];
}

void archSemaphoreDestroy(void *semaphore)
{
    [(CMSemaphore *)semaphore release];
}

void archSemaphoreSignal(void *semaphore)
{
    [(CMSemaphore *)semaphore signal];
}

void archSemaphoreWait(void *semaphore, int timeout)
{
    [(CMSemaphore *)semaphore wait];
}
