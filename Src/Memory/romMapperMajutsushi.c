/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/romMapperMajutsushi.c,v $
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
#include "romMapperMajutsushi.h"
#include "MediaDb.h"
#include "SlotManager.h"
#include "DeviceManager.h"
#include "Board.h"
#include "DAC.h"
#include "SaveState.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>


typedef struct {
    int deviceHandle;
    UInt8* romData;
	DAC* dac;
    int slot;
    int sslot;
    int startPage;
    int size;
    int romMapper[4];
} RomMapperMajutsushi;

static void saveState(RomMapperMajutsushi* rm)
{
    SaveState* state = saveStateOpenForWrite("mapperMajutsushi");
    char tag[16];
    int i;

    for (i = 0; i < 4; i++) {
        sprintf(tag, "romMapper%d", i);
        saveStateSet(state, tag, rm->romMapper[i]);
    }

    saveStateClose(state);
}

static void loadState(RomMapperMajutsushi* rm)
{
    SaveState* state = saveStateOpenForRead("mapperMajutsushi");
    char tag[16];
    int i;

    for (i = 0; i < 4; i++) {
        sprintf(tag, "romMapper%d", i);
        rm->romMapper[i] = saveStateGet(state, tag, 0);
    }

    saveStateClose(state);

    for (i = 0; i < 4; i++) {   
        slotMapPage(rm->slot, rm->sslot, rm->startPage + i, rm->romData + rm->romMapper[i] * 0x2000, 1, 0);
    }
}

static void destroy(RomMapperMajutsushi* rm)
{
    slotUnregister(rm->slot, rm->sslot, rm->startPage);
    deviceManagerUnregister(rm->deviceHandle);
    dacDestroy(rm->dac);

    free(rm->romData);
    free(rm);
}

static void write(RomMapperMajutsushi* rm, UInt16 address, UInt8 value) 
{
    int bank;

    address += 0x4000;

    if (address >= 0x5000 && address < 0x6000) {
        dacWrite(rm->dac, DAC_CH_MONO, value);
		return;
	}

    /* Page at 4000h is fixed */
    if (address < 0x6000 || address >= 0xc000) {
        return;
    }

    bank = (address - 0x4000) >> 13;

    value %= rm->size / 0x2000;
    if (rm->romMapper[bank] != value) {
        UInt8* bankData = rm->romData + ((int)value << 13);

        rm->romMapper[bank] = value;
        
        slotMapPage(rm->slot, rm->sslot, rm->startPage + bank, bankData, 1, 0);
    }
}

int romMapperMajutsushiCreate(char* filename, UInt8* romData, 
                           int size, int slot, int sslot, int startPage) 
{
    DeviceCallbacks callbacks = {
        (DeviceCallback)destroy,
        NULL,
        (DeviceCallback)saveState,
        (DeviceCallback)loadState
    };
    RomMapperMajutsushi* rm;
    int i;

    if (size < 0x8000) {
        return 0;
    }

    rm = malloc(sizeof(RomMapperMajutsushi));

    rm->deviceHandle = deviceManagerRegister(ROM_MAJUTSUSHI, &callbacks, rm);
    slotRegister(slot, sslot, startPage, 4, NULL, NULL, (SlotWrite)write, (SlotEject)destroy, rm);

    rm->romData = malloc(size);
    memcpy(rm->romData, romData, size);
    rm->dac = dacCreate(boardGetMixer(), DAC_MONO);
    rm->size = size;
    rm->slot  = slot;
    rm->sslot = sslot;
    rm->startPage  = startPage;

    rm->romMapper[0] = 0;
    rm->romMapper[1] = 1;
    rm->romMapper[2] = 2;
    rm->romMapper[3] = 3;

    for (i = 0; i < 4; i++) {   
        slotMapPage(rm->slot, rm->sslot, rm->startPage + i, rm->romData + rm->romMapper[i] * 0x2000, 1, 0);
    }

    return 1;
}

