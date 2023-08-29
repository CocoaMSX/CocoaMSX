/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2016 Akop Karapetyan
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
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

struct CocoaThread {
    pthread_attr_t attr;
    pthread_t      pthreadId;
};

static void *pThreadCallback(void *data);

void * archThreadCreate(void (* entryPoint)(void), int priority)
{
    struct CocoaThread *ct = calloc(1, sizeof(struct CocoaThread));
    if (ct != NULL) {
        int status;
        status = pthread_attr_init(&ct->attr);
        assert(status == 0);
        status = pthread_create(&ct->pthreadId, &ct->attr, &pThreadCallback, entryPoint);
        assert(status == 0);
    }
    
    return ct;
}

void archThreadJoin(void *thread, int timeout)
{
    pthread_join(((struct CocoaThread *) thread)->pthreadId, NULL);
}

void archThreadDestroy(void *thread)
{
    pthread_attr_destroy(&((struct CocoaThread *) thread)->attr);
    free(thread);
}

void archThreadSleep(int milliseconds)
{
    usleep(milliseconds * 1000);
}

static void* pThreadCallback(void *data)
{
    void (* entryPoint)(void) = data;
    
    @autoreleasepool
    {
        entryPoint();
    }
    
    return NULL;
    
}
