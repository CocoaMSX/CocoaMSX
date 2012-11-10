/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Sdl/SdlGlob.c,v $
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
#include "ArchGlob.h"
#include <glob.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

ArchGlob* archGlob(const char* pattern, int flags)
{
    ArchGlob* globHandle;
    glob_t g;
    int rv;
    int i;

    rv = glob(pattern, GLOB_MARK, NULL, &g);
    if (rv != 0) {
        return NULL;
    }
    
    globHandle = (ArchGlob*)calloc(1, sizeof(ArchGlob));

    for (i = 0; i < g.gl_pathc; i++) {
        char* path = g.gl_pathv[i];
        int len = strlen(path);

        if ((flags & ARCH_GLOB_DIRS) && path[len - 1] == '/') {
            char* storePath = calloc(1, len);
            memcpy(storePath, path, len - 1);
            globHandle->count++;
            globHandle->pathVector = realloc(globHandle->pathVector, sizeof(char*) * globHandle->count);
            globHandle->pathVector[globHandle->count - 1] = storePath;
        }

        if ((flags & ARCH_GLOB_FILES) && path[len - 1] != '/') {
            char* storePath = calloc(1, len + 1);
            memcpy(storePath, path, len);
            globHandle->count++;
            globHandle->pathVector = realloc(globHandle->pathVector, sizeof(char*) * globHandle->count);
            globHandle->pathVector[globHandle->count - 1] = storePath;
        }
    }

    globfree(&g);

    return globHandle;
}

void archGlobFree(ArchGlob* globHandle)
{
    int i;

    if (globHandle == NULL) {
        return;
    }
    
    for (i = 0; i < globHandle->count; i++) {
        free(globHandle->pathVector[i]);
    }
    if (globHandle->pathVector != NULL) {
        free(globHandle->pathVector);
    }
    free(globHandle);
}
