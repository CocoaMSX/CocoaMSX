/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2015 Akop Karapetyan
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
#import "CMCocoaBuffer.h"

@interface CMCocoaBuffer ()

+ (int)powerOfTwoClosestTo:(int)number;

@end

@implementation CMCocoaBuffer

+ (int)powerOfTwoClosestTo:(int)number
{
    int rv = 1;
    while (rv < number) rv *= 2;
    return rv;
}

- (id) initWithWidth:(int) screenWidth
              height:(int) screenHeight
               depth:(int) imageDepth
                zoom:(int) zoomFactor
        backingScale:(GLfloat) backingScaleFactor
{
    if ((self = [super init]))
    {
        width = screenWidth;
        height = screenHeight;
        backingScale = backingScaleFactor;
        actualWidth = screenWidth * zoomFactor;
        actualHeight = screenHeight * zoomFactor;
        textureWidth = [CMCocoaBuffer powerOfTwoClosestTo:actualWidth * backingScaleFactor];
        textureHeight = [CMCocoaBuffer powerOfTwoClosestTo:actualHeight * backingScaleFactor];
        textureCoordX = (GLfloat) (actualWidth * backingScale) / textureWidth;
        textureCoordY = (GLfloat) (actualHeight * backingScale) / textureHeight;
        depth = imageDepth;
        zoom = zoomFactor;
        bytesPerPixel = imageDepth / 8;
        pitch = actualWidth * bytesPerPixel;
        pixels = (char *) calloc(1, bytesPerPixel * actualWidth * actualHeight);
        scaledPixels = (UInt8 *) calloc(1, bytesPerPixel * textureWidth * textureHeight);
    }
    
    return self;
}

- (void) dealloc
{
    free(pixels);
    free(scaledPixels);
    
    [super dealloc];
}

- (void) applyScale
{
    UInt32 *p = (UInt32 *) pixels;
    UInt32 *sp = (UInt32 *) scaledPixels;
    
    for (int ai = 0, ti = 0; ai < actualHeight; ti++) {
        for (int aj = 0, tj = 0; aj < actualWidth; tj++) {
            sp[tj] = p[aj];
            if (tj & 1) {
                aj++;
            }
        }
        if (ti & 1) {
            ai++;
            p += actualWidth;
        }
        sp += textureWidth;
    }
}

@end
