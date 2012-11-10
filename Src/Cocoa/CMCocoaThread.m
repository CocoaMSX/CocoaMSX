/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012 Akop Karapetyan
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

#include "ArchThread.h"

#import "CMCocoaThread.h"

#pragma mark - CocoaThreadArg

@interface CMCocoaThreadArg : NSObject
{
    @public
    void (*entryPoint)();
}
@end

@implementation CMCocoaThreadArg

@end

#pragma mark - CocoaThread

@implementation CMCocoaThread

+ (void)threadEntry:(id)threadArg
{
    CMCocoaThreadArg *arg = (CMCocoaThreadArg*)threadArg;
    
    @autoreleasepool
    {
        arg->entryPoint();
    }
}

void* archThreadCreate(void (*entryPoint)(), int priority)
{
    NSThread *thread = nil;
    CMCocoaThreadArg *arg = [[CMCocoaThreadArg alloc] init];
    
    if (arg)
    {
        arg->entryPoint = entryPoint;
        
        thread = [[NSThread alloc] initWithTarget:[CMCocoaThread class]
                                         selector:@selector(threadEntry:)
                                           object:arg];
        
        [arg release];
        
        [thread start];
    }
    
    return thread;
}

void archThreadJoin(void* thread, int timeout) 
{
    NSThread *nsThread = (NSThread*)thread;
    while (![nsThread isFinished])
        [NSThread sleepForTimeInterval:20.0 / 1000.0];
}

void archThreadDestroy(void* thread) 
{
    NSThread *nsThread = (NSThread*)thread;
    [nsThread release];
}

void archThreadSleep(int milliseconds)
{
    [NSThread sleepForTimeInterval:milliseconds / 1000.0];
}

@end
