/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/romMapperMegaFlashRomScc.c,v $
**
** $Revision: 1.8 $
**
** $Date: 2008-03-22 11:41:02 $
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
#include "romMapperMegaFlashRomScc.h"
#include "AmdFlash.h"
#include "MediaDb.h"
#include "SlotManager.h"
#include "DeviceManager.h"
#include "IoPort.h"
#include "sramLoader.h"
#include "AY8910.h"
#include "SCC.h"
#include "Board.h"
#include "SaveState.h"
#include <stdlib.h>
#include <string.h>


typedef struct {
    int deviceHandle;
    int    debugHandle;
    UInt8* romData;
    AmdFlash* flash;
    int slot;
    int sslot;
    int startPage;
    int size;
    int romMask;
    int romMapper[4];
    int flashPage[4];
    int sccEnable;
    SCC* scc;
    AY8910* ay8910;
} RomMapperMegaFlashRomScc;

static void mapPage(RomMapperMegaFlashRomScc* rm, int bank, int page)
{
    int readEnable;
    UInt8* bankData;

    rm->romMapper[bank] = page & (rm->size / 0x2000 - 1);
    rm->flashPage[bank] = page;

    if (rm->flashPage[bank] < 0) {
        bankData = rm->romData + page * 0x2000;
    }
    else {
        bankData = amdFlashGetPage(rm->flash, rm->flashPage[bank] * 0x2000);
    }

    readEnable = (bank == 2 && rm->sccEnable) || rm->flashPage[bank] >= 0 ? 0 : 1;

    slotMapPage(rm->slot, rm->sslot, rm->startPage + bank, bankData, readEnable, 0);
}

static void saveState(RomMapperMegaFlashRomScc* rm)
{
    SaveState* state = saveStateOpenForWrite("mapperMegaFlashRomScc");
    char tag[16];
    int i;

    for (i = 0; i < 4; i++) {
        sprintf(tag, "romMapper%d", i);
        saveStateSet(state, tag, rm->romMapper[i]);
    }

    saveStateSet(state, "sccEnable", rm->sccEnable);

    saveStateClose(state);

    sccSaveState(rm->scc);
    if (rm->ay8910)
        ay8910SaveState(rm->ay8910);
    amdFlashSaveState(rm->flash);
}

static void loadState(RomMapperMegaFlashRomScc* rm)
{
    SaveState* state = saveStateOpenForRead("mapperMegaFlashRomScc");
    char tag[16];
    int i;

    for (i = 0; i < 4; i++) {
        sprintf(tag, "romMapper%d", i);
        rm->romMapper[i] = saveStateGet(state, tag, 0);
    }
    
    rm->sccEnable = saveStateGet(state, "sccEnable", 0);

    saveStateClose(state);

    sccLoadState(rm->scc);    
    if (rm->ay8910)
        ay8910LoadState(rm->ay8910);
    amdFlashLoadState(rm->flash);

    for (i = 0; i < 4; i++) {   
        mapPage(rm, i, rm->romMapper[i]);
    }    
}

static void destroy(RomMapperMegaFlashRomScc* rm)
{
    amdFlashDestroy(rm->flash);
    slotUnregister(rm->slot, rm->sslot, rm->startPage);
    deviceManagerUnregister(rm->deviceHandle);
    debugDeviceUnregister(rm->debugHandle);
    if (rm->ay8910)
        ay8910Destroy(rm->ay8910);
    sccDestroy(rm->scc);

    ioPortUnregister(0x10);
    ioPortUnregister(0x11);
    ioPortUnregister(0x12);

    free(rm->romData);
    free(rm);
}

static void reset(RomMapperMegaFlashRomScc* rm)
{
    amdFlashReset(rm->flash);
    sccReset(rm->scc);
    if (rm->ay8910)
        ay8910Reset(rm->ay8910);
}

static UInt8 read(RomMapperMegaFlashRomScc* rm, UInt16 address) 
{
    int bank = address / 0x2000;

    address += 0x4000;

    if (address >= 0x9800 && address < 0xa000 && rm->sccEnable) {
        return sccRead(rm->scc, (UInt8)(address & 0xff));
    }

    if (rm->flashPage[bank] >= 0) {
        return amdFlashRead(rm->flash, (address & 0x1fff) + 0x2000 * rm->flashPage[bank]);
    }

    return rm->romData[rm->romMapper[2] * 0x2000 + (address & 0x1fff)];
}

