/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/romMapperSvi707Fdc.c,v $
**
** $Revision: 1.0 $
**
** $Date: 2008-03-30 18:38:44 $
**
** More info: http://www.bluemsx.com
**
** Copyright (C) 2003-2006 Daniel Vik, Tomas Karlsson
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
#include "romMapperSvi707Fdc.h"
#include "WD2793.h"
#include "Led.h"
#include "MediaDb.h"
#include "RomLoader.h"
#include "Disk.h"
#include "SlotManager.h"
#include "DeviceManager.h"
#include "SaveState.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

typedef struct {
    int deviceHandle;
    UInt8* romData;
    UInt8* romDataCpm;
    UInt8* romDataMsx;
    WD2793* fdc;
    int slot;
    int sslot;
    int startPage;
    UInt8 drvSelect;
    UInt8 toCpm;
    UInt8 toMsx;
} RomMapperSvi707Fdc;

static void saveState(RomMapperSvi707Fdc* rm)
{
    SaveState* state = saveStateOpenForWrite("mapperSvi707Fdc");

    saveStateSet(state, "drvSelect",  rm->drvSelect);
    
    saveStateClose(state);

    wd2793SaveState(rm->fdc);
}

static void loadState(RomMapperSvi707Fdc* rm)
{
    SaveState* state = saveStateOpenForRead("mapperSvi707Fdc");

    rm->drvSelect  = (UInt8)saveStateGet(state, "drvSelect",  0);

    saveStateClose(state);

    wd2793LoadState(rm->fdc);
}

static void destroy(RomMapperSvi707Fdc* rm)
{
    slotUnregister(rm->slot, rm->sslot, rm->startPage);
    deviceManagerUnregister(rm->deviceHandle);

    wd2793Destroy(rm->fdc);

    free(rm->romData);
    free(rm->romDataCpm);
    free(rm->romDataMsx);
    free(rm);
}

static UInt8 read(RomMapperSvi707Fdc* rm, UInt16 address) 
{
    switch (address & 0x3fff) {
        case 0x3fb8:
            return wd2793GetStatusReg(rm->fdc);
        case 0x3fb9:
            return wd2793GetTrackReg(rm->fdc);
        case 0x3fba:
            return wd2793GetSectorReg(rm->fdc);
        case 0x3fbb:
            return wd2793GetDataReg(rm->fdc);
        case 0x3fbc:
            return (wd2793GetIrq(rm->fdc)?0x80:0) | (wd2793GetDataRequest(rm->fdc)?0:0x40);
        case 0x3fbd:
            return 0xff;
        case 0x3fbe:
            return 0xff;
        case 0x3fbf:
            return 0xff;
    }
    return address < 0x4000 ? rm->romData[address] : 0xff;
}

static UInt8 peek(RomMapperSvi707Fdc* rm, UInt16 address) 
{
    switch (address & 0x3fff) {
        case 0x3fb8:
            return 0xff; // Get from fdc
        case 0x3fb9:
            return 0xff; // Get from fdc
        case 0x3fba:
            return 0xff; // Get from fdc
        case 0x3fbb:
            return 0xff; // Get from fdc
        case 0x3fbc:
            return 0xff; // Get from fdc
        case 0x3fbd:
            return 0xff;
        case 0x3fbe:
            return rm->toCpm;
        case 0x3fbf:
            return rm->toMsx;
    }
    return address < 0x4000 ? rm->romData[address] : 0xff;
}

static void write(RomMapperSvi707Fdc* rm, UInt16 address, UInt8 value) 
{
    switch (address & 0x3fff) {
        case 0x3fb8:
            wd2793SetCommandReg(rm->fdc, value);
            break;
        case 0x3fb9:
            wd2793SetTrackReg(rm->fdc, value);
            break;
        case 0x3fba:
            wd2793SetSectorReg(rm->fdc, value);
            break;
        case 0x3fbb:
            wd2793SetDataReg(rm->fdc, value);
            break;
        case 0x3fbc:
            rm->drvSelect = value & 0x3f;
            wd2793SetSide(rm->fdc, value & 4);
            wd2793SetMotor(rm->fdc, value & 8);
            if (diskEnabled(0)) ledSetFdd1(value & 1);
            if (diskEnabled(1)) ledSetFdd2(value & 2);
            switch (value & 3) {
                case 1:
                    wd2793SetDrive(rm->fdc, 0);
                    break;
                case 2:
                    wd2793SetDrive(rm->fdc, 1);
                    break;
                default:
                    wd2793SetDrive(rm->fdc, -1);
            }
            break;
        case 0x3fbe:    // Set CP/M boot ROM
            rm->toCpm = value;
            memcpy(rm->romData, rm->romDataCpm, 0x4000);
            break;
        case 0x3fbf:    // Set MSX ROM
            rm->toMsx = value;
            memcpy(rm->romData, rm->romDataMsx, 0x4000);
            break;
    }
}       

static void reset(RomMapperSvi707Fdc* rm)
{
    wd2793Reset(rm->fdc);
    write(rm, 0xffc, 0);
    write(rm, 0xffd, 0);
}

int romMapperSvi707FdcCreate(const char* filename, UInt8* romData, 
                              int size, int slot, int sslot, int startPage) 
{
    DeviceCallbacks callbacks = { destroy, reset, saveState, loadState };
    RomMapperSvi707Fdc* rm;
    int pages = 4;
    int i;
    int sizeMsx = 0;
    UInt8* bufMsx;

    if ((startPage + pages) > 8) {
        return 0;
    }

    if (size != 0x4000) {
        return 0;
    }

    bufMsx = romLoad("Machines/Shared Roms/svi707msx.rom", NULL, &sizeMsx);
    if (bufMsx == NULL) {
        return 0;
    }
    if (sizeMsx != 0x4000) {
        free(bufMsx);
        return 0;
    }

    rm = malloc(sizeof(RomMapperSvi707Fdc));

    rm->deviceHandle = deviceManagerRegister(ROM_SVI707FDC, &callbacks, rm);
    slotRegister(slot, sslot, startPage, pages, read, peek, write, destroy, rm);

    rm->romData = malloc(size);
    rm->romDataCpm = malloc(size);
    rm->romDataMsx = malloc(sizeMsx);
    memcpy(rm->romData, romData, size);
    memcpy(rm->romDataCpm, romData, size);
    memcpy(rm->romDataMsx, bufMsx, sizeMsx);
    free(bufMsx);

    rm->slot  = slot;
    rm->sslot = sslot;
    rm->startPage  = startPage;

    for (i = 0; i < pages; i++) {
        slotMapPage(slot, sslot, i + startPage, NULL, 0, 0);
    }

    rm->fdc = wd2793Create(FDC_TYPE_WD2793);

    reset(rm);

    return 1;
}
