/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Input/MsxTetrisDongle.c,v $
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
#include "MsxTetrisDongle.h"
#include <stdlib.h>
#include "SaveState.h"

struct MsxTetrisDongle {
    MsxJoystickDevice joyDevice;
    UInt8 state;
};

static UInt8 read(MsxTetrisDongle* tetrisDongle) {
    return tetrisDongle->state;
}

static void write(MsxTetrisDongle* tetrisDongle, UInt8 value) {
    if (value & 0x02) {
        tetrisDongle->state |= 0x08;
    }
    else {
        tetrisDongle->state &= ~0x08;
    }
}

static void saveState(MsxTetrisDongle* tetrisDongle)
{
    SaveState* state = saveStateOpenForWrite("tetrisDongle");
    
    saveStateSet(state, "state", tetrisDongle->state);

    saveStateClose(state);
}

static void loadState(MsxTetrisDongle* tetrisDongle) 
{
    SaveState* state = saveStateOpenForRead("tetrisDongle");

    tetrisDongle->state = (UInt8)saveStateGet(state, "state", 0x3f);

    saveStateClose(state);
}

static void reset(MsxTetrisDongle* tetrisDongle) {
    tetrisDongle->state = 0x3f;
}

MsxJoystickDevice* msxTetrisDongleCreate()
{
    MsxTetrisDongle* tetrisDongle = (MsxTetrisDongle*)calloc(1, sizeof(MsxTetrisDongle));
    tetrisDongle->joyDevice.read      = (UInt8(*)(void*))read;
    tetrisDongle->joyDevice.write     = (void(*)(void*, UInt8))write;
    tetrisDongle->joyDevice.reset     = (void(*)(void*))reset;
    tetrisDongle->joyDevice.loadState = (void(*)(void*))loadState;
    tetrisDongle->joyDevice.saveState = (void(*)(void*))saveState;

    reset(tetrisDongle);
    
    return (MsxJoystickDevice*)tetrisDongle;
}