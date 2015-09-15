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
#include <stdio.h>
#include <stdlib.h>
#include <mach/mach_error.h>
#include <mach/mach_init.h>
#include <mach/semaphore.h>
#include <mach/task.h>

void * archSemaphoreCreate(int initCount)
{
    semaphore_t *sem = (semaphore_t *) malloc(sizeof(semaphore_t));
    if (sem != NULL) {
        kern_return_t ret = semaphore_create(mach_task_self(),
                                             sem, SYNC_POLICY_FIFO, initCount);
        if (ret != KERN_SUCCESS) {
            fprintf(stderr, "semaphore_create failed: (%s - %d)",
                    mach_error_string(ret), ret);
        }
    }
    
    return sem;
}

void archSemaphoreDestroy(void *semaphore)
{
    semaphore_destroy(mach_task_self(), *(semaphore_t *) semaphore);
}

void archSemaphoreSignal(void *semaphore)
{
    semaphore_signal(*(semaphore_t *) semaphore);
}

void archSemaphoreWait(void *semaphore, int timeout)
{
    semaphore_wait(*(semaphore_t *) semaphore);
}
