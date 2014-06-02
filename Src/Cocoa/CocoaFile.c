/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Sdl/SdlFile.c,v $
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
#include "ArchFile.h"

#include <stdlib.h>
#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>


int archCreateDirectory(const char* pathname)
{
    return mkdir(pathname, 0777);
}

const char* archGetCurrentDirectory()
{
    static char buf[512];
    return getcwd(buf, sizeof(buf));
}

void archSetCurrentDirectory(const char* pathname)
{
    chdir(pathname);
}

int archFileExists(const char* fileName)
{
    struct stat s;
    return stat(fileName, &s) == 0;
}

int archFileDelete(const char *fileName)
{
    return remove(fileName) == 0;
}

/* File dialogs: */
char* archFilenameGetOpenRom(Properties* properties, int cartSlot, RomType* romType) { return NULL; }
char* archFilenameGetOpenDisk(Properties* properties, int drive, int allowCreate) { return NULL; }
char* archFilenameGetOpenHarddisk(Properties* properties, int drive, int allowCreate) { return NULL; }
char* archFilenameGetOpenCas(Properties* properties) { return NULL; }
char* archFilenameGetSaveCas(Properties* properties, int* type) { return NULL; }
char* archFilenameGetOpenState(Properties* properties) { return NULL; }
char* archFilenameGetOpenCapture(Properties* properties) { return NULL; }
char* archFilenameGetSaveState(Properties* properties) { return NULL; }
char* archDirnameGetOpenDisk(Properties* properties, int drive) { return NULL; }
char* archFilenameGetOpenRomZip(Properties* properties, int cartSlot, const char* fname, const char* fileList, int count, int* autostart, int* romType) { return NULL; }
char* archFilenameGetOpenDiskZip(Properties* properties, int drive, const char* fname, const char* fileList, int count, int* autostart) { return NULL; }
char* archFilenameGetOpenCasZip(Properties* properties, const char* fname, const char* fileList, int count, int* autostart) { return NULL; }
char* archFilenameGetOpenAnyZip(Properties* properties, const char* fname, const char* fileList, int count, int* autostart, int* romType) { return NULL; }