static UInt8 peek(RomMapperMegaFlashRomScc* rm, UInt16 address) 
{
    int bank = address / 0x2000;

    address += 0x4000;

    if (address >= 0x9800 && address < 0xa000 && rm->sccEnable) {
        return sccPeek(rm->scc, (UInt8)(address & 0xff));
    }

    if (rm->flashPage[bank] >= 0) {
        return amdFlashRead(rm->flash, (address & 0x1fff) + 0x2000 * rm->flashPage[bank]);
    }

    return rm->romData[rm->romMapper[2] * 0x2000 + (address & 0x1fff)];
}

static void write(RomMapperMegaFlashRomScc* rm, UInt16 address, UInt8 value) 
{
    int change = 0;
    int bank;

    address += 0x4000;
    if (address >= 0x9800 && address < 0xa000 && rm->sccEnable) {
        sccWrite(rm->scc, address & 0xff, value);
    }
    address -= 0x4000;

    bank = address >> 13;

    if (rm->flashPage[bank] >= 0) {
        amdFlashWrite(rm->flash, (address & 0x1fff) + 0x2000 * rm->flashPage[bank], value);
    }

    if ((address - 0x1000) & 0x1800) {
        return;
    }

    if (bank == 2) {
        int newEnable = (value & 0x3F) == 0x3F;
        change = rm->sccEnable != newEnable;
        rm->sccEnable = newEnable;
    }

    value &= rm->romMask;
    if (rm->romMapper[bank] != value || change) {
        mapPage(rm, bank, value);
    }
}

static UInt8 ioRead(RomMapperMegaFlashRomScc* rm, UInt16 ioPort)
{
    return ay8910ReadData(rm->ay8910, ioPort);
}

static void ioWrite(RomMapperMegaFlashRomScc* rm, UInt16 ioPort, UInt8 value)
{
    if ((ioPort & 3) == 0) {
        ay8910WriteAddress(rm->ay8910, ioPort, value);
    }
    if ((ioPort & 3) == 1) {
        ay8910WriteData(rm->ay8910, ioPort, value);
    }
}

static void getDebugInfo(RomMapperMegaFlashRomScc* rm, DbgDevice* dbgDevice)
{
    DbgIoPorts* ioPorts;

    ioPorts = dbgDeviceAddIoPorts(dbgDevice, "AY8910", 3);

    dbgIoPortsAddPort(ioPorts, 0, 0x10, DBG_IO_WRITE, 0xff);
    dbgIoPortsAddPort(ioPorts, 1, 0x11, DBG_IO_WRITE, 0xff);
    dbgIoPortsAddPort(ioPorts, 2, 0x12, DBG_IO_READ,  peek(rm, 0x12));
}

int romMapperMegaFlashRomSccCreate(const char* filename, UInt8* romData, 
                                   int size, int slot, int sslot, int startPage, UInt32 writeProtectMask, 
                                   int flashSize, int hasPsg) 
{
    DeviceCallbacks callbacks = { destroy, reset, saveState, loadState };
    DebugCallbacks dbgCallbacks = { getDebugInfo, NULL, NULL, NULL };
    RomMapperMegaFlashRomScc* rm;
    int i;

    rm = calloc(1, sizeof(RomMapperMegaFlashRomScc));

    rm->deviceHandle = deviceManagerRegister(hasPsg ? ROM_MEGAFLSHSCCPLUS : ROM_MEGAFLSHSCC, &callbacks, rm);
    rm->debugHandle = debugDeviceRegister(DBGTYPE_AUDIO, "AY8910", &dbgCallbacks, rm);
    slotRegister(slot, sslot, startPage, 4, read, peek, write, destroy, rm);

    if (size >= flashSize) {
        size = flashSize;
    }
    
    rm->romData = malloc(flashSize);
    memset(rm->romData, 0xff, flashSize);
    memcpy(rm->romData, romData, size);
    rm->size = 0x80000;
    rm->slot  = slot;
    rm->sslot = sslot;
    rm->romMask = flashSize / 0x2000 - 1;
    rm->startPage  = startPage;
    rm->scc = sccCreate(boardGetMixer());
    sccSetMode(rm->scc, SCC_REAL);
    rm->sccEnable = 0;
    if (hasPsg) {
        rm->ay8910 = ay8910Create(boardGetMixer(), AY8910_MSX, PSGTYPE_AY8910, 0, NULL);
    }

    rm->flash = amdFlashCreate(AMD_TYPE_2, flashSize, 0x10000, writeProtectMask, romData, size, sramCreateFilenameWithSuffix(filename, "", ".sram"), 1);

    for (i = 0; i < 4; i++) {   
        mapPage(rm, i, i);
    }
    
    if (hasPsg) {
        ioPortRegister(0x10, NULL, ioWrite, rm);
        ioPortRegister(0x11, NULL, ioWrite, rm);
        ioPortRegister(0x12, ioRead, NULL, rm);
    }

    return 1;
}
