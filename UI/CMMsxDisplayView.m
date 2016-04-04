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

#define HIDE_CURSOR_TIMEOUT_SECONDS 1.0f

@interface CMMsxDisplayView ()

- (void)renderScreen;
- (void) handleMouseAction:(NSEvent *) theEvent;

@end

@implementation CMMsxDisplayView
{
	UInt32 borderColor;
	CGFloat framesPerSecond;
	GLuint screenTexId;
	int currentScreenIndex;
	CMCocoaBuffer *screens[2];
	CMFrameCounter *frameCounter;
	CFAbsoluteTime lastMouseAction;
	NSPoint lastCursorPosition;
	BOOL cursorVisible;
}

#pragma mark - Initialize, Dealloc

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:@"videoScanlineAmount"];
    
    glDeleteTextures(1, &screenTexId);
    
	for (int i = 0; i < 2; i++) {
		screens[i] = nil;
	}
}

- (void)awakeFromNib
{
    [self.window setAcceptsMouseMovedEvents:YES];
    if ([self respondsToSelector:@selector(setWantsBestResolutionOpenGLSurface:)]) {
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"videoScanlineAmount"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
    frameCounter = [[CMFrameCounter alloc] init];
	lastMouseAction = CFAbsoluteTimeGetCurrent();
    
    currentScreenIndex = 0;
	cursorVisible = YES;
	lastCursorPosition = NSMakePoint(-1, -1);
    
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
    
    GLfloat scaleFactor = 1.0f;
    if ([[self window] respondsToSelector:@selector(backingScaleFactor)]) {
        scaleFactor = [[self window] backingScaleFactor];
    }
    
    screens[0] = [[CMCocoaBuffer alloc] initWithWidth:BUFFER_WIDTH
                                               height:HEIGHT
                                                 zoom:ZOOM
                                         backingScale:scaleFactor];
    screens[1] = [[CMCocoaBuffer alloc] initWithWidth:BUFFER_WIDTH
                                               height:HEIGHT
                                                 zoom:ZOOM
                                         backingScale:scaleFactor];
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB,
                 screens[0]->textureSize.width, screens[0]->textureSize.height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
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
    NSSize backingSize;
    if ([self respondsToSelector:@selector(convertRectToBacking:)]) {
        backingSize = [self convertRectToBacking:[self bounds]].size;
    } else {
        backingSize = size;
    }

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
    
    glViewport(0, 0, backingSize.width, backingSize.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, backingSize.width, backingSize.height, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void) cancelOperation:(id) sender
{
    // Prevent ESC from canceling full screen mode
}

#pragma mark - Mouse Callbacks

- (void)mouseMoved:(NSEvent *)theEvent
{
	[self handleMouseAction:theEvent];
	
    [[emulator mouse] mouseMoved:theEvent
                    withinView:self];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[self handleMouseAction:theEvent];
	
    [[emulator mouse] mouseMoved:theEvent
                    withinView:self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[self handleMouseAction:theEvent];
	
    [[emulator mouse] mouseDown:theEvent
                   withinView:self];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[self handleMouseAction:theEvent];
	
    [[emulator mouse] mouseUp:theEvent
                 withinView:self];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self handleMouseAction:theEvent];
	
    [[emulator mouse] rightMouseDown:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self handleMouseAction:theEvent];
	
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
	if ([[self window] isKeyWindow] && NSPointInRect(lastCursorPosition, [self bounds])) {
		CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - lastMouseAction;
		if (cursorVisible && interval > HIDE_CURSOR_TIMEOUT_SECONDS && CMGetBoolPref(@"autohideCursor")) {
			[[emulator mouse] showCursor:NO];
			cursorVisible = NO;
		}
	}
	
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
    FrameBuffer *frameBuffer = frameBufferFlipViewFrame(properties->emulation.syncMethod == P_EMU_SYNCTOVBLANKASYNC);
    
    CMCocoaBuffer *currentScreen = screens[currentScreenIndex];
    
    UInt8 *dpyData = currentScreen->pixels;
    int width = currentScreen->actualWidth;
    int height = currentScreen->actualHeight;
    
    if (frameBuffer == NULL)
        frameBuffer = frameBufferGetWhiteNoiseFrame();
    
    int borderWidth = (BUFFER_WIDTH - frameBuffer->maxWidth) * ZOOM / 2;
    
    videoRender(video, frameBuffer, DEPTH, ZOOM,
                dpyData + borderWidth * currentScreen->bytesPerPixel, 0,
                currentScreen->pitch, -1);
    
    UInt32 bgColor = *((UInt32 *)(dpyData + borderWidth * currentScreen->bytesPerPixel));
    if (bgColor != borderColor) {
        borderColor = bgColor;
        if ([self->_delegate respondsToSelector:@selector(msxDisplay:borderColorChanged:)]) {
            [self->_delegate msxDisplay:self
                     borderColorChanged:[self borderColor]];
        }
    }
    
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
    
    void *texture = [currentScreen applyScale];
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, currentScreen->textureSize.width,
                    currentScreen->textureSize.height,
                    GL_RGBA, GL_UNSIGNED_BYTE, texture);
    
    NSSize backingSize;
    if ([self respondsToSelector:@selector(convertRectToBacking:)]) {
        backingSize = [self convertRectToBacking:[self bounds]].size;
    } else {
        backingSize = [self bounds].size;
    }
    
    CGFloat widthRatio = backingSize.width / (CGFloat)ACTUAL_WIDTH;
    CGFloat offset = ((BUFFER_WIDTH - ACTUAL_WIDTH) / 2.0) * widthRatio;
    
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-offset, 0.0, 0.0);
    glTexCoord2f(currentScreen->textureCoord.x, 0.0);
    glVertex3f(backingSize.width + offset, 0.0, 0.0);
    glTexCoord2f(currentScreen->textureCoord.x, currentScreen->textureCoord.y);
    glVertex3f(backingSize.width + offset, backingSize.height, 0.0);
    glTexCoord2f(0.0, currentScreen->textureCoord.y);
    glVertex3f(-offset, backingSize.height, 0.0);
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

- (NSColor *) borderColor
{
    return [NSColor colorWithCalibratedRed:(borderColor & 0xff) / 255.0
                                     green:((borderColor >> 8) & 0xff) / 255.0
                                      blue:((borderColor >> 16) & 0xff) / 255.0
                                     alpha:1.0];
}

- (void) handleMouseAction:(NSEvent *) theEvent
{
	lastMouseAction = CFAbsoluteTimeGetCurrent();
	lastCursorPosition = [self convertPoint:[theEvent locationInWindow]
								   fromView:nil];
	
	if (!cursorVisible) {
		cursorVisible = YES;
		[[emulator mouse] showCursor:YES];
	}
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
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                     pixelsWide:frameBuffer->maxWidth * zoom
                                                                     pixelsHigh:height
                                                                  bitsPerSample:8
                                                                samplesPerPixel:4
                                                                       hasAlpha:YES
                                                                       isPlanar:NO
                                                                 colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
                                                                    bytesPerRow:pitch
                                                                   bitsPerPixel:0];
    
    // Copy contents of bitmap to NSBitmapImageRep
    memcpy([rep bitmapData], rawBitmapBuffer, pitch * height);
    
    // Create an image with the newly created representation
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:rep];
    
    // Finally, free the buffer
    free(rawBitmapBuffer);
    
    return image;
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
            NSBitmapImageRep *rep = (NSBitmapImageRep *)[[image representations] firstObject];
            NSData *pngData = [rep representationUsingType:NSPNGFileType properties:@{}];
            
            *bitmapSize = pngData.length;
            bytes = malloc(*bitmapSize);
            
            memcpy(bytes, [pngData bytes], *bitmapSize);
        }
    }
    
    return bytes;
}

@end
