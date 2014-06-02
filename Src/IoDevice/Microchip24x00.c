/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/IoDevice/Microchip24x00.c,v $
**
** $Revision: 1.4 $
**
** $Date: 2008-03-30 18:38:40 $
**
** More info: http://www.bluemsx.com
**
** Copyright (C) 2003-2014 Daniel Vik
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
#include "Microchip24x00.h"
#include "Board.h"
#include "SaveState.h"
#include "sramLoader.h"
#include <stdlib.h>
#include <string.h>

typedef struct Microchip24x00
{
    UInt8* romData;
    int    romMask;
    int    addressSize;

    MicroshipDeviceType deviceType;
    int scl;
    int sda;
    int phase;
    int counter;
    int command;
    int address;
    int data;
    int isWriting;
    UInt32 timeWriting;
    UInt8 writeBuffer[256];
    int writeBufferMask;
    int writeCounter;

    BoardTimer* timer;
    
    char sramFilename[512];
};

#define PHASE_IDLE        0
#define PHASE_COMMAND     1
#define PHASE_ADDRESS_HI  2
#define PHASE_ADDRESS_LO  3
#define PHASE_WRITE       4
#define PHASE_READ        5


static int getSize(MicroshipDeviceType deviceType) {
    switch (deviceType) {
    case AT24C01:
        return 128;
    case AT24C02:
        return 256;
    case AT24C04:
        return 512;
    case AT24C08:
        return 1024;
    case AT24C16:
        return 2048;
    case AT24C128:
        return 16384;
    case AT24C256:
        return 32768;
    case M24xx64:
        return 8192;
    }
    return 0;
}

static int getWriteBufferSize(MicroshipDeviceType deviceType) {
    switch (deviceType) {
    case AT24C01:
    case AT24C02:
        return 8;
    case AT24C04:
    case AT24C08:
    case AT24C16:
        return 16;
    case AT24C128:
    case AT24C256:
        return 64;
    case M24xx64:
        return 32;
    }
    return 0;
}

static int getAddress(MicroshipDeviceType deviceType, int command, int address) {
    switch (deviceType) {
    case AT24C01:
        return address & 0x7f;
    case AT24C02:
        return address & 0xff;
    case AT24C04:
        return (address & 0xff) | ((command & 0x02) << 7);
    case AT24C08:
        return (address & 0xff) | ((command & 0x06) << 7);
    case AT24C16:
        return (address & 0xff) | ((command & 0x0e) << 7);
    case AT24C128:
        return address & 0x3fff;
    case AT24C256:
        return address & 0x7fff;
    case M24xx64:
        return address & 0x1fff;
    }
    return 0;
}

static int getAddressSize(MicroshipDeviceType deviceType) {
    switch (deviceType) {
    case AT24C01:
    case AT24C02:
    case AT24C04:
    case AT24C08:
    case AT24C16:
        return 8;
    case AT24C128:
    case AT24C256:
        return 16;
    case M24xx64:
        return 16;
    }
    return 0;
}



static void onTimer(Microchip24x00* rm, UInt32 time)
{
    rm->isWriting = 0;
}

Microchip24x00* microchip24x00Create(MicroshipDeviceType deviceType, const char* sramFilename)
{
    int size = getSize(deviceType);
    Microchip24x00* rm = calloc(1, sizeof(Microchip24x00));

    rm->deviceType = deviceType;
    rm->addressSize = getAddressSize(deviceType);
    rm->writeBufferMask = getWriteBufferSize(deviceType) - 1;
    // Allocate memory
    rm->romMask = size - 1;
    rm->romData = malloc(size);
    memset(rm->romData, 0xff, size);

    // Load rom data if present
    if (sramFilename != NULL) {
        strcpy(rm->sramFilename, sramFilename);
        sramLoad(rm->sramFilename, rm->romData, rm->romMask + 1, NULL, 0);
    }

    rm->timer = boardTimerCreate(onTimer, rm);

    microchip24x00Reset(rm);

    return rm;
}

void microchip24x00Destroy(Microchip24x00* rm)
{
    if (rm->sramFilename[0]) {
        sramSave(rm->sramFilename, rm->romData, rm->romMask + 1, NULL, 0);
    }

    boardTimerDestroy(rm->timer);

    free(rm->romData);
    free(rm);
}

void microchip24x00Reset(Microchip24x00* rm)
{
    rm->scl = 0;
    rm->sda = 0;
    rm->phase = PHASE_IDLE;
    rm->counter = 0;
    rm->command = 0;
    rm->address = 0;
    rm->data = 0;
    rm->writeCounter = 0;
    rm->isWriting = 0;
    rm->timeWriting = 0;
}

