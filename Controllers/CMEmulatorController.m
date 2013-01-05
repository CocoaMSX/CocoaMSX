/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2013 Akop Karapetyan
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
#include <stdlib.h>
#include <stdio.h>

#import "CMAppDelegate.h"

#import "CMAboutController.h"
#import "CMEmulatorController.h"
#import "CMSpecialCartChooserController.h"
#import "CMMachineEditorController.h"

#import "CMPreferences.h"

#include "MsxTypes.h"
#include "AudioMixer.h"
#include "Emulator.h"
#include "Actions.h"
#include "Language.h"
#include "Casette.h"
#include "JoystickPort.h"
#include "PrinterIO.h"
#include "UartIO.h"
#include "MidiIO.h"
#include "LaunchFile.h"
#include "FileHistory.h"
#include "Machine.h"
#include "Board.h"
#include "CommandLine.h"
#include "Debugger.h"

#include "ArchFile.h"
#include "ArchEvent.h"
#include "ArchSound.h"

@interface CMEmulatorController ()

- (CMAppDelegate *)theApp;

- (void)zoomWindowBy:(CGFloat)factor;
- (void)setScreenSize:(NSSize)size
              animate:(BOOL)animate;

- (void)showOpenFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                  completionHandler:(void (^)(NSString *file, NSString *path))handler;
- (void)showOpenFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                    openInDirectory:(NSString *)initialDirectory
                  completionHandler:(void (^)(NSString *file, NSString *path))handler;
- (void)showOpenFileDialogWithTitle:(NSString *)title
                   allowedFileTypes:(NSArray *)allowedFileTypes
                    openInDirectory:(NSString *)initialDirectory
               canChooseDirectories:(BOOL)canChooseDirectories
                  completionHandler:(void (^)(NSString *file, NSString *path))handler;

- (void)showSaveFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                  completionHandler:(void (^)(NSString *file, NSString *path))handler;
- (void)showSaveFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                    openInDirectory:(NSString*)initialDirectory
                  completionHandler:(void (^)(NSString *file, NSString *path))handler;

- (void)insertCartridgeIntoSlot:(NSInteger)slot;
- (void)insertSpecialCartridgeIntoSlot:(NSInteger)slot;
- (void)ejectCartridgeFromSlot:(NSInteger)slot;
- (BOOL)toggleEjectCartridgeMenuItemStatus:(NSMenuItem*)menuItem
                                      slot:(NSInteger)slot;

- (void)insertDiskIntoSlot:(NSInteger)slot;
- (void)ejectDiskFromSlot:(NSInteger)slot;
- (BOOL)toggleEjectDiskMenuItemStatus:(NSMenuItem*)menuItem
                                 slot:(NSInteger)slot;

- (BOOL)toggleEjectCassetteMenuItemStatus:(NSMenuItem*)menuItem;

- (NSString*)fileNameFromCPath:(const char*)filePath;
- (NSString*)fileNameNoExtensionFromCPath:(const char*)filePath;

- (BOOL)mixerEnabledForChannel:(NSInteger)channel;
- (void)toggleMixerChannel:(NSInteger)channel
                 isEnabled:(BOOL)isEnabled;

- (NSInteger)emulationSpeedPercentageFromFrequency:(NSInteger)frequency;
- (NSInteger)emulationFrequencyFromPercentage:(NSInteger)percentage;

- (void)windowKeyDidChange:(BOOL)isKey;

- (void)create;
- (void)destroy;

@end

@implementation CMEmulatorController

@synthesize fpsDisplay = _fpsDisplay;
@synthesize fileToLoadAtStartup = _fileToLoadAtStartup;
@synthesize isInitialized = _isInitialized;

#define WIDTH_DEFAULT   320.0
#define HEIGHT_DEFAULT  240.0

CMEmulatorController *theEmulator = nil; // FIXME

#pragma mark - Initialization, Destruction

- (id)init
{
    if ((self = [super initWithWindowNibName:@"Emulator"]))
    {
        inputDeviceLayouts = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:@"pauseWhenUnfocused"];
    
    [self destroy];
    
    [openRomFileTypes release];
    [openDiskFileTypes release];
    [openCassetteFileTypes release];
    [stateFileTypes release];
    [captureAudioTypes release];
    [captureGameplayTypes release];
    
    [machineEditorController release];
    [aboutController release];
    [cartChooser release];
    [cassetteRepositioner release];
    [preferenceController release];
    
    self.fileToLoadAtStartup = nil;
    
    [keyboard release];
    [mouse release];
    [sound release];
    [joystick release];
    
    [inputDeviceLayouts release];
    
    theEmulator = nil;
    
    [super dealloc];
}

- (void)awakeFromNib
{
    openRomFileTypes = [[NSArray alloc] initWithObjects:@"rom", @"ri", @"mx1", @"mx2", @"zip", nil];
    openDiskFileTypes = [[NSArray alloc] initWithObjects:@"dsk", @"di1", @"di2", @"360", @"720", @"sf7", @"zip", nil];
    openCassetteFileTypes = [[NSArray alloc] initWithObjects:@"cas", @"zip", nil];
    stateFileTypes = [[NSArray alloc] initWithObjects:@"sta", nil];
    captureAudioTypes = [[NSArray alloc] initWithObjects:@"wav", nil];
    captureGameplayTypes = [[NSArray alloc] initWithObjects:@"cap", nil];
    
    [inputDeviceLayouts addObject:[[CMPreferences preferences] keyboardLayout]];
    [inputDeviceLayouts addObject:[[CMPreferences preferences] joystickOneLayout]];
    [inputDeviceLayouts addObject:[[CMPreferences preferences] joystickTwoLayout]];
    
    keyboard = [[CMCocoaKeyboard alloc] init];
    mouse = [[CMCocoaMouse alloc] init];
    sound = [[CMCocoaSound alloc] init];
    joystick = [[CMCocoaJoystick alloc] init];
    
    theEmulator = self; // FIXME
    
    self.isInitialized = NO;
    
    pausedDueToLostFocus = NO;
    
    properties = NULL;
    video = NULL;
    
    [self setScreenSize:NSMakeSize(CMGetIntPref(@"screenWidth"), CMGetIntPref(@"screenHeight"))
                animate:NO];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"pauseWhenUnfocused"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
    [self create];
    [self start];
}

