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
#include <stdlib.h>
#include <sys/time.h>

#include "ArchTimer.h"

#import "CMCocoaTimer.h"

#pragma mark - CocoaTimerArg

@interface CMCocoaTimerArg : NSObject
{
    @public
    int (*timerCb)(void*);
    UInt32 timerFreq;
    UInt32 lastTimeout;
}
@end

@implementation CMCocoaTimerArg
@end

#pragma mark - CocoaTimer

@implementation CMCocoaTimer

static struct timeval start = { -1, -1 };

+ (void)callbackCalledByTimer:(NSTimer*)timer
{
    CMCocoaTimerArg *arg = (CMCocoaTimerArg*)timer.userInfo;
    
    if (arg->timerCb)
    {
        UInt32 currentTime = archGetSystemUpTime(arg->timerFreq);
        
        if (arg->lastTimeout != currentTime)
        {
            arg->lastTimeout = currentTime;
            arg->timerCb(arg->timerCb);
        }
    }
}

void* archCreateTimer(int period, int (*timerCallback)(void*))
{
    NSTimer *timer = nil;
    CMCocoaTimerArg *arg = [[CMCocoaTimerArg alloc] init];
    
    if (arg)
    {
        arg->timerFreq = 1000 / period;
        arg->lastTimeout = archGetSystemUpTime(arg->timerFreq);
        arg->timerCb = timerCallback;
        
        timer = [[NSTimer timerWithTimeInterval:period / 1000.0
                                         target:[CMCocoaTimer class]
                                       selector:@selector(callbackCalledByTimer:)
                                       userInfo:arg
                                        repeats:YES] retain];
        
        [arg release];
        
        [[NSRunLoop currentRunLoop] addTimer:timer
                                     forMode:NSRunLoopCommonModes];
    }
    
    return timer;
}

void archTimerDestroy(void* timer) 
{
    NSTimer *nsTimer = (NSTimer*)timer;
    [nsTimer invalidate];
    
    [nsTimer release];
}

UInt32 archGetSystemUpTime(UInt32 frequency) 
{
    return archGetHiresTimer() / (1000 / frequency);
}

UInt32 archGetHiresTimer()
{
    if (start.tv_sec < 0)
        gettimeofday(&start, NULL);
    
	UInt32 ticks;
	struct timeval now;
	gettimeofday(&now, NULL);
	ticks = (now.tv_sec - start.tv_sec) * 1000 + (now.tv_usec - start.tv_usec) / 1000;
    
    return ticks;
}

@end