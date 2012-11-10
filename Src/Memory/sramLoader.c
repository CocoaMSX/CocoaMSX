/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Memory/sramLoader.c,v $
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
#include "sramLoader.h"
#include "Board.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>



char* sramCreateFilenameWithSuffix(char* romFilename, char* suffix, char* ext)
{
    static char SRAMfileName[512];
    char fileName[512];
    char* dst = fileName + 512;
    char* src;

    *--dst = '\0';
    if (ext == NULL) {
        *--dst = 'm';
        *--dst = 'a';
        *--dst = 'r';
        *--dst = 's';
        *--dst = '.';
    }
    else {
        char* p = ext + strlen(ext);
        do {
            *--dst = *--p;
        } while (p != ext);
    }

    dst -= strlen(suffix);
    memcpy(dst, suffix, strlen(suffix));
    
    src = romFilename + strlen(romFilename);

    while (*src != '.' && src > romFilename) {
        src--;
    }
    src--;

    while (*src != '/' && *src != '\\' && src >= romFilename) {
        *--dst = *src--;
    }

    sprintf(SRAMfileName, "%s" DIR_SEPARATOR "%s", boardGetBaseDirectory(), dst);

    return SRAMfileName;
}


char* sramCreateFilename(char* romFilename) {
    return sramCreateFilenameWithSuffix(romFilename, "", NULL);
}
void sramLoad(char* filename, UInt8* sram, int length, void* header, int headerLength) {
    FILE* file;

    file = fopen(filename, "rb");
    if (file != NULL) {
        if (headerLength > 0) {
            char* readHeader[256];

            fread(readHeader, 1, headerLength, file);
            if (memcmp(readHeader, header, headerLength)) {
                fclose(file);
                return;
            }
        }
        fread(sram, 1, length, file);
        fclose(file);
    }
}

void sramSave(char* filename, UInt8* sram, int length, void* header, int headerLength) {
    FILE* file;

    file = fopen(filename, "wb");
    if (file != NULL) {
        if (headerLength > 0) {
            fwrite(header, 1, headerLength, file);
        }
        fwrite(sram, 1, length, file);
        fclose(file);
    }
}