- (CMAppDelegate*)theApp
{
    return (CMAppDelegate*)[NSApp delegate];
}

- (void)create
{
    if (self.isInitialized)
        return;
    
    CMPreferences *prefs = [CMPreferences preferences];
    
    // Initialize paths
    
    propertiesSetDirectory([prefs.appSupportDirectory UTF8String], [prefs.appSupportDirectory UTF8String]);
    actionSetAudioCaptureSetDirectory((char*)[prefs.audioCaptureDirectory UTF8String], "");
    actionSetVideoCaptureSetDirectory((char*)[prefs.videoCaptureDirectory UTF8String], "");
    boardSetDirectory((char*)[prefs.sramDirectory UTF8String]);
    tapeSetDirectory((char*)[prefs.cassetteDataDirectory UTF8String], "");
    mediaDbLoad((char*)[prefs.databaseDirectory UTF8String]);
    machineSetMachineDirectory([prefs.machineDirectory UTF8String]);
    
    properties = propCreate(0, 0, P_KBD_EUROPEAN, 0, "");
    
    strncpy(properties->emulation.machineName,
            [[prefs machineConfiguration] cStringUsingEncoding:NSUTF8StringEncoding],
            PROP_MAXPATH - 1);
    
    // Initialize the emulator
    
    NSInteger frequency = [self emulationFrequencyFromPercentage:[prefs emulationSpeedPercentage]];
    
    properties->emulation.speed = frequency;
    properties->emulation.vdpSyncMode = prefs.vdpSyncMode;
    properties->emulation.syncMethod = P_EMU_SYNCTOVBLANKASYNC;
    
    video = videoCreate();
    videoSetColors(video, properties->video.saturation, properties->video.brightness,
                   properties->video.contrast, properties->video.gamma);
    videoSetScanLines(video, properties->video.scanlinesEnable, properties->video.scanlinesPct);
    videoSetColorSaturation(video, properties->video.colorSaturationEnable, properties->video.colorSaturationWidth);
    videoSetColorMode(video, properties->video.monitorColor);
    
    mixer = mixerCreate();
    
    emulatorInit(properties, mixer);
    actionInit(video, properties, mixer);
    langInit();
    tapeSetReadOnly(properties->cassette.readOnly);
    
    langSetLanguage(properties->language);
    
    joystickPortSetType(0, properties->joy1.typeId);
    joystickPortSetType(1, properties->joy2.typeId);
    
    printerIoSetType(properties->ports.Lpt.type, properties->ports.Lpt.fileName);
    printerIoSetType(properties->ports.Lpt.type, properties->ports.Lpt.fileName);
    uartIoSetType(properties->ports.Com.type, properties->ports.Com.fileName);
    midiIoSetMidiOutType(properties->sound.MidiOut.type, properties->sound.MidiOut.fileName);
    midiIoSetMidiInType(properties->sound.MidiIn.type, properties->sound.MidiIn.fileName);
    ykIoSetMidiInType(properties->sound.YkIn.type, properties->sound.YkIn.fileName);
    
    emulatorRestartSound();
    
    for (int i = 0; i < MIXER_CHANNEL_TYPE_COUNT; i++)
    {
        mixerSetChannelTypeVolume(mixer, i, properties->sound.mixerChannel[i].volume);
        mixerSetChannelTypePan(mixer, i, properties->sound.mixerChannel[i].pan);
        mixerEnableChannelType(mixer, i, properties->sound.mixerChannel[i].enable);
    }
    
    mixerSetMasterVolume(mixer, properties->sound.masterVolume);
    mixerEnableMaster(mixer, properties->sound.masterEnable);
    
    videoSetRgbMode(video, properties->video.driver != P_VIDEO_DRVGDI);
    
    videoUpdateAll(video, properties);
    
    mediaDbSetDefaultRomType(properties->cartridge.defaultType);
    
    for (int i = 0; i < PROP_MAX_CARTS; i++)
    {
        if (properties->media.carts[i].fileName[0])
            insertCartridge(properties, i, properties->media.carts[i].fileName,
                            properties->media.carts[i].fileNameInZip,
                            properties->media.carts[i].type, -1);
        
        updateExtendedRomName(i, properties->media.carts[i].fileName,
                              properties->media.carts[i].fileNameInZip);
    }
    
    for (int i = 0; i < PROP_MAX_DISKS; i++)
    {
        if (properties->media.disks[i].fileName[0])
            insertDiskette(properties, i, properties->media.disks[i].fileName,
                           properties->media.disks[i].fileNameInZip, -1);
        
        updateExtendedDiskName(i, properties->media.disks[i].fileName,
                               properties->media.disks[i].fileNameInZip);
    }
    
    for (int i = 0; i < PROP_MAX_TAPES; i++)
    {
        if (properties->media.tapes[i].fileName[0])
            insertCassette(properties, i, properties->media.tapes[i].fileName,
                           properties->media.tapes[i].fileNameInZip, 0);
        
        updateExtendedCasName(i, properties->media.tapes[i].fileName,
                              properties->media.tapes[i].fileNameInZip);
    }
    
    Machine* machine = machineCreate(properties->emulation.machineName);
    if (machine != NULL)
    {
        boardSetMachine(machine);
        machineDestroy(machine);
    }
    
    boardSetFdcTimingEnable(properties->emulation.enableFdcTiming);
    boardSetY8950Enable(properties->sound.chip.enableY8950);
    boardSetYm2413Enable(properties->sound.chip.enableYM2413);
    boardSetMoonsoundEnable(properties->sound.chip.enableMoonsound);
    boardSetVideoAutodetect(properties->video.detectActiveMonitor);
    
    boardEnableSnapshots(0); // TODO
    
    self.isInitialized = YES;
    
#ifdef DEBUG
    NSLog(@"EmulatorController: initialized");
#endif
}

- (void)destroy
{
    if (!self.isInitialized)
        return;
    
    if ([self isRunning])
        [self stop];
    
    videoDestroy(video);
    propDestroy(properties);
    archSoundDestroy(); // TODO: this doesn't belong here
    mixerDestroy(mixer);
    
    self.isInitialized = NO;
    
#ifdef DEBUG
    NSLog(@"EmulatorController: destroyed");
#endif
}

