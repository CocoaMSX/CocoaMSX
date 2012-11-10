/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Utils/IsFileExtension.c,v $
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
#include "IsFileExtension.h"
#include "StrcmpNoCase.h"
#include <string.h>
#include <stdlib.h>

int isFileExtension(const char* fileName, char* extension) {
    int flen = strlen(fileName);
    int elen = strlen(extension);

    if (elen > flen) {
        return 0;
    }

    return 0 == strcmpnocase(fileName + flen - elen, extension);
}