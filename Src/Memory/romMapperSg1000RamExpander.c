/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/romMapperSg1000RamExpander.c,v $
**
** $Revision: 1.5 $
**
** $Date: 2008-03-30 18:38:44 $
**
** More info: http://www.bluemsx.com
**
** Copyright (C) 2003-2012 Daniel Vik
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
#include "romMapperSg1000RamExpander.h"
#include "MediaDb.h"
#include "SlotManager.h"
#include "DeviceManager.h"
#include "SaveState.h"
#include "sramLoader.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>


typedef struct {
    int deviceHandle;
    UInt8* romData;
    UInt8 ram1[0x2000];
    UInt8 ram2[0x2000];
    int slot;
    int sslot;
    int startPage;
    int mask2;
} RomMapperSg1000RamExpander;

static void saveState(RomMapperSg1000RamExpander* rm)
{
    SaveState* state = saveStateOpenForWrite("mapperSegaRamExpander");

    saveStateSet(state, "mask2", rm->mask2);
    saveStateSetBuffer(state, "ram1", rm->ram1, 0x2000);
    saveStateSetBuffer(state, "ram2", rm->ram2, rm->mask2 + 1);

    saveStateClose(state);
}

static void loadState(RomMapperSg1000RamExpander* rm)
{
    SaveState* state = saveStateOpenForRead("mapperSegaRamExpander");

    rm->mask2 = saveStateGet(state, "mask2", 0x400);
    saveStateGetBuffer(state, "ram1", rm->ram2, 0x2000);
    saveStateGetBuffer(state, "ram2", rm->ram2, rm->mask2 + 1);

    saveStateClose(state);
}

static void destroy(RomMapperSg1000RamExpander* rm)
{
    slotUnregister(rm->slot, rm->sslot, rm->startPage);
    deviceManagerUnregister(rm->deviceHandle);

    free(rm->romData);
    free(rm);
}

static UInt8 read(RomMapperSg1000RamExpander* rm, UInt16 address) 
{
    return rm->ram2[address & rm->mask2];
}

static void write(RomMapperSg1000RamExpander* rm, UInt16 address, UInt8 value) 
{
    rm->ram2[address & rm->mask2] = value;
}

int romMapperSg1000RamExpanderCreate(const char* filename, UInt8* romData, 
                                     int size, int slot, int sslot, int startPage, int type) 
{
    DeviceCallbacks callbacks = { destroy, NULL, saveState, loadState };
    RomMapperSg1000RamExpander* rm;
    int pages = size / 0x2000 + ((size & 0x1fff) ? 1 : 0);
    int i;

    if (size != 0x8000 || startPage != 0) {
        return 0;
    }

    rm = malloc(sizeof(RomMapperSg1000RamExpander));

    rm->deviceHandle = deviceManagerRegister(type, &callbacks, rm);
    slotRegister(slot, sslot, startPage, pages, read, read, write, destroy, rm);

    rm->romData = malloc(pages * 0x2000);
    memcpy(rm->romData, romData, size);
    memset(rm->ram1, sizeof(rm->ram1), 0xff);
    memset(rm->ram2, sizeof(rm->ram2), 0xff);

    rm->slot  = slot;
    rm->sslot = sslot;
    rm->startPage  = startPage;
    rm->mask2 = ROM_SG1000_RAMEXPANDER_A ? 0x0400 : 0x2000;
    
    for (i = 0; i < pages; i++) {
        if (i + startPage >= 2) slot = 0;
        if (type == ROM_SG1000_RAMEXPANDER_A && i + startPage == 1) {
            slotMapPage(slot, sslot, i + startPage, rm->ram1, 1, 1);
        }
        else {
            slotMapPage(slot, sslot, i + startPage, rm->romData + 0x2000 * i, 1, 0);
        }
    }

    slotMapPage(slot, sslot, 6, NULL, 0, 0);
    slotMapPage(slot, sslot, 7, NULL, 0, 0);

    return 1;
}