- (void)start
{
    if (self.isInitialized)
    {
        if ([self isRunning])
            [self stop];
        
        if (self.fileToLoadAtStartup)
        {
            tryLaunchUnknownFile(self.properties, [self.fileToLoadAtStartup UTF8String], YES);
            
            self.fileToLoadAtStartup = nil;
            return;
        }
        
        emulatorStart(NULL);
        
        // Pause if not focused
        [self windowKeyDidChange:self.window.isKeyWindow];
    }
}

- (void)stop
{
    if ([self isInitialized] && [self isRunning])
    {
        emulatorSuspend();
        emulatorStop();
    }
}

- (void)pause
{
    emulatorSetState(EMU_PAUSED);
    debuggerNotifyEmulatorPause();
}

- (void)resume
{
    emulatorSetState(EMU_RUNNING);
    debuggerNotifyEmulatorResume();
}

- (void)performColdReboot
{
    [self destroy];
    [self create];
    [self start];
}

- (CMInputDeviceLayout *)keyboardLayout
{
    return [inputDeviceLayouts objectAtIndex:0];
}

- (CMInputDeviceLayout *)joystickOneLayout
{
    return [inputDeviceLayouts objectAtIndex:1];
}

- (CMInputDeviceLayout *)joystickTwoLayout
{
    return [inputDeviceLayouts objectAtIndex:2];
}

- (NSArray *)inputDeviceLayouts
{
    return inputDeviceLayouts;
}

- (void)updateFps:(CGFloat)fps
{
    if (emulatorGetState() == EMU_PAUSED)
        self.fpsDisplay = CMLoc(@"MsxIsPaused");
    else
        self.fpsDisplay = [NSString stringWithFormat:CMLoc(@"Fps_f"), fps];
}

- (void)setFdcTimingDisabled:(BOOL)fdcTimingDisabled
{
    properties->emulation.enableFdcTiming = !fdcTimingDisabled;
    boardSetFdcTimingEnable(properties->emulation.enableFdcTiming);
}

- (BOOL)fdcTimingDisabled
{
    return !properties->emulation.enableFdcTiming;
}

- (void)setBrightness:(NSInteger)value
{
    properties->video.brightness = value;
    videoUpdateAll(video, properties);
}

- (NSInteger)brightness
{
    return properties->video.brightness;
}

- (void)setContrast:(NSInteger)value
{
    properties->video.contrast = value;
    videoUpdateAll(video, properties);
}

- (NSInteger)contrast
{
    return properties->video.contrast;
}

- (void)setSaturation:(NSInteger)value
{
    properties->video.saturation = value;
    videoUpdateAll(video, properties);
}

- (NSInteger)saturation
{
    return properties->video.saturation;
}

- (void)setGamma:(NSInteger)value
{
    properties->video.gamma = value;
    videoUpdateAll(video, properties);
}

- (NSInteger)gamma
{
    return properties->video.gamma;
}

- (void)setColorMode:(NSInteger)value
{
    properties->video.monitorColor = value;
    videoUpdateAll(video, properties);
}

- (NSInteger)colorMode
{
    return properties->video.monitorColor;
}

- (void)setSignalMode:(NSInteger)value
{
    properties->video.monitorType = value;
    videoUpdateAll(video, properties);
}

- (NSInteger)signalMode
{
    return properties->video.monitorType;
}

- (void)setRfModulation:(NSInteger)value
{
    properties->video.colorSaturationEnable = (value > 0);
    properties->video.colorSaturationWidth = value;
    
    videoUpdateAll(video, properties);
}

- (NSInteger)rfModulation
{
    if (!properties->video.colorSaturationEnable)
        return 0;
    
    return properties->video.colorSaturationWidth;
}

- (void)setScanlines:(NSInteger)value
{
    if ([self isRunning])
    {
        properties->video.scanlinesEnable = (value > 0);
        properties->video.scanlinesPct = 100 - value;
        
        videoUpdateAll(video, properties);
    }
}

- (NSInteger)scanlines
{
    if (!properties->video.scanlinesEnable)
        return 0;
    
    return 100 - properties->video.scanlinesPct;
}

- (void)setStretchHorizontally:(BOOL)value
{
    properties->video.horizontalStretch = value;
    videoUpdateAll(video, properties);
}

- (BOOL)stretchHorizontally
{
    return properties->video.horizontalStretch;
}

- (void)setDeinterlace:(BOOL)value
{
    properties->video.deInterlace = value;
    videoUpdateAll(video, properties);
}

- (BOOL)deinterlace
{
    return properties->video.deInterlace;
}

- (BOOL)mixerEnabledForChannel:(NSInteger)channel
{
    return properties->sound.mixerChannel[channel].enable;
}

- (void)toggleMixerChannel:(NSInteger)channel
                 isEnabled:(BOOL)isEnabled
{
    properties->sound.mixerChannel[channel].enable = isEnabled;
    mixerEnableChannelType(mixer, channel, isEnabled);
}

- (void)setMsxAudioEnabled:(BOOL)msxAudioEnabled
{
    [self toggleMixerChannel:MIXER_CHANNEL_MSXAUDIO isEnabled:msxAudioEnabled];
}

- (BOOL)msxAudioEnabled
{
    return [self mixerEnabledForChannel:MIXER_CHANNEL_MSXAUDIO];
}

- (void)setMsxMusicEnabled:(BOOL)msxMusicEnabled
{
    [self toggleMixerChannel:MIXER_CHANNEL_MSXMUSIC isEnabled:msxMusicEnabled];
}

- (BOOL)msxMusicEnabled
{
    return [self mixerEnabledForChannel:MIXER_CHANNEL_MSXMUSIC];
}

- (void)setMoonSoundEnabled:(BOOL)moonSoundEnabled
{
    [self toggleMixerChannel:MIXER_CHANNEL_MOONSOUND isEnabled:moonSoundEnabled];
}

- (BOOL)moonSoundEnabled
{
    return [self mixerEnabledForChannel:MIXER_CHANNEL_MOONSOUND];
}

