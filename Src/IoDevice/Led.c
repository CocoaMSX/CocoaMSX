/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/IoDevice/Led.c,v $
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
#include "Led.h"

static bool ledCapslock = false;
static bool ledKana     = false;
static bool ledTurboR   = false;
static bool ledPause    = false;
static bool ledRensha   = false;
static bool ledFdd1     = false;
static bool ledFdd2     = false;
static bool ledHd       = false;
static bool ledCas      = false;

void ledSetAll(bool enable) {
    enable = enable ? true : false;
    
    ledCapslock = enable;
    ledKana     = enable;
    ledTurboR   = enable;
    ledPause    = enable;
    ledRensha   = enable;
    ledFdd1     = enable;
    ledFdd2     = enable;
    ledHd       = enable;
    ledCas      = enable;
}

void ledSetCapslock(bool enable) {
    ledCapslock = enable ? true : false;
}

bool ledGetCapslock(void) {
    return ledCapslock;
}

void ledSetKana(bool enable) {
    ledKana = enable ? true : false;
}

bool ledGetKana(void) {
    return ledKana;
}

void ledSetTurboR(bool enable) {
    ledTurboR = enable ? true : false;
}

bool ledGetTurboR(void) {
    return ledTurboR;
}

void ledSetPause(bool enable) {
    ledPause = enable ? true : false;
}

bool ledGetPause(void) {
    return ledPause;
}

void ledSetRensha(bool enable) {
    ledRensha = enable ? true : false;
}

bool ledGetRensha(void) {
    return ledRensha;
}

void ledSetFdd1(bool enable) {
    ledFdd1 = enable ? true : false;
}

bool ledGetFdd1(void) {
    return ledFdd1;
}

void ledSetFdd2(bool enable) {
    ledFdd2 = enable ? true : false;
}

bool ledGetFdd2(void) {
    return ledFdd2;
}

void ledSetHd(bool enable) {
    ledHd = enable ? true : false;
}

bool ledGetHd(void) {
    return ledHd;
}

void ledSetCas(bool enable) {
    ledCas = enable ? true : false;
}

bool ledGetCas(void) {
    return ledCas;
}

