/*****************************************************************************
** File:        msxTypes.h
**
** Author:      Daniel Vik
**
** Description: Type definitions
**
** More info:   www.bluemsx.com
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
#ifndef BLUEMSX_TYPES
#define BLUEMSX_TYPES

#ifdef __cplusplus
extern "C" {
#endif


#ifdef __GNUC__
#define __int64 long long
#endif

#ifdef _WIN32
#define DIR_SEPARATOR "\\"
#else
#define DIR_SEPARATOR "/"
#endif

/* Define double type for different targets
 */
#if defined(__x86_64__) || defined(__i386__) || defined _WIN32
typedef double DoubleT;
#else
typedef float DoubleT;
#endif


/* So far, only support for MSVC types
 */
typedef unsigned char    UInt8;
#ifndef __MACTYPES__
typedef unsigned short   UInt16;
typedef unsigned int     UInt32;
typedef unsigned __int64 UInt64;
#endif
typedef signed   char    Int8;
typedef signed   short   Int16;
typedef signed   int     Int32;

// Define color stuff

#if PIXEL_WIDTH==32

#define COLSHIFT_R  16
#define COLMASK_R   0xff
#define COLSHIFT_G  8
#define COLMASK_G   0xff
#define COLSHIFT_B  0
#define COLMASK_B   0xff

typedef UInt32 Pixel;

#elif PIXEL_WIDTH==8

#define COLSHIFT_R  10
#define COLMASK_R   0x1f
#define COLSHIFT_G  5
#define COLMASK_G   0x1f
#define COLSHIFT_B  0
#define COLMASK_B   0x1f

typedef UInt8 Pixel;

#else

#define COLSHIFT_R  5
#define COLMASK_R   0x07
#define COLSHIFT_G  2
#define COLMASK_G   0x03
#define COLSHIFT_B  0
#define COLMASK_B   0x07

typedef UInt16 Pixel;

#endif

// Debug replacement for malloc and free to easier find memory leaks.
#if 0

#define malloc dbgMalloc
#define calloc dbgCalloc
#define free   dbgFree

#include <stdlib.h>

void* dbgMalloc(size_t size);
void* dbgCalloc(size_t size, size_t count);
void dbgFree(void* ptr);
void dbgEnable();
void dbgDisable();
void dbgPrint();

#else

#define dbgEnable()
#define dbgDisable()
#define dbgPrint()

#endif

#ifdef __cplusplus
}
#endif


///
/// The following section contain target dependent configuration
/// It should probably be moved to its own file but for convenience
/// its kept here....
///


//
// Target dependent video configuration options
//

#if 0
// Should be enabled for IPHONE
#include <Config/VideoChips.h>

// Enable for displays that are only 320 pixels wide
#define MAX_VIDEO_WIDTH_320

// Skip overscan for CRT (e.g. Iphone)
#define CRT_SKIP_OVERSCAN

// Enable for 565 RGB displays
#define VIDEO_COLOR_TYPE_RGB565

// Enable for 565 RGB displays
#define VIDEO_COLOR_TYPE_RGB565

// Enable for 5551 RGBA displays
#define VIDEO_COLOR_TYPE_RGBA5551

// Provide custom z80 configuration
#define Z80_CUSTOM_CONFIGURATION

// For Iphone custom z80 configuration is in separate file:
#include <Config/Z80.h>


// Exclude embedded samples from build
#define NO_EMBEDDED_SAMPLES

#endif


// Placeholder for configuration definitions
// Targets that wish to disable features should create an ifdef block
// for that particular target with the appropriate definitions or
// add them as a pre-processor directive in the build system
#if 0


#define EXCLUDE_JOYSTICK_PORT_GUNSTICK
#define EXCLUDE_JOYSTICK_PORT_ASCIILASER
#define EXCLUDE_JOYSTICK_PORT_JOYSTICK
#define EXCLUDE_JOYSTICK_PORT_MOUSE
#define EXCLUDE_JOYSTICK_PORT_TETRIS2DONGLE
#define EXCLUDE_JOYSTICK_PORT_MAGICKEYDONGLE
#define EXCLUDE_JOYSTICK_PORT_ARKANOID_PAD



#define EXCLUDE_SPECIAL_GAME_CARTS
#define EXCLUDE_MSXMIDI
#define EXCLUDE_NMS8280DIGI
#define EXCLUDE_JOYREXPSG
#define EXCLUDE_OPCODE_DEVICES
#define EXCLUDE_SVI328_DEVICES
#define EXCLUDE_SVIMSX_DEVICES
#define EXCLUDE_FORTEII
#define EXCLUDE_OBSONET
#define EXCLUDE_NOWIND
#define EXCLUDE_DUMAS
#define EXCLUDE_MOONSOUND
#define EXCLUDE_PANASONIC_DEVICES
#define EXCLUDE_YAMAHA_SFG
#define EXCLUDE_ROM_YAMAHANET
#define EXCLUDE_SEGA_DEVICES
#define EXCLUDE_DISK_DEVICES
#define EXCLUDE_IDE_DEVICES
#define EXCLUDE_MICROSOL80
#define EXCLUDE_SRAM_MATSUCHITA
#define EXCLUDE_SRAM_S1985
#define EXCLUDE_ROM_S1990
#define EXCLUDE_ROM_TURBOR
#define EXCLUDE_ROM_F4DEVICE

#endif



#endif

