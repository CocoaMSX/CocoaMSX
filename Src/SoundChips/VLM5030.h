/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/SoundChips/VLM5030.h,v $
**
** $Revision: 1.6 $
**
** $Date: 2008-03-30 18:38:45 $
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
#ifndef VLM5030_H
#define VLM5030_H

#include "MsxTypes.h"
#include "AudioMixer.h"

/* Type definitions */
typedef struct VLM5030 VLM5030;

/* Constructor and destructor */
VLM5030* vlm5030Create(Mixer* mixer, UInt8* voiceData, int length);
void vlm5030Destroy(VLM5030* vlm5030);
void vlm5030Reset(VLM5030* vlm5030);
void vlm5030LoadState(VLM5030* vlm5030);
void vlm5030SaveState(VLM5030* vlm5030);
UInt8 vlm5030Peek(VLM5030* vlm5030, UInt16 ioPort);
UInt8 vlm5030Read(VLM5030* vlm5030, UInt16 ioPort);
void vlm5030Write(VLM5030* vlm5030, UInt16 ioPort, UInt8 value);

#endif
