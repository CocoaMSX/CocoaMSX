/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012 Akop Karapetyan
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
#include "ArchEvent.h"
#include <stdlib.h>

typedef struct {
    void* eventSem;
    void* lockSem;
    int   state;
} Event;

void* archEventCreate(int initState) 
{ 
    Event* e = calloc(1, sizeof(Event));
    e->state = initState ? 1 : 0;
    e->lockSem  = archSemaphoreCreate(1);
    e->eventSem  = archSemaphoreCreate(e->state);
    return e; 
}

void archEventDestroy(void *event) 
{
    Event* e = (Event*)event;
    archSemaphoreDestroy(e->lockSem);
    archSemaphoreDestroy(e->eventSem);
    free(e);
}

void archEventSet(void *event)
{
    Event* e = (Event*)event;
    if (e->state == 0) {
        e->state = 1;
        archSemaphoreSignal(e->eventSem);
    }
}

void archEventWait(void *event, int timeout) 
{
    Event* e = (Event*)event;
    archSemaphoreWait(e->eventSem, timeout);
    e->state = 0;
}

typedef struct {
    NSCondition *cond;
    NSInteger count;
    NSInteger waitersCount;
} Semaphore;

void* archSemaphoreCreate(int initCount) 
{
    Semaphore *s = (Semaphore*)malloc(sizeof(Semaphore));
    if (!s)
        return NULL;
    
    NSCondition *cond = [[NSCondition alloc] init];
    
    s->cond = cond;
    s->count = initCount;
    s->waitersCount = 0;
    
    return s;
}

void archSemaphoreDestroy(void *semaphore)
{
    Semaphore* s = (Semaphore*)semaphore;
    [s->cond release];
    free(s);
}

void archSemaphoreSignal(void *semaphore)
{
    Semaphore* s = (Semaphore*)semaphore;
    
    [s->cond lock];
    if (s->waitersCount > 0)
        [s->cond signal];
    
	++s->count;
    [s->cond unlock];
}

void archSemaphoreWait(void *semaphore, int timeout) 
{
    Semaphore* s = (Semaphore*)semaphore;

    [s->cond lock];
    
	++s->waitersCount;
    while (s->count == 0)
        [s->cond wait];
    
	--s->waitersCount;
    --s->count;
    
    [s->cond unlock];
}
