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
#include <OpenGL/gl.h>
#include <time.h>

#import "CMMsxDisplayView.h"
#import "CMEmulatorController.h"
#import "CMCocoaBuffer.h"
#import "CMFrameCounter.h"
#import "CMPreferences.h"

#include "Properties.h"
#include "VideoRender.h"
#include "FrameBuffer.h"
#include "ArchNotifications.h"

#define ACTUAL_WIDTH 272

#define BUFFER_WIDTH 320
#define HEIGHT       240
#define DEPTH        32
#define ZOOM         2

@interface CMMsxDisplayView ()

- (void)renderScreen;

@end

@implementation CMMsxDisplayView

#pragma mark - Initialize, Dealloc

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:@"videoScanlineAmount"];
    
    glDeleteTextures(1, &screenTexId);
    
    for (int i = 0; i < 2; i++)
        [screens[i] release];
    
    [frameCounter release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    [self.window setAcceptsMouseMovedEvents:YES];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"videoScanlineAmount"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
    frameCounter = [[CMFrameCounter alloc] init];
    
    cursorVisible = YES;
    currentScreenIndex = 0;
    
    for (int i = 0; i < 2; i++)
        screens[i] = nil;
}

#pragma mark - Notification Callbacks

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"videoScanlineAmount"])
    {
        NSNumber *newValue = [change objectForKey:NSKeyValueChangeNewKey];
        
        // Change actual scanline value, but only if the display is large enough
        if (self.bounds.size.width >= ACTUAL_WIDTH * ZOOM)
            emulator.scanlines = [newValue integerValue];
    }
}

#pragma mark - Cocoa Callbacks

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &screenTexId);
    
    glBindTexture(GL_TEXTURE_2D, screenTexId);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    for (int i = 0; i < 2; i++)
    {
        [screens[i] release];
        screens[i] = [[CMCocoaBuffer alloc] initWithWidth:BUFFER_WIDTH
                                                   height:HEIGHT
                                                    depth:DEPTH
                                                     zoom:ZOOM];
    }
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB,
                 screens[0]->textureWidth,
                 screens[0]->textureHeight,
                 0, GL_RGBA, GL_UNSIGNED_BYTE,
                 screens[0]->pixels);
    
    glDisable(GL_TEXTURE_2D);
    
#ifdef DEBUG
    NSLog(@"MsxDisplayView: initialized");
#endif
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self renderScreen];
}

- (void)reshape
{
    [[self openGLContext] makeCurrentContext];
    [[self openGLContext] update];
    
    NSSize size = [self bounds].size;
    
    if ([emulator isStarted])
    {
        if (size.width < ACTUAL_WIDTH * ZOOM)
        {
            if (emulator.scanlines != 0)
            {
                emulator.scanlines = 0;
#ifdef DEBUG
                NSLog(@"Disabling scanlines - screen not large enough");
#endif
            }
        }
        else
        {
            NSInteger scanlineAmount = [[NSUserDefaults standardUserDefaults] integerForKey:@"videoScanlineAmount"];
            if (emulator.scanlines != scanlineAmount)
            {
                emulator.scanlines = scanlineAmount;
#ifdef DEBUG
                NSLog(@"Resetting scanlines to %d%%", (int)scanlineAmount);
#endif
            }
        }
    }
    
#ifdef DEBUG
    NSLog(@"MsxDisplayView: resized to %.00fx%.00f", size.width, size.height);
#endif
    
    glViewport(0, 0, size.width, size.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, size.width, size.height, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    
    glClear(GL_COLOR_BUFFER_BIT);
}

#pragma mark - Mouse Callbacks

- (void)mouseMoved:(NSEvent *)theEvent
{
    [[emulator mouse] mouseMoved:theEvent
                    withinView:self];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [[emulator mouse] mouseMoved:theEvent
                    withinView:self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[emulator mouse] mouseDown:theEvent
                   withinView:self];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [[emulator mouse] mouseUp:theEvent
                 withinView:self];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    [[emulator mouse] rightMouseDown:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    [[emulator mouse] rightMouseUp:theEvent];
}

- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime
{
    @autoreleasepool
    {
        [self renderScreen];
    }
    
    return kCVReturnSuccess;
}

#pragma mark - Emulator-specific graphics code

- (void)renderScreen
{
    NSOpenGLContext *nsContext = [self openGLContext];
    [nsContext makeCurrentContext];
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (!emulator.isInitialized)
    {
        [nsContext flushBuffer];
        return;
    }
    
    CGLContextObj cglContext = [nsContext CGLContextObj];
    
    CGLLockContext(cglContext);
    
    framesPerSecond = [frameCounter update];
    [emulator updateFps:framesPerSecond];
    
    Properties *properties = emulator.properties;
    Video *video = emulator.video;
    FrameBuffer* frameBuffer = frameBufferFlipViewFrame(properties->emulation.syncMethod == P_EMU_SYNCTOVBLANKASYNC);
    
    CMCocoaBuffer *currentScreen = screens[currentScreenIndex];
    
    char* dpyData = currentScreen->pixels;
    int width = currentScreen->actualWidth;
    int height = currentScreen->actualHeight;
    
    if (frameBuffer == NULL)
        frameBuffer = frameBufferGetWhiteNoiseFrame();
    
    int borderWidth = (BUFFER_WIDTH - frameBuffer->maxWidth) * currentScreen->zoom / 2;
    const int linesPerBlock = 4;
    GLfloat coordX = currentScreen->textureCoordX;
    GLfloat coordY = currentScreen->textureCoordY;
    int y;
    
    videoRender(video, frameBuffer, currentScreen->depth, currentScreen->zoom,
                dpyData + borderWidth * currentScreen->bytesPerPixel, 0,
                currentScreen->pitch, -1);
    
    if (borderWidth > 0)
    {
        int h = height;
        while (h--)
        {
            memset(dpyData, 0, borderWidth * currentScreen->bytesPerPixel);
            memset(dpyData + (width - borderWidth) * currentScreen->bytesPerPixel,
                   0, borderWidth * currentScreen->bytesPerPixel);
            
            dpyData += currentScreen->pitch;
        }
    }
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, screenTexId);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    
    for (y = 0; y < height; y += linesPerBlock)
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, y, width, linesPerBlock,
                        GL_RGBA, GL_UNSIGNED_BYTE,
                        currentScreen->pixels + y * currentScreen->pitch);
    
    NSSize size = [self bounds].size;
    
    CGFloat widthRatio = size.width / (CGFloat)ACTUAL_WIDTH;
    CGFloat offset = ((BUFFER_WIDTH - ACTUAL_WIDTH) / 2.0) * widthRatio;
    
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-offset, 0.0, 0.0);
    glTexCoord2f(coordX, 0.0);
    glVertex3f(size.width + offset, 0.0, 0.0);
    glTexCoord2f(coordX, coordY);
    glVertex3f(size.width + offset, size.height, 0.0);
    glTexCoord2f(0.0, coordY);
    glVertex3f(-offset, size.height, 0.0);
    glEnd();
    glDisable(GL_TEXTURE_2D);
    
    [nsContext flushBuffer];
    
    currentScreenIndex ^= 1;
    
    CGLUnlockContext(cglContext);
}

