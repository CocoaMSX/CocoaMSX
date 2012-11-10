/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Arch/ArchTimer.h,v $
**
** $Revision: 72 $
**
** $Date: 2012-10-19 17:09:05 -0700 (Fri, 19 Oct 2012) $
**
** More info: http://www.bluemsx.com
**
** Copyright (C) 2003-2006 Daniel Vik
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
#ifndef ARCH_TIMER_H
#define ARCH_TIMER_H

#include "MsxTypes.h"

UInt32 archGetSystemUpTime(UInt32 frequency);
void* archCreateTimer(int period, int (*timerCallback)(void*));
void archTimerDestroy(void* timer);
UInt32 archGetHiresTimer();

#define RDTSC_MAX_TIMERS 5

void rdtsc_start_timer (int timer) ;
void rdtsc_end_timer (int timer);
unsigned long long int rdtsc_get_timer (int timer) ;

#endif
