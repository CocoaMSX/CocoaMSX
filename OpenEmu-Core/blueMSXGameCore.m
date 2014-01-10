/*
 Copyright (c) 2014, OpenEmu Team
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the OpenEmu Team nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "blueMSXGameCore.h"
#import "OEMSXSystemResponderClient.h"

#import <OpenGL/gl.h>

#include "ArchInput.h"
#include "ArchNotifications.h"
#include "Actions.h"
#include "JoystickPort.h"
#include "Machine.h"
#include "MidiIO.h"
#include "UartIO.h"
#include "Casette.h"
#include "Emulator.h"
#include "Board.h"
#include "Language.h"
#include "LaunchFile.h"
#include "PrinterIO.h"
#include "InputEvent.h"

#define BUFFER_WIDTH  320
#define SCREEN_WIDTH  272
#define SCREEN_DEPTH  32
#define SCREEN_HEIGHT 240

#define virtualCodeSet(eventCode) self->virtualCodeMap[eventCode] = 1
#define virtualCodeUnset(eventCode) self->virtualCodeMap[eventCode] = 0
#define virtualCodeClear() memset(self->virtualCodeMap, 0, sizeof(self->virtualCodeMap));

@interface blueMSXGameCore()
{
    NSLock *bufferLock;
}

- (void)initializeBlueMSX;
- (void)renderFrame;

@end

static blueMSXGameCore *_core;

@implementation blueMSXGameCore

- (id)init
{
    if ((self = [super init]))
    {
        currentScreenIndex = 0;
        bufferLock = [[NSLock alloc] init];
        _core = self;
        for (int i = 0; i < 2; i++)
            screens[i] = [[CMCocoaBuffer alloc] initWithWidth:BUFFER_WIDTH
                                                       height:SCREEN_HEIGHT
                                                        depth:SCREEN_DEPTH
                                                         zoom:1];
        
        [self initializeBlueMSX];
    }

    return self;
}

- (void)dealloc
{
    videoDestroy(video);
    propDestroy(properties);
    archSoundDestroy();
    mixerDestroy(mixer);
}

- (void)initializeBlueMSX;
{
    properties = propCreate(0, 0, P_KBD_EUROPEAN, 0, "");
    
    NSString *resourcePath = [[NSBundle bundleWithIdentifier:@"org.openemu.blueMSX"] resourcePath];
    
    // Set machine name
    strncpy(properties->emulation.machineName, "MSX2 - C-BIOS", PROP_MAXPATH - 1);
    
    // Set up properties
    properties->emulation.speed = 50;
    properties->emulation.syncMethod = P_EMU_SYNCTOVBLANKASYNC;
    properties->emulation.enableFdcTiming = YES;
    properties->emulation.vdpSyncMode = 0;
    
    properties->video.brightness = 100;
    properties->video.contrast = 100;
    properties->video.saturation = 100;
    properties->video.gamma = 100;
    properties->video.colorSaturationWidth = 0;
    properties->video.colorSaturationEnable = NO;
    properties->video.deInterlace = YES;
    properties->video.monitorType = 0;
    properties->video.monitorColor = 0;
    properties->video.scanlinesPct = 100;
    properties->video.scanlinesEnable = (properties->video.scanlinesPct < 100);
    
    properties->sound.mixerChannel[MIXER_CHANNEL_PSG].volume = 100;
    properties->sound.mixerChannel[MIXER_CHANNEL_PSG].pan = 50;
    properties->sound.mixerChannel[MIXER_CHANNEL_PSG].enable = YES;
    properties->sound.mixerChannel[MIXER_CHANNEL_SCC].volume = 100;
    properties->sound.mixerChannel[MIXER_CHANNEL_SCC].pan = 50;
    properties->sound.mixerChannel[MIXER_CHANNEL_SCC].enable = YES;
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].volume = 100;
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].pan = 50;
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].enable = YES;
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].volume = 100;
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].pan = 50;
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].enable = YES;
    properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].volume = 100;
    properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].pan = 50;
    properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].enable = YES;
    properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].volume = 100;
    properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].pan = 50;
    properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].enable = YES;
    
    properties->joy1.typeId = JOYSTICK_PORT_JOYSTICK;
    properties->joy2.typeId = JOYSTICK_PORT_JOYSTICK;
    
    // Init video
    video = videoCreate();
    videoSetColors(video, properties->video.saturation, properties->video.brightness,
                   properties->video.contrast, properties->video.gamma);
    videoSetScanLines(video, properties->video.scanlinesEnable, properties->video.scanlinesPct);
    videoSetColorSaturation(video, properties->video.colorSaturationEnable, properties->video.colorSaturationWidth);
    videoSetColorMode(video, properties->video.monitorColor);
    videoSetRgbMode(video, 1);
    videoUpdateAll(video, properties);
    
    // Init translations (unused for the most part)
    langSetLanguage(properties->language);
    langInit();
    
    // Init input
    joystickPortSetType(0, properties->joy1.typeId);
    joystickPortSetType(1, properties->joy2.typeId);
    
    // Init misc. devices
    printerIoSetType(properties->ports.Lpt.type, properties->ports.Lpt.fileName);
    printerIoSetType(properties->ports.Lpt.type, properties->ports.Lpt.fileName);
    uartIoSetType(properties->ports.Com.type, properties->ports.Com.fileName);
    midiIoSetMidiOutType(properties->sound.MidiOut.type, properties->sound.MidiOut.fileName);
    midiIoSetMidiInType(properties->sound.MidiIn.type, properties->sound.MidiIn.fileName);
    ykIoSetMidiInType(properties->sound.YkIn.type, properties->sound.YkIn.fileName);
    
    // Init mixer
    mixer = mixerCreate();
    
    for (int i = 0; i < MIXER_CHANNEL_TYPE_COUNT; i++)
    {
        mixerSetChannelTypeVolume(mixer, i, properties->sound.mixerChannel[i].volume);
        mixerSetChannelTypePan(mixer, i, properties->sound.mixerChannel[i].pan);
        mixerEnableChannelType(mixer, i, properties->sound.mixerChannel[i].enable);
    }
    
    mixerSetMasterVolume(mixer, properties->sound.masterVolume);
    mixerEnableMaster(mixer, properties->sound.masterEnable);
    
    // Init media DB
    mediaDbLoad([[resourcePath stringByAppendingPathComponent:@"Databases"] UTF8String]);
    mediaDbSetDefaultRomType(properties->cartridge.defaultType);
    
    // Init board
    boardSetFdcTimingEnable(properties->emulation.enableFdcTiming);
    boardSetY8950Enable(properties->sound.chip.enableY8950);
    boardSetYm2413Enable(properties->sound.chip.enableYM2413);
    boardSetMoonsoundEnable(properties->sound.chip.enableMoonsound);
    boardSetVideoAutodetect(properties->video.detectActiveMonitor);
    boardEnableSnapshots(0);
    
    // Init storage
    for (int i = 0; i < PROP_MAX_CARTS; i++)
    {
        if (properties->media.carts[i].fileName[0])
            insertCartridge(properties, i, properties->media.carts[i].fileName,
                            properties->media.carts[i].fileNameInZip,
                            properties->media.carts[i].type, -1);
    }
    
    for (int i = 0; i < PROP_MAX_DISKS; i++)
    {
        if (properties->media.disks[i].fileName[0])
            insertDiskette(properties, i, properties->media.disks[i].fileName,
                           properties->media.disks[i].fileNameInZip, -1);
    }
    
    for (int i = 0; i < PROP_MAX_TAPES; i++)
    {
        if (properties->media.tapes[i].fileName[0])
            insertCassette(properties, i, properties->media.tapes[i].fileName,
                           properties->media.tapes[i].fileNameInZip, 0);
    }
    
    tapeSetReadOnly(properties->cassette.readOnly);
    
    // Misc. initialization
    machineSetDirectory([[resourcePath stringByAppendingPathComponent:@"Machines"] UTF8String]);
    emulatorInit(properties, mixer);
    actionInit(video, properties, mixer);
    emulatorRestartSound();
}

- (void)startEmulation
{
    [super startEmulation];
    
    // propertiesSetDirectory("", "");
    // tapeSetDirectory("/Cassettes", "");
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[self batterySavesDirectoryPath]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    
    boardSetDirectory([[self batterySavesDirectoryPath] UTF8String]);
    
    emulatorStart(NULL);
    insertCartridge(properties, 0, [fileToLoad UTF8String], NULL, romTypeToLoad, 0);
}

- (void)stopEmulation
{
    emulatorSuspend();
    emulatorStop();
    
    [super stopEmulation];
}

- (void)setPauseEmulation:(BOOL)pauseEmulation
{
    if (pauseEmulation)
        emulatorSetState(EMU_PAUSED);
    else
        emulatorSetState(EMU_RUNNING);
    
    [super setPauseEmulation:pauseEmulation];
}

- (void)resetEmulation
{
    actionEmuResetSoft();
}

- (oneway void)didPushMSXJoystickButton:(OEMSXJoystickButton)button
                             controller:(NSInteger)index
{
    int code = -1;
    
    switch (button)
    {
    case OEMSXJoystickUp:
        code = (index == 1) ? EC_JOY1_UP : EC_JOY2_UP;
        break;
    case OEMSXJoystickDown:
        code = (index == 1) ? EC_JOY1_DOWN : EC_JOY2_DOWN;
        break;
    case OEMSXJoystickLeft:
        code = (index == 1) ? EC_JOY1_LEFT : EC_JOY2_LEFT;
        break;
    case OEMSXJoystickRight:
        code = (index == 1) ? EC_JOY1_RIGHT : EC_JOY2_RIGHT;
        break;
    case OEMSXButtonA:
        code = (index == 1) ? EC_JOY1_BUTTON1 : EC_JOY2_BUTTON1;
        break;
    case OEMSXButtonB:
        code = (index == 1) ? EC_JOY1_BUTTON2 : EC_JOY2_BUTTON2;
        break;
    default:
        break;
    }
    
    if (code != -1)
        virtualCodeSet(code);
}

- (oneway void)didReleaseMSXJoystickButton:(OEMSXJoystickButton)button
                                controller:(NSInteger)index
{
    int code = -1;
    
    switch (button)
    {
    case OEMSXJoystickUp:
        code = (index == 1) ? EC_JOY1_UP : EC_JOY2_UP;
        break;
    case OEMSXJoystickDown:
        code = (index == 1) ? EC_JOY1_DOWN : EC_JOY2_DOWN;
        break;
    case OEMSXJoystickLeft:
        code = (index == 1) ? EC_JOY1_LEFT : EC_JOY2_LEFT;
        break;
    case OEMSXJoystickRight:
        code = (index == 1) ? EC_JOY1_RIGHT : EC_JOY2_RIGHT;
        break;
    case OEMSXButtonA:
        code = (index == 1) ? EC_JOY1_BUTTON1 : EC_JOY2_BUTTON1;
        break;
    case OEMSXButtonB:
        code = (index == 1) ? EC_JOY1_BUTTON2 : EC_JOY2_BUTTON2;
        break;
    default:
        break;
    }
    
    if (code != -1)
        virtualCodeUnset(code);
}

- (void)executeFrame
{
    //
    memcpy(eventMap, _core->virtualCodeMap, sizeof(_core->virtualCodeMap));
}

- (void)renderFrame
{
    [bufferLock lock];
    
    FrameBuffer* frameBuffer = frameBufferFlipViewFrame(properties->emulation.syncMethod == P_EMU_SYNCTOVBLANKASYNC);
    CMCocoaBuffer *currentScreen = screens[currentScreenIndex];
    
    char* dpyData = currentScreen->pixels;
    int width = currentScreen->actualWidth;
    int height = currentScreen->actualHeight;
    
    if (frameBuffer == NULL)
        frameBuffer = frameBufferGetWhiteNoiseFrame();
    
    int borderWidth = (BUFFER_WIDTH - frameBuffer->maxWidth) * currentScreen->zoom / 2;
    
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
    
    currentScreenIndex ^= 1;
    
    [bufferLock unlock];
}

- (BOOL)loadFileAtPath:(NSString *)path
{
    const char *cpath = [path UTF8String];
    MediaType *mediaType = mediaDbLookupRomByPath(cpath);
    if (!mediaType)
        mediaType = mediaDbGuessRomByPath(cpath);
    
    if (mediaType)
        romTypeToLoad = mediaDbGetRomType(mediaType);
    else
        romTypeToLoad = ROM_UNKNOWN;
    
    fileToLoad = path;
    
    return YES;
}

- (OEIntSize)bufferSize
{
    return OEIntSizeMake(screens[0]->actualWidth, screens[0]->actualHeight);
}

- (OEIntRect)screenRect
{
    return OEIntRectMake((BUFFER_WIDTH - SCREEN_WIDTH) / 2, 0,
                         SCREEN_WIDTH, screens[0]->actualHeight);
}

- (OEIntSize)aspectSize
{
    return (OEIntSize){ 17, 15 };
}

- (const void*)videoBuffer
{
    return screens[currentScreenIndex]->pixels;
}

- (GLenum)pixelFormat
{
    return GL_RGBA;
}

- (GLenum)pixelType
{
    return GL_UNSIGNED_BYTE;
}

- (GLenum)internalPixelFormat
{
    return GL_RGB;
}

- (double)audioSampleRateForBuffer:(NSUInteger)buffer
{
    return 0; //buffer == 0 ? SAMPLERATE : DAC_FREQUENCY;
}

- (NSUInteger)channelCountForBuffer:(NSUInteger)buffer
{
    return 0; //buffer == 0 ? 2 : 1;
}

- (NSUInteger)audioBufferCount
{
    return 0; //2;
}

- (BOOL)saveStateToFileAtPath:(NSString *)fileName
{
    emulatorSuspend();
    boardSaveState([fileName UTF8String], 1);
    emulatorResume();

    return YES;
}

- (BOOL)loadStateFromFileAtPath:(NSString *)fileName
{
    emulatorSuspend();
    emulatorStop();
    emulatorStart([fileName UTF8String]);

    return YES;
}

#pragma mark - blueMSX callbacks

#pragma mark - Emulation callbacks

void archEmulationStartNotification()
{
}

void archEmulationStopNotification()
{
}

void archEmulationStartFailure()
{
}

#pragma mark - Debugging callbacks

void archTrap(UInt8 value)
{
}

#pragma mark - Input Callbacks

void archPollInput()
{
//    memcpy(eventMap, _core->virtualCodeMap, sizeof(_core->virtualCodeMap));
}

UInt8 archJoystickGetState(int joystickNo)
{
    return 0; // Coleco-specific; unused
}

void archKeyboardSetSelectedKey(int keyCode)
{
}

#pragma mark - Mouse Callbacks

void archMouseGetState(int *dx, int *dy)
{
    // FIXME
//    @autoreleasepool
//    {
//        NSPoint coordinates = theEmulator.mouse.pointerCoordinates;
//        *dx = (int)coordinates.x;
//        *dy = (int)coordinates.y;
//    }
}

int archMouseGetButtonState(int checkAlways)
{
    // FIXME
//    @autoreleasepool
//    {
//        return theEmulator.mouse.buttonState;
//    }
    return 0;
}

void archMouseEmuEnable(AmEnableMode mode)
{
    // FIXME
//    @autoreleasepool
//    {
//        theEmulator.mouse.mouseMode = mode;
//    }
}

void archMouseSetForceLock(int lock)
{
}

#pragma mark - Sound callbacks

void archSoundCreate(Mixer* mixer, UInt32 sampleRate, UInt32 bufferSize, Int16 channels)
{
    // FIXME
//    @autoreleasepool
//    {
//        [theEmulator.sound initializeWithSampleRate:sampleRate
//                                           channels:channels
//                                         bufferSize:bufferSize
//                                              mixer:mixer
//                                     bitsPerChannel:16];
//    }
}

void archSoundDestroy()
{
    // FIXME
//    @autoreleasepool
//    {
//        [theEmulator.sound destroy];
//    }
}

void archSoundResume()
{
    // FIXME
//    @autoreleasepool
//    {
//        [theEmulator.sound resume];
//    }
}

void archSoundSuspend()
{
    // FIXME
//    @autoreleasepool
//    {
//        [theEmulator.sound pause];
//    }
}

#pragma mark - Video callbacks

int archUpdateEmuDisplay(int syncMode)
{
    [_core renderFrame];
    
    return 1;
}

void archUpdateWindow()
{
}

void *archScreenCapture(ScreenCaptureType type, int *bitmapSize, int onlyBmp)
{
    return NULL;
}

@end
