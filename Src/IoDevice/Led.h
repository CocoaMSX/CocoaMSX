/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/IoDevice/Led.h,v $
**
** $Revision: 1.5 $
**
** $Date: 2008-03-30 18:38:40 $
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
#ifndef MSXLED_H
#define MSXLED_H

#include <stdbool.h>

void ledSetAll(bool enable);

void ledSetCapslock(bool enable);
bool ledGetCapslock(void);

void ledSetKana(bool enable);
bool ledGetKana(void);

void ledSetTurboR(bool enable);
bool ledGetTurboR(void);

void ledSetPause(bool enable);
bool ledGetPause(void);

void ledSetRensha(bool enable);
bool ledGetRensha(void);

void ledSetFdd1(bool enable);
bool ledGetFdd1(void);

void ledSetFdd2(bool enable);
bool ledGetFdd2(void);

void ledSetHd(bool enable);
bool ledGetHd(void);

void ledSetCas(bool enable);
bool ledGetCas(void);

#endif

