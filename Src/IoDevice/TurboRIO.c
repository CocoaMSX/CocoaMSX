/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/IoDevice/TurboRIO.c,v $
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
#include "TurboRIO.h"
#include "IoPort.h"
#include "Board.h"
#include "Led.h"
#include "Switches.h"
#include "DeviceManager.h"
#include "DebugDeviceManager.h"
#include "Language.h"
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>


typedef struct TurboRIO {
    int deviceHandle;
    int debugHandle;
} TurboRIO;

static void write(TurboRIO* turboRIO, UInt16 ioPort, UInt8 value)
{
	ledSetPause(value & 0x01);
	ledSetTurboR(value & 0x80);
}

static UInt8 read(TurboRIO* turboRIO, UInt16 ioPort)
{
    return switchGetPause() ? 1 : 0;
}

static void destroy(TurboRIO* turboRIO)
{
    ioPortUnregister(0xa7);

    debugDeviceUnregister(turboRIO->debugHandle);
    deviceManagerUnregister(turboRIO->deviceHandle);

    free(turboRIO);
}

static void getDebugInfo(TurboRIO* turboRIO, DbgDevice* dbgDevice)
{
    DbgIoPorts* ioPorts;

    ioPorts = dbgDeviceAddIoPorts(dbgDevice, langDbgDevTrPause(), 1);
    dbgIoPortsAddPort(ioPorts, 0, 0xa7, DBG_IO_READWRITE, read(turboRIO, 0xa7));
}

int romMapperTurboRIOCreate()
{
    DeviceCallbacks callbacks = { (DeviceCallback)destroy, NULL, NULL, NULL };
    DebugCallbacks dbgCallbacks = { (void(*)(void*,DbgDevice*))getDebugInfo, NULL, NULL, NULL };

    TurboRIO* turboRIO = (TurboRIO*)calloc(1, sizeof(TurboRIO));

    turboRIO->deviceHandle = deviceManagerRegister(ROM_TURBORIO, &callbacks, turboRIO);
    turboRIO->debugHandle = debugDeviceRegister(DBGTYPE_PORT, langDbgDevTrPause(), &dbgCallbacks, turboRIO);

    ioPortRegister(0xa7, (IoPortRead)read, (IoPortWrite)write, turboRIO);

    return 1;
}