void microchip24x00SaveState(Microchip24x00* rm)
{
    SaveState* state = saveStateOpenForWrite("Microchip24x00");

    saveStateSet(state, "scl",           rm->scl);
    saveStateSet(state, "sda",           rm->sda);
    saveStateSet(state, "phase",            rm->phase);
    saveStateSet(state, "counter",          rm->counter);
    saveStateSet(state, "command",          rm->command);
    saveStateSet(state, "address",          rm->address);
    saveStateSet(state, "data",             rm->data);
    saveStateSet(state, "isWriting",        rm->isWriting);
    saveStateSet(state, "writeCounter",     rm->isWriting);
    saveStateSet(state, "writeBufferMask",  rm->writeBufferMask);
    saveStateSet(state, "timeWriting",      rm->timeWriting);

    saveStateSetBuffer(state, "writeBuffer", rm->writeBuffer, sizeof(rm->writeBuffer));

    saveStateClose(state);
}

void microchip24x00LoadState(Microchip24x00* rm)
{
    SaveState* state = saveStateOpenForRead("Microchip24x00");

    rm->scl             = saveStateGet(state, "scl",             0);
    rm->sda             = saveStateGet(state, "sda",             0);
    rm->phase           = saveStateGet(state, "phase",           0);
    rm->counter         = saveStateGet(state, "counter",         0);
    rm->command         = saveStateGet(state, "command",         0);
    rm->address         = saveStateGet(state, "address",         0);
    rm->data            = saveStateGet(state, "data",            0);
    rm->writeCounter    = saveStateGet(state, "writeCounter",    0);
    rm->writeBufferMask = saveStateGet(state, "writeBufferMask", 0);
    rm->timeWriting     = saveStateGet(state, "timeWriting",     0);

    saveStateGetBuffer(state, "writeBuffer", rm->writeBuffer, sizeof(rm->writeBuffer));

    saveStateClose(state);

    if (rm->isWriting) {
        boardTimerAdd(rm->timer, rm->timeWriting);
    }
}

void microchip24x00SetScl(Microchip24x00* rm, int value)
{
    int change;

    value = value ? 1 : 0;
    change = rm->scl ^ value;
    rm->scl = value;

    if (!change) {
        return;
    }

    if (!value) {
        return;
    }

    if (rm->phase == PHASE_IDLE) {
        return;
    }

    if (rm->counter++ < 8) {
        if (rm->phase == PHASE_READ) {
            rm->sda = (rm->data >> 7) & 1;
            rm->data <<= 1;
        }
        else {
            rm->data <<= 1;
            rm->data |= rm->sda;
        }
        return;
    }

    rm->counter = 0;

    switch (rm->phase) {
    case PHASE_COMMAND:
        rm->command = rm->data & 0xff;
        if (rm->isWriting || (rm->command & 0xf0) != 0xa0) {
            rm->phase = PHASE_IDLE;
        }
        else {
            if (rm->command & 1) {
                rm->phase = PHASE_READ;
                rm->data = rm->romData[rm->address];
                rm->address = (rm->address + 1) & rm->romMask;
            }
            else {
                if (rm->addressSize == 8) {
                    rm->phase = PHASE_ADDRESS_LO;
                }
                else {
                    rm->phase = PHASE_ADDRESS_HI;
                }
            }
            rm->sda = 0;
        }
        break;
    case PHASE_ADDRESS_HI:
        // Do nothing here. 
        // Save address when both address bytes are written
        rm->phase = PHASE_ADDRESS_LO;
        rm->sda = 0;
        break;
    case PHASE_ADDRESS_LO:
        rm->address = getAddress(rm->deviceType, rm->command, rm->data);
        rm->phase = PHASE_WRITE;
        rm->sda = 0;
        break;
    case PHASE_WRITE:
        rm->writeBuffer[rm->writeCounter & rm->writeBufferMask] = rm->data & 0xff;
        rm->writeCounter++;
        rm->sda = 0;
        break;
    case PHASE_READ:
        rm->data = rm->romData[rm->address];
        rm->address = (rm->address + 1) & rm->romMask;
        break;
    }
}

void microchip24x00SetSda(Microchip24x00* rm, int value)
{
    int change;
    value = value ? 1 : 0;
    change = rm->sda ^ value;
    rm->sda = value;

    if (!rm->scl || !change) {
        return;
    }

    if (value) {
        if (rm->phase == PHASE_WRITE && rm->counter == 1) {
            int i;
            for (i = 0; i < rm->writeCounter; i++) {
                rm->romData[rm->address] = rm->writeBuffer[i];
                rm->address = ((rm->address & ~rm->writeBufferMask) | 
                    ((rm->address + 1) & rm->writeBufferMask)) & rm->romMask;
            }
            if (rm->writeCounter > 0) {
                rm->timeWriting = boardSystemTime() + boardFrequency() * 3 / 1000;
                boardTimerAdd(rm->timer, rm->timeWriting);
                rm->isWriting = 1;
            }
        }
        rm->phase = PHASE_IDLE;
    }
    else {
        // Start
        rm->phase = PHASE_COMMAND;
        rm->writeCounter = 0;
        rm->counter = 0;
    }
}

int microchip24x00GetSda(Microchip24x00* rm) {
    return rm->sda;
}

int microchip24x00GetScl(Microchip24x00* rm) {
    return rm->scl;
}
