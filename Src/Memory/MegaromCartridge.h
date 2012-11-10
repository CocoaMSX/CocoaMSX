/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/MegaromCartridge.h,v $
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
#ifndef MEGAROM_CARTRIDGE_H
#define MEGAROM_CARTRIDGE_H

#include "MsxTypes.h"
#include "MediaDb.h"
#include "YM2413.h"

void cartridgeSetSlotInfo(int cartNo, int slot, int sslot);

int cartridgeInsert(int cartNo, RomType romType, char* cart, char* cartZip);

#endif
