/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/romMapperMuPack.c,v $
**
** $Revision: 1.10 $
**
** $Date: 2008-03-30 18:38:44 $
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
#include "romMapperMuPack.h"
#include "MediaDb.h"
#include "SlotManager.h"
#include "DeviceManager.h"
#include "SaveState.h"
#include "ramMapperIo.h"
#include "MSXMidi.h"
#include <stdlib.h>
#include <string.h>


typedef struct {
    int deviceHandle;
    UInt8* romData;
    int slot;
    int sslot;
    int romSize;
    UInt8 sslReg;
    UInt8 subslot[4];
    
    int handle;
    UInt8* ramData;
    int ramMask;
    UInt8 ramPort[4];

} RomMapperMuPack;


static void writeIo(RomMapperMuPack* rm, UInt16 page, UInt8 value)
{
    rm->ramPort[page] = value;
}

static void saveState(RomMapperMuPack* rm)
{
    SaveState* state = saveStateOpenForWrite("mapperMuPack");

    saveStateSet(state, "sslReg", rm->sslReg);
    saveStateSetBuffer(state, "subslot", rm->subslot, 4);

    saveStateSetBuffer(state, "ramPort", rm->ramPort, 4);
    saveStateSetBuffer(state, "ramData", rm->ramData, 0x4000 * (rm->ramMask + 1));

    saveStateClose(state);
}

static void loadState(RomMapperMuPack* rm)
{
    SaveState* state = saveStateOpenForRead("mapperMuPack");
    int i;
    
    rm->sslReg = (UInt8)saveStateGet(state, "sslReg", 0);
    saveStateGetBuffer(state, "subslot", rm->subslot, 4);
    
    saveStateGetBuffer(state, "ramPort", rm->ramPort, 4);
    saveStateGetBuffer(state, "ramData", rm->ramData, 0x4000 * (rm->ramMask + 1));

    saveStateClose(state);

    for (i = 0; i < 4; i++) {
        writeIo(rm, i, rm->ramPort[i]);
    }
}

static void destroy(RomMapperMuPack* rm)
{
    slotUnregister(rm->slot, rm->sslot, 0);
    deviceManagerUnregister(rm->deviceHandle);
    
    ramMapperIoRemove(rm->handle);

    free(rm->romData);
    free(rm->ramData);
    free(rm);
}

static void reset(RomMapperMuPack* rm)
{
    int page;
    rm->sslReg = 0;
    for (page = 0; page < 4; page++) {
        rm->subslot[page] = 0;
        rm->ramPort[page] = page;
    }
}

static UInt8 read(RomMapperMuPack* rm, UInt16 address) 
{
    int page = address >> 14;
    int ramBaseAddr;

    if (address == 0xffff) {
        return ~rm->sslReg;
    }

    switch (rm->subslot[page]) {
    case 1:
        ramBaseAddr = 0x4000 * (rm->ramPort[page] & rm->ramMask);
        return rm->ramData[ramBaseAddr + (address & 0x3fff)];
    case 2:
        if (address >= 0x4000 && address < 0x4000 + rm->romSize) {
            return rm->romData[address - 0x4000];
        }
        return 0xff;
    }
    return 0xff;
}


static void write(RomMapperMuPack* rm, UInt16 address, UInt8 value) 
{
    int page = address >> 14;
    int ramBaseAddr;

    if (address == 0xffff) {
        rm->sslReg = value;
        for (page = 0; page < 4; page++) {
            rm->subslot[page] = value & 3;
            value >>= 2;
        }
        return;
    }
    switch (rm->subslot[page]) {
    case 1:
        ramBaseAddr = 0x4000 * (rm->ramPort[page] & rm->ramMask);
        rm->ramData[ramBaseAddr + (address & 0x3fff)] = value;
    }
}

int romMapperMuPackCreate(const char* filename, UInt8* romData, 
                           int size, int slot, int sslot, int startPage) 
{
    DeviceCallbacks callbacks = { destroy, reset, saveState, loadState };
    RomMapperMuPack* rm;
    int i;

    rm = malloc(sizeof(RomMapperMuPack));

    rm->deviceHandle = deviceManagerRegister(ROM_MUPACK, &callbacks, rm);
    slotRegister(slot, sslot, 0, 8, read, read, write, destroy, rm);

    rm->romData = calloc(1, size);
    memcpy(rm->romData, romData, size);
    rm->romSize = size;
    rm->slot  = slot;
    rm->sslot = sslot;

    // Ram mapper
    rm->ramMask = 16 - 1;
    rm->ramData  = malloc((rm->ramMask + 1) * 0x4000);
    rm->handle  = ramMapperIoAdd((rm->ramMask + 1) * 0x4000, writeIo, rm);

    // MIDI
    MSXMidiCreate(1);

    for (i = 0; i < 8; i++) { 
        slotMapPage(rm->slot, rm->sslot, i, NULL, 0, 0);
    }

    reset(rm);

    return 1;
}