- (NSInteger)emulationSpeedPercentageFromFrequency:(NSInteger)frequency
{
    NSInteger logFrequency = 3579545 * pow(2.0, (properties->emulation.speed - 50) / 15.0515);
    
    return logFrequency * 100 / 3579545;
}

- (NSInteger)emulationFrequencyFromPercentage:(NSInteger)percentage
{
    CGFloat frequency = percentage * 3579545.0 / 100.0;
    CGFloat logFrequency = log(frequency / 3579545.0) / log(2.0);
    
    return (NSInteger)(50.0 + 15.0515 * logFrequency);
}

- (NSInteger)emulationSpeedPercentage
{
#ifdef DEBUG
    NSLog(@"P: %d CPU: %d",
          (int)[self emulationSpeedPercentageFromFrequency:properties->emulation.speed],
          properties->emulation.speed);
#endif
    
    return [self emulationSpeedPercentageFromFrequency:properties->emulation.speed];
}

- (void)setEmulationSpeedPercentage:(NSInteger)percentage
{
#ifdef DEBUG
    NSLog(@"P: %d CPU: %d",
          (int)percentage,
          (int)[self emulationFrequencyFromPercentage:percentage]);
#endif

    properties->emulation.speed = [self emulationFrequencyFromPercentage:percentage];
    emulatorSetFrequency(properties->emulation.speed, NULL);
}

#pragma mark - Machine Configuration

+ (NSArray *)machineConfigurations
{
    NSMutableArray *machineConfigurations = [NSMutableArray array];
    
    char **machineNames = machineGetAvailable(1);
    while (*machineNames != NULL)
    {
        NSString *machineName =  [NSString stringWithCString:*machineNames
                                                    encoding:NSUTF8StringEncoding];
        [machineConfigurations addObject:machineName];
        
        machineNames++;
    }
    
    return machineConfigurations;
}

- (NSString *)currentMachineConfiguration
{
    return [NSString stringWithCString:properties->emulation.machineName
                              encoding:NSUTF8StringEncoding];
}

#pragma mark - Input Peripherals

- (NSInteger)deviceInJoystickPort1
{
    return properties->joy1.typeId;
}

- (void)setDeviceInJoystickPort1:(NSInteger)deviceInJoystickPort1
{
    properties->joy1.typeId = deviceInJoystickPort1;
    joystickPortSetType(0, deviceInJoystickPort1);
}

- (NSInteger)deviceInJoystickPort2
{
    return properties->joy2.typeId;
}

- (void)setDeviceInJoystickPort2:(NSInteger)deviceInJoystickPort2
{
    properties->joy2.typeId = deviceInJoystickPort2;
    joystickPortSetType(1, deviceInJoystickPort2);
}

#pragma mark - Properties

- (BOOL)isRunning
{
    NSInteger machineState = emulatorGetState();
    return (machineState == EMU_RUNNING || machineState == EMU_PAUSED);
}

- (BOOL)isPaused
{
    return (emulatorGetState() == EMU_PAUSED);
}

- (NSInteger)machineState
{
    return emulatorGetState();
}

- (CMCocoaKeyboard *)keyboard
{
    return keyboard;
}

- (CMCocoaMouse *)mouse
{
    return mouse;
}

- (CMCocoaSound *)sound
{
    return sound;
}

- (CMCocoaJoystick *)joystick
{
    return joystick;
}

- (Properties *)properties
{
    return properties;
}

- (Video *)video
{
    return video;
}

- (CMMsxDisplayView *)screen
{
    return screen;
}

- (BOOL)isInFullScreenMode
{
    return (self.window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask;
}

#pragma mark - Private methods

- (void)zoomWindowBy:(CGFloat)factor
{
    [self setScreenSize:NSMakeSize(WIDTH_DEFAULT * factor, HEIGHT_DEFAULT * factor)
                animate:YES];
}

- (void)setScreenSize:(NSSize)size
              animate:(BOOL)animate
{
    if ([self isInFullScreenMode])
        [self.window toggleFullScreen:nil];
    
    NSSize windowSize = self.window.frame.size;
    NSSize screenSize = screen.frame.size;
    
    CGFloat newWidth = size.width + (windowSize.width - screenSize.width);
    CGFloat newHeight = size.height + (windowSize.height - screenSize.height);
    
    [self.window setFrame:NSMakeRect(self.window.frame.origin.x,
                                     self.window.frame.origin.y,
                                     newWidth, newHeight)
             display:YES
             animate:animate];
}

- (void)showOpenFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                  completionHandler:(void (^)(NSString *file, NSString *path))handler
{
    [self showOpenFileDialogWithTitle:title
                     allowedFileTypes:allowedFileTypes
                      openInDirectory:nil
                 canChooseDirectories:NO
                    completionHandler:handler];
}

- (void)showOpenFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                    openInDirectory:(NSString *)initialDirectory
                  completionHandler:(void (^)(NSString *file, NSString *path))handler
{
    [self showOpenFileDialogWithTitle:title
                     allowedFileTypes:allowedFileTypes
                      openInDirectory:initialDirectory
                 canChooseDirectories:NO
                    completionHandler:handler];
}

- (void)showOpenFileDialogWithTitle:(NSString *)title
                   allowedFileTypes:(NSArray *)allowedFileTypes
                    openInDirectory:(NSString *)initialDirectory
               canChooseDirectories:(BOOL)canChooseDirectories
                  completionHandler:(void (^)(NSString *file, NSString *path))handler
{
    NSOpenPanel* dialog = [NSOpenPanel openPanel];
    
    dialog.title = title;
    dialog.canChooseFiles = YES;
    dialog.canChooseDirectories = canChooseDirectories;
    dialog.canCreateDirectories = YES;
    dialog.allowedFileTypes = allowedFileTypes;
    
    if (initialDirectory)
        dialog.directoryURL = [NSURL fileURLWithPath:initialDirectory];
    
    [dialog beginSheetModalForWindow:self.window
                   completionHandler:^(NSInteger result)
     {
         NSString *file = nil;
         NSString *filePath = nil;
         
         if (result == NSFileHandlingPanelOKButton)
         {
             file = [dialog URL].path;
             filePath = dialog.directoryURL.path;
         }
         
         handler(file, filePath);
     }];
}

- (void)showSaveFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                    openInDirectory:(NSString*)initialDirectory
                  completionHandler:(void (^)(NSString *file, NSString *path))handler
{
    NSSavePanel *dialog = [NSSavePanel savePanel];
    
    dialog.title = title;
    dialog.canCreateDirectories = YES;
    dialog.allowedFileTypes = allowedFileTypes;
    
    if (initialDirectory)
        dialog.directoryURL = [NSURL fileURLWithPath:initialDirectory];
    
    [dialog beginSheetModalForWindow:self.window
                   completionHandler:^(NSInteger result)
     {
         NSString *file = nil;
         NSString *filePath = nil;
         
         if (result == NSFileHandlingPanelOKButton)
         {
             file = [dialog URL].path;
             filePath = dialog.directoryURL.path;
         }
         
         handler(file, filePath);
     }];
}

- (void)showSaveFileDialogWithTitle:(NSString*)title
                   allowedFileTypes:(NSArray*)allowedFileTypes
                  completionHandler:(void (^)(NSString *file, NSString *path))handler
{
    [self showSaveFileDialogWithTitle:title
                     allowedFileTypes:allowedFileTypes
                      openInDirectory:nil
                    completionHandler:handler];
}

- (void)insertCartridgeIntoSlot:(NSInteger)slot
{
    if (!self.isInitialized)
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"InsertCartridge")
                     allowedFileTypes:openRomFileTypes
                    completionHandler:^(NSString *file, NSString *path)
    {
        if (file)
        {
            [CMPreferences preferences].cartridgeDirectory = path;
            [self insertCartridge:file slot:slot];
        }
    }];
}