- (CGFloat)framesPerSecond
{
    return framesPerSecond;
}

#pragma mark - blueMSX implementations

extern CMEmulatorController *theEmulator;

int archUpdateEmuDisplay(int syncMode)
{
    @autoreleasepool
    {
        theEmulator.screen.needsDisplay = YES;
    }
    
    return 1;
}

void archUpdateWindow()
{
}

- (NSImage *)captureScreen:(BOOL)large
{
    NSInteger zoom = (large) ? 2 : 1;
    NSInteger width = BUFFER_WIDTH * zoom;
    NSInteger height = HEIGHT * zoom;
    NSInteger pitch = width * sizeof(UInt32);
    
    UInt32 *rawBitmapBuffer = malloc(pitch * height);
    if (!rawBitmapBuffer)
        return nil;
    
    Video *copy = videoCopy(emulator.video);
    if (!copy)
    {
        free(rawBitmapBuffer);
        return nil;
    }
    
    copy->palMode = VIDEO_PAL_FAST;
    copy->scanLinesEnable = 0;
    copy->colorSaturationEnable = 0;
    
    FrameBuffer *frameBuffer = frameBufferGetViewFrame();
    if (frameBuffer == NULL || frameBuffer->maxWidth <= 0 || frameBuffer->lines <= 0)
    {
        free(rawBitmapBuffer);
        videoDestroy(copy);
        return nil;
    }
    
    videoRender(copy, frameBuffer, 32, zoom, rawBitmapBuffer, 0, pitch, 0);
    videoDestroy(copy);
    
    // Mirror the byte order
    for (int i = width * height - 1; i >= 0; i--)
    {
        UInt8 r = rawBitmapBuffer[i] & 0xff;
        UInt8 g = (rawBitmapBuffer[i] & 0xff00) >> 8;
        UInt8 b = (rawBitmapBuffer[i] & 0xff0000) >> 16;
        
        rawBitmapBuffer[i] = r | (g << 8) | (b << 16) | 0xff000000;
    }
    
    // Create a bitmap representation
    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                     pixelsWide:frameBuffer->maxWidth * zoom
                                                                     pixelsHigh:height
                                                                  bitsPerSample:8
                                                                samplesPerPixel:4
                                                                       hasAlpha:YES
                                                                       isPlanar:NO
                                                                 colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
                                                                    bytesPerRow:pitch
                                                                   bitsPerPixel:0] autorelease];
    
    // Copy contents of bitmap to NSBitmapImageRep
    memcpy([rep bitmapData], rawBitmapBuffer, pitch * height);
    
    // Create an image with the newly created representation
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:rep];
    
    // Finally, free the buffer
    free(rawBitmapBuffer);
    
    return [image autorelease];
}

void *archScreenCapture(ScreenCaptureType type, int *bitmapSize, int onlyBmp)
{
    void *bytes = NULL;
    *bitmapSize = 0;
    
    @autoreleasepool
    {
        NSImage *image = [theEmulator.screen captureScreen:NO];
        if (image && [image representations].count > 0)
        {
            NSBitmapImageRep *rep = [[image representations] objectAtIndex:0];
            NSData *pngData = [rep representationUsingType:NSPNGFileType properties:nil];
            
            *bitmapSize = pngData.length;
            bytes = malloc(*bitmapSize);
            
            memcpy(bytes, [pngData bytes], *bitmapSize);
        }
    }
    
    return bytes;
}

@end
