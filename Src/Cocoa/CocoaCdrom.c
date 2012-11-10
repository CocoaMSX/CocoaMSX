/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Sdl/SdlCdrom.c,v $
**
** $Revision: 73 $
**
** $Date: 2012-10-19 17:10:16 -0700 (Fri, 19 Oct 2012) $
**
** More info: http://www.bluemsx.com
**
** Copyright (C) 2003-2007 Daniel Vik, white cat
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
#include "ArchCdrom.h"
#include "ScsiDefs.h"
#include <stdlib.h>

void archCdromDestroy(ArchCdrom* cdrom) {}
void archCdromHwReset(ArchCdrom* cdrom) {}
void archCdromBusReset(ArchCdrom* cdrom) {}
void archCdromDisconnect(ArchCdrom* cdrom) {}
void archCdromLoadState(ArchCdrom* cdrom) {}
void archCdromSaveState(ArchCdrom* cdrom) {}

ArchCdrom* archCdromCreate(CdromXferCompCb xferCompCb, void* ref) {
    return NULL;
}

int archCdromExecCmd(ArchCdrom* cdrom, const UInt8* cdb, UInt8* buffer, int bufferSize)
{
    return 0;
}

int archCdromIsXferComplete(ArchCdrom* cdrom, int* transferLength)
{
    *transferLength = 0;
    return 1;
}

UInt8 archCdromGetStatusCode(ArchCdrom* cdrom)
{
    return SCSIST_CHECK_CONDITION;
}

int archCdromGetSenseKeyCode(ArchCdrom* cdrom)
{
    return SENSE_INVALID_COMMAND_CODE;
}

void* archCdromBufferMalloc(size_t size)
{
    return calloc(1, size);
}

void  archCdromBufferFree(void* ptr)
{
    free(ptr);
}
