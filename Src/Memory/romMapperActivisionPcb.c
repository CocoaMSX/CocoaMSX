/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/romMapperActivisionPcb.c,v $
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
#include "romMapperActivisionPcb.h"
#include "Microchip24x00.h"
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
    int slot;
    int sslot;
    int startPage;
    UInt32 romMask;
    UInt16 latch;
    int romMapper;

    Microchip24x00* eeprom;
} RomMapperActivisionPcb;

static void slotSetMapper(RomMapperActivisionPcb* rm, int romMapper)
{
    rm->romMapper = romMapper & rm->romMask;
    slotMapPage(rm->slot, rm->sslot, rm->startPage + 2, rm->romData + 0x0000 + (rm->romMapper << 14), 0, 0);
    slotMapPage(rm->slot, rm->sslot, rm->startPage + 3, rm->romData + 0x2000 + (rm->romMapper << 14), 0, 0);
}

static void saveState(RomMapperActivisionPcb* rm)
{
    SaveState* state = saveStateOpenForWrite("mapperActivisionPcb");
    saveStateSet(state, "romMapper",  rm->romMapper);
    saveStateSet(state, "latch",      rm->latch);
    saveStateClose(state);

    if (rm->eeprom != NULL) {
        microchip24x00SaveState(rm->eeprom);
    }
}

static void loadState(RomMapperActivisionPcb* rm)
{
    SaveState* state = saveStateOpenForRead("mapperActivisionPcb");
    rm->romMapper = (UInt8)saveStateGet(state, "romMapper",  1);
    rm->latch     = (UInt8)saveStateGet(state, "latch",      0);
    slotSetMapper(rm, rm->romMapper);
    
    if (rm->eeprom != NULL) {
        microchip24x00LoadState(rm->eeprom);
    }
}

static void destroy(RomMapperActivisionPcb* rm)
{
    slotUnregister(rm->slot, rm->sslot, rm->startPage);
    deviceManagerUnregister(rm->deviceHandle);
    if (rm->eeprom != NULL) {
        microchip24x00Destroy(rm->eeprom);
    }
    free(rm->romData);
    free(rm);
}

static void reset(RomMapperActivisionPcb* rm)
{
    slotSetMapper(rm, 1);
}

static void write(RomMapperActivisionPcb* rm, UInt16 address, UInt8 value) 
{
    int hotspot;

    // Only one 16kB page is mapped to this read method, so the mask just removes high bits.
    address &= 0x3fff;

    if (address < 0x3f80) {
        return;
    }

    hotspot = (address >> 4) & 7;
    switch (hotspot) {
    case 0:
        break;
    case 1:
    case 2:
    case 3:
        slotSetMapper(rm, hotspot & 3);
        break;
    case 4:
    case 5:
        if (rm->eeprom != NULL) {
            microchip24x00SetScl(rm->eeprom, hotspot & 1);
        }
        break;
    case 6:
    case 7:
        if (rm->eeprom != NULL) {
            microchip24x00SetSda(rm->eeprom, hotspot & 1);
        }
        break;
    }
}

static UInt8 read(RomMapperActivisionPcb* rm, UInt16 address) 
{
    int hotspot;
    int latch = rm->latch;

    rm->latch = address;
    // Only one 16kB page is mapped to this read method, so the mask just removes high bits.
    address &= 0x3fff;

    if (latch >= 0xa000 || address < 0x3f80) {
        return rm->romData[(rm->romMapper << 14) + address];
    }

    hotspot = (address >> 4) & 7;
    switch (hotspot) {
    case 0:
        if (rm->eeprom != NULL) {
            return microchip24x00GetSda(rm->eeprom);
        }
    case 1:
    case 2:
    case 3:
        return rm->romMapper;
    case 4:
    case 5:
    case 6:
    case 7:
        return hotspot & 1;
    }

    return 0;
}

static UInt8 peek(RomMapperActivisionPcb* rm, UInt16 address) 
{
    int hotspot;

    // Only one 16kB page is mapped to this read method, so the mask just removes high bits.
    address &= 0x3fff;

    if (address < 0x3f80) {
        return rm->romData[(rm->romMapper << 14) + address];
    }
    hotspot = (address >> 4) & 7;
    switch (hotspot) {
    case 0:
        if (rm->eeprom != NULL) {
            return microchip24x00GetSda(rm->eeprom);
        }
    case 1:
    case 2:
    case 3:
        return rm->romMapper == hotspot ? 1 : 0;
    case 4:
    case 5:
    case 6:
    case 7:
        return hotspot & 1;
    }

    return 0;
}

int romMapperActivisionPcbCreate(const char* filename, int romType, UInt8* romData, 
                                 int size, int slot, int sslot, 
                                 int startPage) 
{
    DeviceCallbacks callbacks = { destroy, reset, saveState, loadState };
    RomMapperActivisionPcb* rm;
    
    if (size & 0x3fff) {
        return 0;
    }
    
    rm = malloc(sizeof(RomMapperActivisionPcb));

    rm->deviceHandle = deviceManagerRegister(romType, &callbacks, rm);
    slotRegister(slot, sslot, startPage, 4, read, peek, write, destroy, rm);

    rm->romData = calloc(1, size);
    memcpy(rm->romData, romData, size);
    rm->romMask = size / 0x4000 - 1;
    rm->slot  = slot;
    rm->sslot = sslot;
    rm->startPage  = startPage;
    rm->romMapper = 1;
    if (romType == ROM_ACTIVISIONPCB) {
        rm->eeprom = NULL;
    }
    else {
        rm->eeprom = microchip24x00Create(
            romType == ROM_ACTIVISIONPCB_2K ? AT24C02 :
            (romType == ROM_ACTIVISIONPCB_16K ? AT24C16 : AT24C256), sramCreateFilename(filename));
    }
    slotMapPage(rm->slot, rm->sslot, rm->startPage + 0, rm->romData + 0x0000, 1, 0);
    slotMapPage(rm->slot, rm->sslot, rm->startPage + 1, rm->romData + 0x2000, 1, 0);
    slotMapPage(rm->slot, rm->sslot, rm->startPage + 2, rm->romData + 0x0000 + (rm->romMapper << 14), 0, 0);
    slotMapPage(rm->slot, rm->sslot, rm->startPage + 3, rm->romData + 0x2000 + (rm->romMapper << 14), 0, 0);

    reset(rm);

    return 1;
}