- (BOOL)insertCartridge:(NSString *)cartridge
                   slot:(NSInteger)slot
{
    if (!self.isInitialized || ![[NSFileManager defaultManager] fileExistsAtPath:cartridge])
        return NO;
    
    emulatorSuspend();
    insertCartridge(properties, slot, [cartridge UTF8String], NULL, ROM_UNKNOWN, 0);
    emulatorResume();
    
    return YES;
}

- (BOOL)insertUnknownMedia:(NSString *)media
{
    if (self.isRunning)
        [self stop];
    
    return tryLaunchUnknownFile(self.properties, [media UTF8String], YES) != 0;
}

- (void)insertSpecialCartridgeIntoSlot:(NSInteger)slot
{
    if (!self.isInitialized)
        return;
    
    [cartChooser release];
    cartChooser = [[CMSpecialCartChooserController alloc] init];
    cartChooser.delegate = self;
    
    [cartChooser showSheetForWindow:self.window cartridgeSlot:slot];
}

- (void)ejectCartridgeFromSlot:(NSInteger)slot
{
    if (![self isRunning])
        return;
    
    actionCartRemove(slot);
}

- (NSString*)fileNameFromCPath:(const char*)filePath
{
    if (!filePath || !*filePath)
        return nil;
    
    NSString *filePathAsString = [NSString stringWithUTF8String:filePath];
    
    return [filePathAsString lastPathComponent];
}

- (NSString*)fileNameNoExtensionFromCPath:(const char*)filePath
{
    return [[self fileNameFromCPath:filePath] stringByDeletingPathExtension];
}

- (BOOL)toggleEjectCartridgeMenuItemStatus:(NSMenuItem*)menuItem
                                      slot:(NSInteger)slot
{
    if (self.isInitialized)
    {
        NSString *displayName = [self fileNameFromCPath:properties->media.carts[slot].fileName];
        
        if (displayName)
        {
            menuItem.title = [NSString stringWithFormat:CMLoc(@"EjectMedia_f"),
                              displayName];
            return YES;
        }
    }
    
    menuItem.title = CMLoc(@"EjectCartridge");
    return NO;
}

- (void)insertDiskIntoSlot:(NSInteger)slot
{
    if (!self.isInitialized)
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"InsertDisk")
                     allowedFileTypes:openDiskFileTypes
                      openInDirectory:[CMPreferences preferences].diskDirectory
                 canChooseDirectories:YES
                    completionHandler:^(NSString *file, NSString *path)
     {
         if (file)
         {
             emulatorSuspend();
             
             BOOL isDirectory;
             const char *fileCstr = [file UTF8String];
             
             [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory];
             
             if (isDirectory)
             {
                 // Insert directory
                 
                 strcpy(properties->media.disks[slot].directory, fileCstr);
                 insertDiskette(properties, slot, fileCstr, NULL, 0);
             }
             else
             {
                 // Insert disk file
                 
                 insertDiskette(properties, slot, fileCstr, NULL, 0);
                 [CMPreferences preferences].diskDirectory = path;
             }
             
             emulatorResume();
         }
     }];
}

- (void)ejectDiskFromSlot:(NSInteger)slot
{
    actionDiskRemove(slot);
}

- (BOOL)toggleEjectDiskMenuItemStatus:(NSMenuItem*)menuItem
                                 slot:(NSInteger)slot
{
    if (self.isInitialized)
    {
        NSString *displayName = [self fileNameFromCPath:properties->media.disks[slot].fileName];
        
        if (displayName)
        {
            menuItem.title = [NSString stringWithFormat:CMLoc(@"EjectMedia_f"),
                              displayName];
            return YES;
        }
    }
    
    menuItem.title = CMLoc(@"EjectDisk");
    return NO;
}

- (BOOL)toggleEjectCassetteMenuItemStatus:(NSMenuItem*)menuItem
{
    if (self.isInitialized)
    {
        NSString *displayName = [self fileNameFromCPath:properties->media.tapes[0].fileName];
        
        if (displayName)
        {
            menuItem.title = [NSString stringWithFormat:CMLoc(@"EjectMedia_f"),
                              displayName];
            
            return YES;
        }
    }
    
    menuItem.title = CMLoc(@"EjectCassette");
    return NO;
}

- (void)windowKeyDidChange:(BOOL)isKey
{
    mouse.emulatorHasFocus = isKey;
    keyboard.emulatorHasFocus = isKey;
    joystick.emulatorHasFocus = isKey;
    
    BOOL pauseWhenUnfocused = [[NSUserDefaults standardUserDefaults] boolForKey:@"pauseWhenUnfocused"];
    
    if (isKey)
    {
        if ([self isPaused] && pausedDueToLostFocus)
            [self resume];
        
        pausedDueToLostFocus = NO;
    }
    else
    {
        if ([self isRunning] && pauseWhenUnfocused)
        {
            [self pause];
            pausedDueToLostFocus = YES;
        }
    }
}

