/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2016 Akop Karapetyan
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

+ (int) powerOfTwoClosestTo:(int) number;

@end

@implementation CMCocoaBuffer

+ (int) powerOfTwoClosestTo:(int) number
{
    int rv = 1;
    while (rv < number) rv *= 2;
    return rv;
}

- (id) initWithWidth:(int) screenWidth
              height:(int) screenHeight
                zoom:(int) zoomFactor
        backingScale:(GLfloat) backingScaleFactor
{
    if ((self = [super init]))
    {
        actualWidth = screenWidth * zoomFactor;
        actualHeight = screenHeight * zoomFactor;
        
        NSSize scaledSize = NSMakeSize(actualWidth * backingScaleFactor,
                                       actualHeight * backingScaleFactor);
        
        textureSize = NSMakeSize([CMCocoaBuffer powerOfTwoClosestTo:scaledSize.width],
                                 [CMCocoaBuffer powerOfTwoClosestTo:scaledSize.height]);
        textureCoord = NSMakePoint(scaledSize.width / textureSize.width,
                                   scaledSize.height / textureSize.height);
        
        bytesPerPixel = sizeof(UInt32);
        scaledPixels = (UInt8 *) calloc(1, bytesPerPixel * textureSize.width * textureSize.height);
        
        if (actualWidth * backingScaleFactor != actualWidth) {
            // Use an intermediate area for the initial screen blit
            pixels = (UInt8 *) calloc(1, bytesPerPixel * actualWidth * actualHeight);
            pitch = actualWidth * bytesPerPixel;
            
            NSLog(@"CocoaBuffer: Using a buffer with %.02f scale factor",
                  backingScaleFactor);
        } else {
            // Just render to the texture
            pixels = scaledPixels;
            pitch = textureSize.width * bytesPerPixel;
            
            NSLog(@"CocoaBuffer: Rendering directly to texture");
        }
    }
    
    return self;
}

- (void) dealloc
{
    free(scaledPixels);
    if (pixels != scaledPixels) {
        free(pixels);
    }
    
    scaledPixels = NULL;
    pixels = NULL;
}

- (void *) applyScale
{
    if (pixels != scaledPixels) {
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
            sp += (int) textureSize.width;
        }
    }
    
    return scaledPixels;
}

@end
