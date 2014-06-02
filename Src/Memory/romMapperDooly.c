/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/romMapperNormal.c,v $
**
** $Revision: 1.11 $
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
#include "romMapperDooly.h"
#include "MediaDb.h"
#include "SlotManager.h"
#include "DeviceManager.h"
#include "SaveState.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>


typedef struct {
    int deviceHandle;
    UInt8* romData;
    int slot;
    int sslot;
    int startPage;
    UInt8 conversion;
} RomMapperDooly;

static void loadState(RomMapperDooly* rm)
{
    SaveState* state = saveStateOpenForRead("mapperDooly");
    rm->conversion = (UInt8)saveStateGet(state, "conversion", 0);
    saveStateClose(state);
}

static void saveState(RomMapperDooly* rm)
{
    SaveState* state = saveStateOpenForWrite("mapperDooly");
    saveStateSet(state, "conversion", rm->conversion);
    saveStateClose(state);
}

static void destroy(RomMapperDooly* rm)
{
    slotUnregister(rm->slot, rm->sslot, rm->startPage);
    deviceManagerUnregister(rm->deviceHandle);

    free(rm->romData);
    free(rm);
}

static UInt8 read(RomMapperDooly* rm, UInt16 address) 
{
    UInt8 value = rm->romData[address];
    switch (rm->conversion) {
    case 1:
        return (value & 0xf8) | (value << 2 & 0x04) | (value >> 1 & 0x03);
    case 4:
        return (value & 0xf8) | (value >> 2 & 0x01) | (value << 1 & 0x06);
    case 3:
    case 7:
        return value | 0x07;
    case 2:
    case 5:
    case 6:
        switch (value & 0x07) {
        case 1:
        case 2:
        case 4:
            return value & 0xf8;
        case 3:
        case 5:
        case 6:
            switch (rm->conversion) {
            case 2:
                return (value & 0xf8) | (((value << 2 & 0x04) | (value >> 1 & 0x03)) ^ 0x07);
            case 5:
                return value ^ 0x07;
            case 6:
                return (value & 0xf8) | (((value >> 2 & 0x01) | (value << 1 & 0x06)) ^ 0x07);
            }
        }
    }
    return value;
}

static void write(RomMapperDooly* rm, UInt16 address, UInt8 value) 
{
    if (address != 0x7f00) {
        rm->conversion = value & 0x07;
    }
}

static void reset(RomMapperDooly* rm)
{
    rm->conversion = 0;
}

int romMapperDoolyCreate(const char* filename, UInt8* romData, 
                         int size, int slot, int sslot, int startPage) 
{
    DeviceCallbacks callbacks = { destroy, reset, saveState, loadState };
    RomMapperDooly* rm;
    int i;

    rm = malloc(sizeof(RomMapperDooly));

    rm->deviceHandle = deviceManagerRegister(ROM_DOOLY, &callbacks, rm);
    slotRegister(slot, sslot, startPage, 4, read, read, write, destroy, rm);

    if (size > 0x8000) {
        size = 0x8000;
    }

    rm->romData = malloc(0x8000);
    memcpy(rm->romData, romData, size);

    rm->slot  = slot;
    rm->sslot = sslot;
    rm->startPage  = startPage;

    for (i = 0; i < 4; i++) {
        slotMapPage(slot, sslot, i + startPage, NULL, 0, 0);
    }

    reset(rm);

    return 1;
}