#pragma mark - IBActions

- (void)openAbout:(id)sender
{
    if (!aboutController)
        aboutController = [[CMAboutController alloc] init];
    
    [aboutController showWindow:self];
}

- (void)openPreferences:(id)sender
{
    if (!self.isInitialized)
        return;
    
    if (!preferenceController)
        preferenceController = [[CMPreferenceController alloc] initWithEmulator:self];
    
    [preferenceController showWindow:self];
}

// File menu

- (void)insertCartridgeSlot1:(id)sender
{
    [self insertCartridgeIntoSlot:0];
}

- (void)insertCartridgeSlot2:(id)sender
{
    [self insertCartridgeIntoSlot:1];
}

- (void)insertSpecialCartridgeSlot1:(id)sender
{
    [self insertSpecialCartridgeIntoSlot:0];
}

- (void)insertSpecialCartridgeSlot2:(id)sender
{
    [self insertSpecialCartridgeIntoSlot:1];
}

- (void)ejectCartridgeSlot1:(id)sender
{
    [self ejectCartridgeFromSlot:0];
}

- (void)ejectCartridgeSlot2:(id)sender
{
    [self ejectCartridgeFromSlot:1];
}

- (void)toggleCartAutoReset:(id)sender
{
    if (self.isInitialized)
        properties->cartridge.autoReset = !properties->cartridge.autoReset;
}

- (void)insertDiskSlot1:(id)sender
{
    [self insertDiskIntoSlot:0];
}

- (void)insertDiskSlot2:(id)sender
{
    [self insertDiskIntoSlot:1];
}

- (void)ejectDiskSlot1:(id)sender
{
    [self ejectDiskFromSlot:0];
}

- (void)ejectDiskSlot2:(id)sender
{
    [self ejectDiskFromSlot:1];
}

- (void)toggleDiskAutoReset:(id)sender
{
    if (self.isInitialized)
        properties->diskdrive.autostartA = !properties->diskdrive.autostartA;
}

- (void)insertCassette:(id)sender
{
    if (!self.isInitialized)
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"InsertCassette")
                     allowedFileTypes:openCassetteFileTypes
                      openInDirectory:[CMPreferences preferences].cassetteDirectory
                    completionHandler:^(NSString *file, NSString *path)
    {
        if (file)
        {
            emulatorSuspend();
            
            if (properties->cassette.rewindAfterInsert)
                tapeRewindNextInsert();
            
            insertCassette(properties, 0, [file UTF8String], NULL, 0);
            [CMPreferences preferences].cassetteDirectory = path;
            
            emulatorResume();
        }
    }];
}

- (void)ejectCassette:(id)sender
{
    actionCasRemove();
}

- (void)toggleCassetteAutoRewind:(id)sender
{
    if (self.isInitialized)
        properties->cassette.rewindAfterInsert = !properties->cassette.rewindAfterInsert;
}

- (void)toggleCassetteWriteProtect:(id)sender
{
    if (self.isInitialized)
        properties->cassette.readOnly ^= 1;
}

- (void)rewindCassette:(id)sender
{
    if (self.isInitialized)
        actionCasRewind();
}

- (void)repositionCassette:(id)sender
{
    if (!self.isInitialized || !(*properties->media.tapes[0].fileName))
        return;
    
    [cassetteRepositioner release];
    cassetteRepositioner = [[CMRepositionCassetteController alloc] init];
    cassetteRepositioner.delegate = self;
    
    [cassetteRepositioner showSheetForWindow:self.window];
}

// MSX menu

- (void)statusMsx:(id)sender
{
}

- (void)resetMsx:(id)sender
{
    if ([self isRunning])
        actionEmuResetSoft();
}

- (void)shutDownMsx:(id)sender
{
    if ([self isRunning])
    {
        [self destroy];
        [self stop];
    }
    else
    {
        [self create];
        [self start];
    }
}

- (void)pauseMsx:(id)sender
{
    NSInteger machineState = emulatorGetState();
    
    if (machineState == EMU_PAUSED)
    {
        [self resume];
    }
    else if (machineState == EMU_RUNNING)
    {
        [self pause];
    }
}

- (void)loadState:(id)sender
{
    if (!self.isInitialized)
        return;
    
    NSInteger emulatorState = emulatorGetState();
    if (emulatorState != EMU_RUNNING && emulatorState != EMU_PAUSED)
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"LoadSnapshot")
                     allowedFileTypes:stateFileTypes
                      openInDirectory:[CMPreferences preferences].snapshotDirectory
                    completionHandler:^(NSString *file, NSString *path)
    {
        if (file)
        {
            emulatorSuspend();
            emulatorStop();
            emulatorStart([file UTF8String]);
            
            [CMPreferences preferences].snapshotDirectory = path;
        }
    }];
}

