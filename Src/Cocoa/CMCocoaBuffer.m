/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2014 Akop Karapetyan
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

- (id)initWithWidth:(int)screenWidth
             height:(int)screenHeight
              depth:(int)imageDepth
               zoom:(int)zoomFactor
{
    if ((self = [super init]))
    {
        width = screenWidth;
        height = screenHeight;
        actualWidth = screenWidth * zoomFactor;
        actualHeight = screenHeight * zoomFactor;
        textureWidth = [CMCocoaBuffer powerOfTwoClosestTo:actualWidth];
        textureHeight = [CMCocoaBuffer powerOfTwoClosestTo:actualHeight];
        textureCoordX = (GLfloat)actualWidth / textureWidth;
        textureCoordY = (GLfloat)actualHeight / textureHeight;
        depth = imageDepth;
        zoom = zoomFactor;
        bytesPerPixel = imageDepth / 8;
        pitch = actualWidth * bytesPerPixel;
        pixels = (char*)calloc(1, bytesPerPixel * textureWidth * textureHeight);
    }
    
    return self;
}

- (void)dealloc
{
    if (pixels)
        free(pixels);
    
    [super dealloc];
}

@end
