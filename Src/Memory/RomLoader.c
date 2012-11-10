/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/RomLoader.c,v $
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
#include "RomLoader.h"
#include "ziphelper.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// PacketFileSystem.h Need to be included after all other includes
#include "PacketFileSystem.h"


UInt8* romLoad(const char *fileName, const char *fileInZipFile, int* size)
{
    UInt8* buf = NULL;
    FILE *file;

    if (fileName == NULL || strlen(fileName) == 0) {
        return NULL;
    }

    if (fileInZipFile != NULL && strlen(fileInZipFile) == 0) {
        fileInZipFile = NULL;
    }

    if (fileInZipFile != NULL) {
        buf = zipLoadFile(fileName, fileInZipFile, size);
        return buf;
    }

    file = fopen(fileName, "rb");
    if (file == NULL) {
        return NULL;
    }

    fseek(file, 0, SEEK_END);
    *size = ftell(file);
    if (*size == 0) {
        fclose(file);
        return malloc(1);
    }

    fseek(file, 0, SEEK_SET);

    buf = malloc(*size);
    
    *size = fread(buf, 1, *size, file);
    fclose(file);

    return buf;
}