- (void)saveState:(id)sender
{
    if (!self.isInitialized || !self.isRunning)
        return;
    
    emulatorSuspend();
    
    [self showSaveFileDialogWithTitle:CMLoc(@"SaveSnapshot")
                     allowedFileTypes:stateFileTypes
                      openInDirectory:[CMPreferences preferences].snapshotDirectory
                    completionHandler:^(NSString *file, NSString *path)
     {
         if (file)
         {
             boardSaveState([file UTF8String], 1);
             
             CMPreferences *preferences = [CMPreferences preferences];
             preferences.snapshotDirectory = path;
             
             if (preferences.snapshotIconStyle != CMSnapshotIconStyleNone)
             {
                 NSImage *screenshot = [screen captureScreen:YES];
                 
                 if (screenshot)
                 {
                     NSImage *icon = nil;
                     
                     if (preferences.snapshotIconStyle == CMSnapshotIconStyleFilmstrip)
                     {
                         CGFloat iconDim = 512;
                         CGFloat insetSize = 360;
                         
                         icon = [NSImage imageNamed:@"filmstrip"];
                         [icon setSize:NSMakeSize(iconDim, iconDim)];
                         
                         [icon lockFocus];
                         
                         [screenshot drawAtPoint:NSMakePoint(76, 73)
                                        fromRect:NSMakeRect((screenshot.size.width - insetSize) / 2.0,
                                                            (screenshot.size.height - insetSize) / 2.0,
                                                            insetSize, insetSize)
                                       operation:NSCompositeSourceOver
                                        fraction:1.0];
                         
                         [icon unlockFocus];
                     }
                     else if (preferences.snapshotIconStyle == CMSnapshotIconStyleScreen)
                     {
                         CGFloat iconDim = MIN(screenshot.size.width, screenshot.size.height);
                         
                         icon = [[[NSImage alloc] initWithSize:NSMakeSize(iconDim, iconDim)] autorelease];
                         
                         [icon lockFocus];
                         
                         [screenshot drawAtPoint:NSZeroPoint
                                        fromRect:NSMakeRect((screenshot.size.width - iconDim) / 2.0,
                                                            (screenshot.size.height - iconDim) / 2.0,
                                                            iconDim, iconDim)
                                       operation:NSCompositeSourceOver
                                        fraction:1.0];
                         
                         [icon unlockFocus];
                     }
                     
                     [[NSWorkspace sharedWorkspace] setIcon:icon forFile:file options:NSExcludeQuickDrawElementsIconCreationOption];
                 }
             }
         }
         
         emulatorResume();
     }];
}

- (void)saveScreenshot:(id)sender
{
    if (!self.isInitialized || ![self isRunning])
        return;
    
    emulatorSuspend();
    
    [self showSaveFileDialogWithTitle:CMLoc(@"SaveScreenshot")
                     allowedFileTypes:[NSArray arrayWithObjects:@"png", nil]
                    completionHandler:^(NSString *file, NSString *path)
     {
         if (file)
         {
             NSImage *image = [screen captureScreen:YES];
             if (image && [image representations].count > 0)
             {
                 NSBitmapImageRep *rep = [[image representations] objectAtIndex:0];
                 NSData *pngData = [rep representationUsingType:NSPNGFileType properties:nil];
                 
                 [pngData writeToFile:file atomically:NO];
             }
         }
         
         emulatorResume();
     }];
}

- (void)recordAudio:(id)sender
{
    if (!self.isInitialized || ![self isRunning])
        return;
    
    if (mixerIsLogging(mixer))
        mixerStopLog(mixer);
    else
    {
        emulatorSuspend();
        
        [self showSaveFileDialogWithTitle:CMLoc(@"CaptureAudio")
                         allowedFileTypes:captureAudioTypes
                          openInDirectory:[CMPreferences preferences].audioCaptureDirectory
                        completionHandler:^(NSString *file, NSString *path)
         {
             if (file)
             {
                 mixerStartLog(mixer, [file UTF8String]);
                 [CMPreferences preferences].audioCaptureDirectory = path;
             }
             
             emulatorResume();
         }];
    }
}

- (void)recordGameplay:(id)sender
{
    if (!self.isInitialized || ![self isRunning])
        return;
    
    emulatorSuspend();
    
    if (!boardCaptureIsRecording())
    {
        [self showSaveFileDialogWithTitle:CMLoc(@"CaptureGameplay")
                         allowedFileTypes:captureGameplayTypes
                          openInDirectory:[CMPreferences preferences].videoCaptureDirectory
                        completionHandler:^(NSString *file, NSString *path)
         {
             if (file)
             {
                 const char *destination = [file UTF8String];
                 strncpy(properties->filehistory.videocap, destination, PROP_MAXPATH - 1);
                 
                 boardCaptureStart(destination);
                 
                 [CMPreferences preferences].videoCaptureDirectory = path;
             }
         }];
    }
    else
    {
        boardCaptureStop();
    }
    
    emulatorResume();
}

- (void)editMachineSettings:(id)sender
{
    if (!self.isInitialized)
        return;
    
    if (!machineEditorController)
        machineEditorController = [[CMMachineEditorController alloc] init];
    
    [machineEditorController showWindow:self];
}

// View menu

- (void)normalSize:(id)sender
{
    [self zoomWindowBy:1.0];
}

- (void)doubleSize:(id)sender
{
    [self zoomWindowBy:2.0];
}

- (void)toggleFullScreen:(id)sender
{
    // TODO: fullScreen support for Snow Leopard
    if ([self.window respondsToSelector:@selector(toggleFullScreen:)])
        [self.window toggleFullScreen:sender];
}

#pragma mark - blueMSX implementations - emulation

void archEmulationStartNotification()
{
}

void archEmulationStopNotification()
{
}

void archEmulationStartFailure()
{
}

#pragma mark - blueMSX implementations - debugging

void archTrap(UInt8 value)
{
}

#pragma mark - Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"pauseWhenUnfocused"])
    {
        [self windowKeyDidChange:self.window.isKeyWindow];
    }
}

#pragma mark - NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - NSWindowDelegate

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    NSRect windowFrame = [self.window frame];
    NSRect viewRect = [self.screen convertRect:[self.screen bounds] toView: nil];
    NSRect contentRect = [self.window contentRectForFrameRect:windowFrame];
    
    float marginY = viewRect.origin.y + windowFrame.size.height - contentRect.size.height;
    float marginX = contentRect.size.width - viewRect.size.width;
    
    // Clamp the minimum height
    if ((frameSize.height - marginY) < HEIGHT_DEFAULT)
        frameSize.height = HEIGHT_DEFAULT + marginY;
    
    // Set the screen width as a percentage of the screen height
    frameSize.width = (frameSize.height - marginY) / (HEIGHT_DEFAULT / WIDTH_DEFAULT) + marginX;
    
    return frameSize;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self stop];
    [self destroy];
    
    if (([self.window styleMask] & NSFullScreenWindowMask) != NSFullScreenWindowMask)
    {
        CMSetIntPref(@"screenWidth", screen.bounds.size.width);
        CMSetIntPref(@"screenHeight", screen.bounds.size.height);
    }
    
    [[NSApplication sharedApplication] terminate:self];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self windowKeyDidChange:YES];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [self windowKeyDidChange:NO];
}

