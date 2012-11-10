/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/IoDevice/Led.h,v $
**
** $Revision: 73 $
**
** $Date: 2012-10-19 17:10:16 -0700 (Fri, 19 Oct 2012) $
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

void ledSetAll(int enable);

void ledSetCapslock(int enable);
int  ledGetCapslock();

void ledSetKana(int enable);
int  ledGetKana();

void ledSetTurboR(int enable);
int  ledGetTurboR();

void ledSetPause(int enable);
int  ledGetPause();

void ledSetRensha(int enable);
int  ledGetRensha();

void ledSetFdd1(int enable);
int  ledGetFdd1();

void ledSetFdd2(int enable);
int  ledGetFdd2();

void ledSetHd(int enable);
int  ledGetHd();

void ledSetCas(int enable);
int  ledGetCas();

#endif

