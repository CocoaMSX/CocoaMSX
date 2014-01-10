/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2014 Akop Karapetyan
 **
 ** Semaphore implementation based on SDL_sem:
 **
 **   SDL - Simple DirectMedia Layer
 **   Copyright (C) 1997-2012 Sam Lantinga (slouken@libsdl.org)
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
#import "CMEvent.h"
#import "CMSemaphore.h"

#pragma mark - CMEvent

@implementation CMEvent

- (id)initWithState:(BOOL)initialState
{
    if ((self = [super init]))
    {
        state = initialState;
        eventSem = [[CMSemaphore alloc] initWithCount:state];
    }
    
    return self;
}

- (void)dealloc
{
    [eventSem release];
    
    [super dealloc];
}

- (void)set
{
    if (!state)
    {
        state = YES;
        [eventSem signal];
    }
}

- (void)wait
{
    [eventSem wait];
    state = NO;
}

@end

#pragma mark - blueMSX Event Callbacks

void* archEventCreate(int initState)
{
    return [[CMEvent alloc] initWithState:initState];
}

void archEventDestroy(void *event)
{
    [(CMEvent *)event release];
}

void archEventSet(void *event)
{
    [(CMEvent *)event set];
}

void archEventWait(void *event, int timeout)
{
    [(CMEvent *)event wait];
}