#define CMMinYEdgeHeight 32.0

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"EmulatorController: willEnterFullScreen");
#endif
    
    // Save the screen size first
    CMSetIntPref(@"screenWidth", screen.bounds.size.width);
    CMSetIntPref(@"screenHeight", screen.bounds.size.height);
    
    [self.window setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
    [self.window setContentBorderThickness:0 forEdge:NSMinYEdge];
    
    NSSize newScreenSize = screen.frame.size;
    [screen setFrame:NSMakeRect(0, 0, newScreenSize.width, newScreenSize.height + CMMinYEdgeHeight)];
    [fpsCounter setHidden:YES];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"EmulatorController: willExitFullScreen");
#endif
    
    [self.window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [self.window setContentBorderThickness:CMMinYEdgeHeight forEdge:NSMinYEdge];
    
    NSSize newScreenSize = screen.frame.size;
    [screen setFrame:NSMakeRect(0, CMMinYEdgeHeight, newScreenSize.width, newScreenSize.height - CMMinYEdgeHeight)];
    [fpsCounter setHidden:NO];
}

#pragma mark - SpecialCartSelectedDelegate

- (void)cartSelectedOfType:(NSInteger)romType romName:(const char*)romName slot:(NSInteger)slot;
{
#ifdef DEBUG
    NSLog(@"EmulatorController:cartSelectedOfType %d '%s'",
          (int)romType, romName);
#endif
    
    emulatorSuspend();
    insertCartridge(self.properties, slot, romName, NULL, romType, 0);
    emulatorResume();
}

#pragma mark - CassetteRepositionDelegate

- (void)cassetteRepositionedTo:(NSInteger)position
{
#ifdef DEBUG
    NSLog(@"EmulatorController:cassetteRepositionedTo:%d", (int)position);
#endif
    
    emulatorSuspend();
    tapeSetCurrentPos(position);
    emulatorResume();
}

#pragma mark - NSUserInterfaceValidation

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
    NSMenuItem *menuItem = (NSMenuItem*)item;
    
    NSInteger machineState = [self machineState];
    BOOL isRunning = [self isRunning];
    
    if (item.action == @selector(toggleCartAutoReset:))
    {
        menuItem.state = (properties->cartridge.autoReset) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if (item.action == @selector(insertCartridgeSlot1:) ||
             item.action == @selector(insertCartridgeSlot2:) ||
             item.action == @selector(insertDiskSlot1:) ||
             item.action == @selector(insertDiskSlot2:) ||
             item.action == @selector(insertCassette:))
    {
        return isRunning;
    }
    else if (item.action == @selector(ejectCartridgeSlot1:))
        return [self toggleEjectCartridgeMenuItemStatus:menuItem slot:0];
    else if (item.action == @selector(ejectCartridgeSlot2:))
        return [self toggleEjectCartridgeMenuItemStatus:menuItem slot:1];
    else if (item.action == @selector(toggleDiskAutoReset:))
    {
        menuItem.state = (properties->diskdrive.autostartA) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if (item.action == @selector(ejectDiskSlot1:))
        return [self toggleEjectDiskMenuItemStatus:menuItem slot:0];
    else if (item.action == @selector(ejectDiskSlot2:))
        return [self toggleEjectDiskMenuItemStatus:menuItem slot:1];
    else if (item.action == @selector(ejectCassette:))
        return [self toggleEjectCassetteMenuItemStatus:menuItem];
    else if (item.action == @selector(toggleCassetteAutoRewind:))
    {
        menuItem.state = (properties->cassette.rewindAfterInsert) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if (item.action == @selector(toggleCassetteWriteProtect:))
    {
        menuItem.state = (properties->cassette.readOnly) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if (item.action == @selector(rewindCassette:))
        return (*properties->media.tapes[0].fileName) ? NSOnState : NSOffState;
    else if (item.action == @selector(repositionCassette:))
        return (*properties->media.tapes[0].fileName) ? NSOnState : NSOffState;
    else if (item.action == @selector(normalSize:) ||
             item.action == @selector(doubleSize:))
    {
        return ![self isInFullScreenMode];
    }
    else if (item.action == @selector(loadState:))
    {
        return isRunning;
    }
    else if (item.action == @selector(saveState:))
    {
        return isRunning;
    }
    else if (item.action == @selector(statusMsx:))
    {
        if (machineState == EMU_RUNNING)
            menuItem.title = CMLoc(@"MsxIsRunning");
        else if (machineState == EMU_PAUSED)
            menuItem.title = CMLoc(@"MsxIsPaused");
        else if (machineState == EMU_SUSPENDED)
            menuItem.title = CMLoc(@"MsxIsSuspended");
        else if (machineState == EMU_STOPPED)
            menuItem.title = CMLoc(@"MsxIsOff");
        else
            menuItem.title = CMLoc(@"MsxIsUnknown");
        
        return NO; // always disabled
    }
    else if (item.action == @selector(resetMsx:))
    {
        // Resetting while paused leads to some odd behavior
        return (machineState == EMU_RUNNING);
    }
    else if (item.action == @selector(shutDownMsx:))
    {
        if (isRunning)
            menuItem.title = CMLoc(@"ShutDown");
        else
            menuItem.title = CMLoc(@"StartUp");
    }
    else if (item.action == @selector(pauseMsx:))
    {
        if (machineState == EMU_PAUSED)
            menuItem.title = CMLoc(@"Resume");
        else
            menuItem.title = CMLoc(@"Pause");
        
        return isRunning;
    }
    else if (item.action == @selector(saveScreenshot:))
    {
        return isRunning;
    }
    else if (item.action == @selector(recordAudio:))
    {
        if (!mixerIsLogging(mixer))
            menuItem.title = CMLoc(@"RecordAudioEll");
        else
            menuItem.title = CMLoc(@"StopRecording");
        
        return isRunning;
    }
    else if (item.action == @selector(recordGameplay:))
    {
        if (!boardCaptureIsRecording())
            menuItem.title = CMLoc(@"RecordGameplayEll");
        else
            menuItem.title = CMLoc(@"StopRecording");
        
        return isRunning;
    }
    else if (item.action == @selector(toggleFullScreen:))
    {
        // TODO: fullScreen support for Snow Leopard
        return [self.window respondsToSelector:@selector(toggleFullScreen:)];
    }
    
    return menuItem.isEnabled;
}

@end
