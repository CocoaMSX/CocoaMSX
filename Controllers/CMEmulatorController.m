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
#include <stdlib.h>
#include <stdio.h>

#import "CMAppDelegate.h"

#import "CMAboutController.h"
#import "CMEmulatorController.h"
#import "CMSpecialCartChooserController.h"
#import "CMMachineEditorController.h"

#import "CMPreferences.h"
#import "CMMSXKeyboard.h"

#import "NSString+CMExtensions.h"

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
#include "Led.h"
#include "Debugger.h"
#include "Switches.h"

#include "ArchFile.h"
#include "ArchEvent.h"
#include "ArchSound.h"

#define LED_CAPS_LOCK 0x001
#define LED_CODE      0x002
#define LED_TURBO_R   0x004
#define LED_PAUSE     0x008
#define LED_RENSHA    0x010
#define LED_FDD0      0x020
#define LED_FDD1      0x040
#define LED_HD        0x080
#define LED_CASSETTE  0x100
#define LED_POWER     0x200

@interface CMEmulatorController ()

- (CMAppDelegate *)theApp;

- (int)ledState;
- (void)toggleIfLedState:(int)state
              ledBitMask:(int)bitMask
               imageView:(NSImageView *)imageView
           offStateImage:(NSString *)offImage
            onStateImage:(NSString *)onImage;

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
                   useAccessoryView:(NSView *)accessoryView
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

- (void)insertDiskAtPath:(NSString *)path
                    slot:(NSInteger)slot;
- (void)ejectDiskFromSlot:(NSInteger)slot;
- (BOOL)toggleEjectDiskMenuItemStatus:(NSMenuItem*)menuItem
                                 slot:(NSInteger)slot;

- (BOOL)toggleEjectCassetteMenuItemStatus:(NSMenuItem*)menuItem;

- (void)insertCassetteAtPath:(NSString *)path;

- (NSString*)fileNameFromCPath:(const char*)filePath;
- (NSString*)fileNameNoExtensionFromCPath:(const char*)filePath;

- (NSInteger)emulationSpeedPercentageFromFrequency:(NSInteger)frequency;
- (NSInteger)emulationFrequencyFromPercentage:(NSInteger)percentage;

- (void)windowKeyDidChange:(BOOL)isKey;

- (void)create;
- (void)destroy;

- (BOOL)isLionFullscreenAvailable;
- (void)toggleFullScreen;
- (NSWindow *)activeWindow;
- (void)enterLegacyFullscreen;
- (void)exitLegacyFullscreen;

- (BOOL)isStatusBarVisible;
- (void)setIsStatusBarVisible:(BOOL)isVisible;

- (void)cleanupTemporaryCaptureFile;

- (void)addRecentMediaItemWithURL:(NSURL *)url
                           action:(SEL)action
                           parent:(NSMenuItem *)parent;
- (void)clearRecentMediaItemsInMenu:(NSMenuItem *)menuItem;
- (void)rebuildRecentItemsMenus;

@end

@implementation CMEmulatorController

@synthesize fpsDisplay = _fpsDisplay;
@synthesize fileToLoadAtStartup = _fileToLoadAtStartup;
@synthesize isInitialized = _isInitialized;
@synthesize currentlyLoadedCaptureFilePath = _currentlyLoadedCaptureFilePath;
@synthesize lastSavedState = _lastSavedState;
@synthesize lastLoadedState = _lastLoadedState;

#define WIDTH_DEFAULT   544.0
#define HEIGHT_DEFAULT  480.0
#define WIDTH_TO_HEIGHT_RATIO (WIDTH_DEFAULT / HEIGHT_DEFAULT)

#define CMMinYEdgeHeight 32.0 // Height of the status bar at bottom

CMEmulatorController *theEmulator = nil; // FIXME

#pragma mark - Initialization, Destruction

- (id)init
{
    if ((self = [super initWithWindowNibName:@"Emulator"]))
    {
        inputDeviceLayouts = [[NSMutableArray alloc] init];
        
        listOfPreferenceKeysToObserve = [[NSArray alloc] initWithObjects:
                                         @"pauseWhenUnfocused",
                                         @"emulationSpeedPercentage",
                                         @"enableFloppyTiming",
                                         @"videoBrightness",
                                         @"videoContrast",
                                         @"videoSaturation",
                                         @"videoGamma",
                                         @"videoRfModulation",
                                         @"videoEnableDeInterlacing",
                                         @"videoSignalMode",
                                         @"videoColorMode",
                                         @"joystickDevicePort1",
                                         @"joystickDevicePort2",
                                         @"audioEnablePsg",
                                         @"audioVolumePsg",
                                         @"audioBalancePsg",
                                         @"audioEnableScc",
                                         @"audioVolumeScc",
                                         @"audioBalanceScc",
                                         @"audioEnableMsxMusic",
                                         @"audioVolumeMsxMusic",
                                         @"audioBalanceMsxMusic",
                                         @"audioEnableMsxAudio",
                                         @"audioVolumeMsxAudio",
                                         @"audioBalanceMsxAudio",
                                         @"audioEnableKeyboard",
                                         @"audioVolumeKeyboard",
                                         @"audioBalanceKeyboard",
                                         @"audioEnableMoonSound",
                                         @"audioVolumeMoonSound",
                                         @"audioBalanceMoonSound",
                                         @"joystickRenshaTurbo",
                                         nil];
        
        openRomFileTypes = [[NSArray alloc] initWithObjects:@"rom", @"ri", @"mx1", @"mx2", @"zip", nil];
        openDiskFileTypes = [[NSArray alloc] initWithObjects:@"dsk", @"di1", @"di2", @"360", @"720", @"sf7", @"zip", nil];
        openCassetteFileTypes = [[NSArray alloc] initWithObjects:@"cas", @"zip", nil];
        stateFileTypes = [[NSArray alloc] initWithObjects:@"sta", nil];
        captureAudioTypes = [[NSArray alloc] initWithObjects:@"wav", nil];
        captureGameplayTypes = [[NSArray alloc] initWithObjects:@"cap", nil];
        
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"RomTypes"
                                                                 ofType:@"plist"
                                                            inDirectory:@"Data"];
        
        NSDictionary *romTypeMap = [NSDictionary dictionaryWithContentsOfFile:resourcePath];
        
        // Sort ROM type ID's by name
        NSArray *sortedRomTypeIds = [[romTypeMap allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                     {
                                         if ([a isEqualTo:@"0"])
                                             return -1;
                                         else if ([b isEqualTo:@"0"])
                                             return 1;
                                         
                                         NSString *titleA = [romTypeMap objectForKey:a];
                                         NSString *titleB = [romTypeMap objectForKey:b];
                                         
                                         return [titleA caseInsensitiveCompare:titleB];
                                     }];
        
        romTypes = [[NSMutableDictionary alloc] init];
        romTypeIndices = [[NSMutableDictionary alloc] init];
        romTypeNames = [[NSMutableArray alloc] init];
        
        [sortedRomTypeIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             NSNumber *index = @(idx);
             NSNumber *type = [NSNumber numberWithInt:[obj intValue]];
             
             [romTypes setObject:type forKey:index];
             [romTypeIndices setObject:index forKey:type];
             [romTypeNames addObject:[romTypeMap valueForKey:obj]];
         }];
    }
    
    return self;
}

- (void)dealloc
{
    // Stop monitoring for preference key changes
    
    [listOfPreferenceKeysToObserve enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [[NSUserDefaults standardUserDefaults] removeObserver:self
                                                   forKeyPath:obj];
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CMKeyPasteStarted
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CMKeyPasteEnded
                                                  object:nil];
    
    [self destroy];
    
    [self cleanupTemporaryCaptureFile];
    
    [listOfPreferenceKeysToObserve release];
    
    [romTypes release];
    [romTypeIndices release];
    [romTypeNames release];
    
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
    
    [self setLastLoadedState:nil];
    [self setLastSavedState:nil];
    [self setFileToLoadAtStartup:nil];
    [self setCurrentlyLoadedCaptureFilePath:nil];
    
    [input release];
    [mouse release];
    [sound release];
    
    [inputDeviceLayouts release];
    
    theEmulator = nil;
    
    [super dealloc];
}

- (void)awakeFromNib
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
    {
        NSWindowCollectionBehavior beh = [[self window] collectionBehavior];
        [[self window] setCollectionBehavior:beh | NSWindowCollectionBehaviorFullScreenPrimary];
    }
    
    [romTypeDropdown addItemsWithTitles:romTypeNames];
    
    [inputDeviceLayouts addObject:[[CMPreferences preferences] keyboardLayout]];
    [inputDeviceLayouts addObject:[[CMPreferences preferences] joystickOneLayout]];
    [inputDeviceLayouts addObject:[[CMPreferences preferences] joystickTwoLayout]];
    
    input = [[CMCocoaInput alloc] init];
    mouse = [[CMCocoaMouse alloc] init];
    sound = [[CMCocoaSound alloc] init];
    
    theEmulator = self; // FIXME
    
    [self setIsInitialized:NO];
    
    pausedDueToLostFocus = NO;
    
    properties = NULL;
    video = NULL;
    
    [self setScreenSize:NSMakeSize(CMGetIntPref(@"screenWidth"), CMGetIntPref(@"screenHeight"))
                animate:NO];
    
    [self setIsStatusBarVisible:CMGetBoolPref(@"isStatusBarVisible")];
    
    // Start monitoring for preference changes
    
    [listOfPreferenceKeysToObserve enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:obj
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedPasteStartedNotification:)
                                                 name:CMKeyPasteStarted
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedPasteEndedNotification:)
                                                 name:CMKeyPasteEnded
                                               object:nil];
    
    [self rebuildRecentItemsMenus];
    
    [self create];
    [self start];
}

- (CMAppDelegate*)theApp
{
    return (CMAppDelegate*)[NSApp delegate];
}

- (void)create
{
    if ([self isInitialized])
        return;
    
    CMPreferences *prefs = [CMPreferences preferences];
    
    // Initialize paths
    
    propertiesSetDirectory([prefs.appSupportDirectory UTF8String], [prefs.appSupportDirectory UTF8String]);
    actionSetAudioCaptureSetDirectory((char*)[prefs.audioCaptureDirectory UTF8String], "");
    actionSetVideoCaptureSetDirectory((char*)[prefs.videoCaptureDirectory UTF8String], "");
    boardSetDirectory((char*)[prefs.sramDirectory UTF8String]);
    tapeSetDirectory((char*)[prefs.cassetteDataDirectory UTF8String], "");
    mediaDbLoad((char*)[prefs.databaseDirectory UTF8String]);
    machineSetDirectory([prefs.machineDirectory UTF8String]);
    
    properties = propCreate(0, 0, P_KBD_EUROPEAN, 0, "");
    
    strncpy(properties->emulation.machineName,
            [CMGetObjPref(@"machineConfiguration") cStringUsingEncoding:NSUTF8StringEncoding],
            PROP_MAXPATH - 1);
    
    // Initialize the emulator
    
    properties->emulation.speed = [self emulationFrequencyFromPercentage:CMGetIntPref(@"emulationSpeedPercentage")];
    properties->emulation.syncMethod = P_EMU_SYNCTOVBLANKASYNC;
    properties->emulation.enableFdcTiming = CMGetBoolPref(@"enableFloppyTiming");
    properties->emulation.vdpSyncMode = CMGetIntPref(@"vdpSyncMode");
    
    properties->video.brightness = CMGetIntPref(@"videoBrightness");
    properties->video.contrast = CMGetIntPref(@"videoContrast");
    properties->video.saturation = CMGetIntPref(@"videoSaturation");
    properties->video.gamma = CMGetIntPref(@"videoGamma");
    properties->video.colorSaturationWidth = CMGetIntPref(@"videoRfModulation");
    properties->video.colorSaturationEnable = (properties->video.colorSaturationWidth > 0);
    properties->video.deInterlace = CMGetBoolPref(@"videoEnableDeInterlacing");
    properties->video.monitorType = CMGetIntPref(@"videoSignalMode");
    properties->video.monitorColor = CMGetIntPref(@"videoColorMode");
    
    properties->sound.mixerChannel[MIXER_CHANNEL_PSG].volume = CMGetIntPref(@"audioVolumePsg");
    properties->sound.mixerChannel[MIXER_CHANNEL_PSG].pan = CMGetIntPref(@"audioBalancePsg");
    properties->sound.mixerChannel[MIXER_CHANNEL_PSG].enable = CMGetIntPref(@"audioEnablePsg");
    properties->sound.mixerChannel[MIXER_CHANNEL_SCC].volume = CMGetIntPref(@"audioVolumeScc");
    properties->sound.mixerChannel[MIXER_CHANNEL_SCC].pan = CMGetIntPref(@"audioBalanceScc");
    properties->sound.mixerChannel[MIXER_CHANNEL_SCC].enable = CMGetIntPref(@"audioEnableScc");
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].volume = CMGetIntPref(@"audioVolumeMsxMusic");
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].pan = CMGetIntPref(@"audioBalanceMsxMusic");
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].enable = CMGetIntPref(@"audioEnableMsxMusic");
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].volume = CMGetIntPref(@"audioVolumeMsxAudio");
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].pan = CMGetIntPref(@"audioBalanceMsxAudio");
    properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].enable = CMGetIntPref(@"audioEnableMsxAudio");
    properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].volume = CMGetIntPref(@"audioVolumeKeyboard");
    properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].pan = CMGetIntPref(@"audioBalanceKeyboard");
    properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].enable = CMGetIntPref(@"audioEnableKeyboard");
    properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].volume = CMGetIntPref(@"audioVolumeMoonSound");
    properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].pan = CMGetIntPref(@"audioBalanceMoonSound");
    properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].enable = CMGetIntPref(@"audioEnableMoonSound");
    
    properties->joy1.autofire = CMGetIntPref(@"joystickRenshaTurbo");
    switchSetRensha(properties->joy1.autofire);

    properties->joy1.typeId = CMGetIntPref(@"joystickDevicePort1");
    properties->joy2.typeId = CMGetIntPref(@"joystickDevicePort2");
    
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
    
    videoSetRgbMode(video, 1);
    
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
    
    [self setIsInitialized:YES];
    
    NSString *name = [NSString stringWithCString:properties->emulation.machineName
                                        encoding:NSASCIIStringEncoding];
    [[self window] setTitle:name];
    
#ifdef DEBUG
    NSLog(@"EmulatorController: initialized");
#endif
}

- (void)destroy
{
    if (![self isInitialized])
        return;
    
    if ([self isStarted])
        [self stop];
    
    videoDestroy(video);
    propDestroy(properties);
    archSoundDestroy(); // TODO: this doesn't belong here
    mixerDestroy(mixer);
    
    [self setIsInitialized:NO];
    
#ifdef DEBUG
    NSLog(@"EmulatorController: destroyed");
#endif
}

- (void)start
{
    if ([self isInitialized])
    {
        if ([self isStarted])
            [self stop];
        
        if ([self fileToLoadAtStartup])
        {
            tryLaunchUnknownFile([self properties], [[self fileToLoadAtStartup] UTF8String], YES);
            
            [self setFileToLoadAtStartup:nil];
            return;
        }
        
        emulatorStart(NULL);
        
        // Pause if not focused
        [self windowKeyDidChange:[[self activeWindow] isKeyWindow]];
    }
}

- (void)stop
{
    if ([self isInitialized] && [self isStarted])
    {
        emulatorSuspend();
        emulatorStop();
    }
    
    [self setCurrentlyLoadedCaptureFilePath:nil];
    [self cleanupTemporaryCaptureFile];
    
    [self updateFps:0];
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

- (NSString *)runningMachineConfiguration
{
    if (![self isInitialized])
        return nil;
    
    return [NSString stringWithUTF8String:properties->emulation.machineName];
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

- (int)ledState
{
    int state = 0;
    if (ledGetCapslock())
        state |= LED_CAPS_LOCK;
    if (ledGetKana())
        state |= LED_CODE;
    if (ledGetTurboR())
        state |= LED_TURBO_R;
    if ([self isPaused])
        state |= LED_PAUSE;
    if (ledGetRensha())
        state |= LED_RENSHA;
    if (ledGetHd())
        state |= LED_HD;
    if (ledGetFdd1())
        state |= LED_FDD0;
    if (ledGetFdd2())
        state |= LED_FDD1;
    if (ledGetCas())
        state |= LED_CASSETTE;
    if ([self isStarted])
        state |= LED_POWER;
    
    return state;
}

- (void)toggleIfLedState:(int)state
              ledBitMask:(int)bitMask
               imageView:(NSImageView *)imageView
           offStateImage:(NSString *)offImage
            onStateImage:(NSString *)onImage
{
    if ((state & bitMask) != (lastLedState & bitMask))
    {
        if (state & bitMask)
            [imageView setImage:[NSImage imageNamed:onImage]];
        else
            [imageView setImage:[NSImage imageNamed:offImage]];
    }
}

- (void)updateFps:(CGFloat)fps
{
    int state = [self ledState];
    
    [self toggleIfLedState:state
                ledBitMask:LED_FDD0
                 imageView:fdd0Led
             offStateImage:@"fdd0_led_off"
              onStateImage:@"fdd0_led_on"];
    [self toggleIfLedState:state
                ledBitMask:LED_FDD1
                 imageView:fdd1Led
             offStateImage:@"fdd1_led_off"
              onStateImage:@"fdd1_led_on"];
    [self toggleIfLedState:state
                ledBitMask:LED_CODE
                 imageView:codeLed
             offStateImage:@"code_led_off"
              onStateImage:@"code_led_on"];
    [self toggleIfLedState:state
                ledBitMask:LED_CAPS_LOCK
                 imageView:capsLed
             offStateImage:@"caps_led_off"
              onStateImage:@"caps_led_on"];
    [self toggleIfLedState:state
                ledBitMask:LED_PAUSE
                 imageView:pauseLed
             offStateImage:@"pause_led_off"
              onStateImage:@"pause_led_on"];
    [self toggleIfLedState:state
                ledBitMask:LED_POWER
                 imageView:powerLed
             offStateImage:@"power_led_off"
              onStateImage:@"power_led_on"];
    [self toggleIfLedState:state
                ledBitMask:LED_RENSHA
                 imageView:renshaLed
             offStateImage:@"rensha_led_off"
              onStateImage:@"rensha_led_on"];
    [self toggleIfLedState:state
                ledBitMask:LED_CASSETTE
                 imageView:casLed
             offStateImage:@"cas_led_off"
              onStateImage:@"cas_led_on"];

    if (emulatorGetState() != EMU_RUNNING)
        [self setFpsDisplay:@""];
    else
        [self setFpsDisplay:[NSString stringWithFormat:CMLoc(@"%.02f", @""), fps]];
    
    self->lastLedState = state;
}

- (void)setScanlines:(NSInteger)value
{
    if ([self isStarted])
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

- (NSInteger)emulationSpeedPercentageFromFrequency:(NSInteger)frequency
{
    NSInteger logFrequency = 3579545 * pow(2.0, (properties->emulation.speed - 50) / 15.0515);
    
    return logFrequency * 100 / 3579545;
}

- (NSInteger)emulationFrequencyFromPercentage:(NSInteger)percentage
{
    percentage = MIN(MAX(percentage, 0), 1000);
    
    CGFloat frequency = percentage * 3579545.0 / 100.0;
    CGFloat logFrequency = log(frequency / 3579545.0) / log(2.0);
    
    return (NSInteger)(50.0 + 15.0515 * logFrequency);
}

- (void)setEmulationSpeedAsPercentage:(NSInteger)percentage
{
    properties->emulation.speed = [self emulationFrequencyFromPercentage:percentage];
    emulatorSetFrequency(properties->emulation.speed, NULL);
}

#pragma mark - Machine Configuration

+ (NSArray *)machineConfigurations
{
    NSMutableArray *machineConfigurations = [NSMutableArray array];
    
    ArrayList *list = arrayListCreate();
    machineFillAvailable(list, 1);
    
    ArrayListIterator *iterator = arrayListCreateIterator(list);
    while (arrayListCanIterate(iterator))
    {
        NSString *machineName = [NSString stringWithCString:arrayListIterate(iterator)
                                                   encoding:NSUTF8StringEncoding];
        
        if (machineName && [machineName length] > 0)
            [machineConfigurations addObject:machineName];
    }
    arrayListDestroyIterator(iterator);
    
    arrayListDestroy(list);
    
    return machineConfigurations;
}

- (NSString *)currentMachineConfiguration
{
    return [NSString stringWithCString:properties->emulation.machineName
                              encoding:NSUTF8StringEncoding];
}

+ (NSString *)pathForMachineConfigurationNamed:(NSString *)name
{
    NSString *machinesPath = [[CMPreferences preferences] machineDirectory];
    
    // First, check for a zip file
    NSString *zipFile = [machinesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", name]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:zipFile])
        return zipFile;
    
    // Next, check for a directory
    BOOL isDirectory = NO;
    NSString *directory = [machinesPath stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory] && isDirectory)
        return directory;
    
    return nil;
}

+ (BOOL)removeMachineConfiguration:(NSString *)configurationName
{
    NSError *error = nil;
    NSString *machinePath = [self pathForMachineConfigurationNamed:configurationName];
    
    if (!machinePath)
        return NO;
    
    [[NSFileManager defaultManager] removeItemAtPath:machinePath
                                               error:&error];
    
    return (error == nil);
}

- (void)addRecentMediaItemWithURL:(NSURL *)url
                           action:(SEL)action
                           parent:(NSMenuItem *)parent
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[url lastPathComponent]
                                                       action:action
                                                keyEquivalent:@""] autorelease];
    
    [menuItem setRepresentedObject:url];
    [[parent submenu] insertItem:menuItem
                         atIndex:[[parent submenu] numberOfItems] - 1];
}

- (void)clearRecentMediaItemsInMenu:(NSMenuItem *)menuItem
{
    NSMenu *subMenu = [menuItem submenu];
    [[subMenu itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj action] != @selector(clearRecentItems:))
             [subMenu removeItem:obj];
     }];
}

- (void)rebuildRecentItemsMenus
{
    // Clear existing menu items
    [self clearRecentMediaItemsInMenu:recentCartridgesA];
    [self clearRecentMediaItemsInMenu:recentCartridgesB];
    [self clearRecentMediaItemsInMenu:recentDisksA];
    [self clearRecentMediaItemsInMenu:recentDisksB];
    [self clearRecentMediaItemsInMenu:recentCassettes];
    
    // Add new items
    NSArray *recentURLs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    [recentURLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *extension = [[obj pathExtension] lowercaseString];
        if ([openRomFileTypes containsObject:extension])
        {
            [self addRecentMediaItemWithURL:obj
                                     action:@selector(insertRecentCartridgeA:)
                                     parent:recentCartridgesA];
            [self addRecentMediaItemWithURL:obj
                                     action:@selector(insertRecentCartridgeB:)
                                     parent:recentCartridgesB];
        }
        else if ([openDiskFileTypes containsObject:extension])
        {
            [self addRecentMediaItemWithURL:obj
                                     action:@selector(insertRecentDiskA:)
                                     parent:recentDisksA];
            [self addRecentMediaItemWithURL:obj
                                     action:@selector(insertRecentDiskB:)
                                     parent:recentDisksB];
        }
        else if ([openCassetteFileTypes containsObject:extension])
        {
            [self addRecentMediaItemWithURL:obj
                                     action:@selector(insertRecentCassette:)
                                     parent:recentCassettes];
        }
    }];
    
    // Add dividers, where appropriate
    int numberOfCartridgeItems = [[recentCartridgesA submenu] numberOfItems];
    if (numberOfCartridgeItems > 1)
    {
        [[recentCartridgesA submenu] insertItem:[NSMenuItem separatorItem]
                                             atIndex:numberOfCartridgeItems - 1];
        [[recentCartridgesB submenu] insertItem:[NSMenuItem separatorItem]
                                             atIndex:numberOfCartridgeItems - 1];
    }
    
    int numberOfDiskItems = [[recentDisksA submenu] numberOfItems];
    if (numberOfDiskItems > 1)
    {
        [[recentDisksA submenu] insertItem:[NSMenuItem separatorItem]
                                        atIndex:numberOfDiskItems - 1];
        [[recentDisksB submenu] insertItem:[NSMenuItem separatorItem]
                                        atIndex:numberOfDiskItems - 1];
    }
    
    int numberOfCassetteItems = [[recentCassettes submenu] numberOfItems];
    if (numberOfCassetteItems > 1)
    {
        [[recentCassettes submenu] insertItem:[NSMenuItem separatorItem]
                                           atIndex:numberOfCassetteItems - 1];
    }
}

#pragma mark - Properties

- (BOOL)isStarted
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

- (CMCocoaInput *)input
{
    return input;
}

- (CMCocoaMouse *)mouse
{
    return mouse;
}

- (CMCocoaSound *)sound
{
    return sound;
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
        [self toggleFullScreen];
    
    NSSize windowSize = [[self window] frame].size;
    NSSize screenSize = [screen frame].size;
    
    CGFloat newWidth = size.width + (windowSize.width - screenSize.width);
    CGFloat newHeight = size.height + (windowSize.height - screenSize.height);
    
    [self.window setFrame:NSMakeRect([[self window] frame].origin.x,
                                     [[self window] frame].origin.y,
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
                     useAccessoryView:nil
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
                     useAccessoryView:nil
                    completionHandler:handler];
}

- (void)showOpenFileDialogWithTitle:(NSString *)title
                   allowedFileTypes:(NSArray *)allowedFileTypes
                    openInDirectory:(NSString *)initialDirectory
               canChooseDirectories:(BOOL)canChooseDirectories
                   useAccessoryView:(NSView *)accessoryView
                  completionHandler:(void (^)(NSString *file, NSString *path))handler
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    [panel setTitle:title];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:canChooseDirectories];
    [panel setCanCreateDirectories:YES];
    
    BOOL canOpenAnyFile = CMGetBoolPref(@"openAnyFile");
    
    if (accessoryView)
    {
        [panel setAccessoryView:accessoryView];
        [openAnyFileCheckbox setState:canOpenAnyFile];
    }
    
    if (!accessoryView || !canOpenAnyFile)
        [panel setAllowedFileTypes:allowedFileTypes];
    
    currentlyActiveOpenPanel = panel;
    currentlySupportedFileTypes = allowedFileTypes;
    
    if (initialDirectory)
        [panel setDirectoryURL:[NSURL fileURLWithPath:initialDirectory]];
    
    [panel beginSheetModalForWindow:[self activeWindow]
                   completionHandler:^(NSInteger result)
     {
         NSString *file = nil;
         NSString *filePath = nil;
         
         if (result == NSFileHandlingPanelOKButton)
         {
             file = [panel URL].path;
             filePath = panel.directoryURL.path;
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
    
    [dialog beginSheetModalForWindow:[self activeWindow]
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

- (void)insertCartridgeIntoSlot:(NSInteger)slot
{
    if (![self isInitialized])
        return;
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    [panel setTitle:CMLoc(@"Insert Cartridge", @"")];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:YES];
    [panel setAccessoryView:romSelectionAccessoryView];
    [panel setDelegate:self];
    
    BOOL canOpenAnyFile = CMGetBoolPref(@"openAnyFile");
    
    [openAnyRomFileCheckbox setState:canOpenAnyFile];
    [romTypeDropdown selectItemAtIndex:0];
    
    if (!canOpenAnyFile)
        [panel setAllowedFileTypes:openRomFileTypes];
    
    currentlyActiveOpenPanel = panel;
    currentlySupportedFileTypes = openRomFileTypes;
    
    NSString *initialDir = [[CMPreferences preferences] cartridgeDirectory];
    if (initialDir)
        [panel setDirectoryURL:[NSURL fileURLWithPath:initialDir]];
    
    [panel beginSheetModalForWindow:[self activeWindow]
                  completionHandler:^(NSInteger result)
     {
         if (result == NSFileHandlingPanelOKButton)
         {
             [[CMPreferences preferences] setCartridgeDirectory:[[panel directoryURL] path]];
             
             RomType type = ROM_UNKNOWN;
             
             if ([romTypeDropdown isEnabled])
             {
                 int romTypeIndex = [romTypeDropdown indexOfItem:[romTypeDropdown selectedItem]];
                 type = [[romTypes objectForKey:@(romTypeIndex)] intValue];
             }
             
             [self insertCartridge:[[panel URL] path] slot:slot type:type];
         }
     }];
}

- (BOOL)insertCartridge:(NSString *)cartridge
                   slot:(NSInteger)slot
                   type:(RomType)type
{
    if (![self isInitialized] || ![[NSFileManager defaultManager] fileExistsAtPath:cartridge])
        return NO;
    
    emulatorSuspend();
    
    if (insertCartridge(properties, slot, [cartridge UTF8String], NULL, type, 0))
    {
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:cartridge]];
        [self rebuildRecentItemsMenus];
    }
    
    emulatorResume();
    
    // Reset last used state names
    [self setLastLoadedState:nil];
    [self setLastSavedState:nil];

    return YES;
}

- (BOOL)insertUnknownMedia:(NSString *)media
{
    if ([self isStarted])
        [self stop];
    
    
    // Reset last used state names
    [self setLastLoadedState:nil];
    [self setLastSavedState:nil];

    return tryLaunchUnknownFile(self.properties, [media UTF8String], YES) != 0;
}

- (void)insertSpecialCartridgeIntoSlot:(NSInteger)slot
{
    if (![self isInitialized])
        return;
    
    [cartChooser release];
    cartChooser = [[CMSpecialCartChooserController alloc] init];
    [cartChooser setDelegate:self];
    
    [cartChooser showSheetForWindow:self.window cartridgeSlot:slot];
}

- (void)ejectCartridgeFromSlot:(NSInteger)slot
{
    if (![self isStarted])
        return;
    
    actionCartRemove(slot);
    
    // Reset last used state names
    [self setLastLoadedState:nil];
    [self setLastSavedState:nil];
}

- (NSString *)fileNameFromCPath:(const char *)filePath
{
    if (!filePath || !*filePath)
        return nil;
    
    NSString *filePathAsString = [NSString stringWithUTF8String:filePath];
    
    return [filePathAsString lastPathComponent];
}

- (NSString *)fileNameNoExtensionFromCPath:(const char*)filePath
{
    return [[self fileNameFromCPath:filePath] stringByDeletingPathExtension];
}

- (BOOL)toggleEjectCartridgeMenuItemStatus:(NSMenuItem*)menuItem
                                      slot:(NSInteger)slot
{
    if ([self isInitialized])
    {
        NSString *displayName = [self fileNameFromCPath:properties->media.carts[slot].fileName];
        
        if (displayName)
        {
            [menuItem setTitle:[NSString stringWithFormat:CMLoc(@"Eject %@", @""), displayName]];
            return YES;
        }
    }
    
    [menuItem setTitle:CMLoc(@"Eject Cartridge", @"")];
    
    return NO;
}

- (void)insertDiskAtPath:(NSString *)path
                    slot:(NSInteger)slot
{
    emulatorSuspend();
    
    BOOL isDirectory;
    const char *fileCstr = [path UTF8String];
    
    [[NSFileManager defaultManager] fileExistsAtPath:path
                                         isDirectory:&isDirectory];
    
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
        [[CMPreferences preferences] setDiskDirectory:path];
        
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
        [self rebuildRecentItemsMenus];
    }
    
    emulatorResume();
    
    // If the user is inserting a disk into the first slot, reset last used
    // state names
    if (slot == 0)
    {
        [self setLastLoadedState:nil];
        [self setLastSavedState:nil];
    }
}

- (void)ejectDiskFromSlot:(NSInteger)slot
{
    actionDiskRemove(slot);
    
    // If the user is ejecting a disk from the first slot, reset last used
    // state names
    if (slot == 0)
    {
        [self setLastLoadedState:nil];
        [self setLastSavedState:nil];
    }
}

- (void)insertCassetteAtPath:(NSString *)path
{
    emulatorSuspend();
    
    if (properties->cassette.rewindAfterInsert)
        tapeRewindNextInsert();
    
    if (insertCassette(properties, 0, [path UTF8String], NULL, 0))
    {
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
        [self rebuildRecentItemsMenus];
        [[CMPreferences preferences] setCassetteDirectory:path];
    }
    
    emulatorResume();
}

- (BOOL)saveStateToFile:(NSString *)file
{
    if (![self isInitialized])
        return NO;
    
    emulatorSuspend();
    boardSaveState([file UTF8String], 1);
    emulatorResume();
    
    NSInteger iconStyle = CMGetIntPref(@"snapshotIconStyle");
    
    if (iconStyle != CMSnapshotIconStyleNone)
    {
        NSImage *screenshot = [screen captureScreen:YES];
        
        if (screenshot)
        {
            NSImage *icon = nil;
            
            if (iconStyle == CMSnapshotIconStyleFilmstrip)
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
            else if (iconStyle == CMSnapshotIconStyleScreen)
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
    
    return YES;
}

- (BOOL)toggleEjectDiskMenuItemStatus:(NSMenuItem*)menuItem
                                 slot:(NSInteger)slot
{
    if ([self isInitialized])
    {
        NSString *displayName = [self fileNameFromCPath:properties->media.disks[slot].fileName];
        
        if (displayName)
        {
            [menuItem setTitle:[NSString stringWithFormat:CMLoc(@"Eject %@", @""), displayName]];
            return YES;
        }
    }
    
    menuItem.title = CMLoc(@"Eject Disk", @"");
    return NO;
}

- (BOOL)toggleEjectCassetteMenuItemStatus:(NSMenuItem*)menuItem
{
    if ([self isInitialized])
    {
        NSString *displayName = [self fileNameFromCPath:properties->media.tapes[0].fileName];
        
        if (displayName)
        {
            [menuItem setTitle:[NSString stringWithFormat:CMLoc(@"Eject %@", @""), displayName]];
            return YES;
        }
    }
    
    menuItem.title = CMLoc(@"Eject Cassette", @"");
    return NO;
}

- (void)pasteText:(id)sender
{
    NSPasteboard *pasteBoard  = [NSPasteboard generalPasteboard];
    NSString *text = [pasteBoard stringForType:NSPasteboardTypeString];
    
    NSString *runningMachineId = [self runningMachineConfiguration];
    NSString *layoutName = [CMMSXKeyboard layoutNameOfMachineWithIdentifier:runningMachineId];
    
    [[self input] pasteText:text layoutName:layoutName];
}

- (void)windowKeyDidChange:(BOOL)isKey
{
    [mouse setEmulatorHasFocus:isKey];
    [input setEmulatorHasFocus:isKey];
    
    BOOL pauseWhenUnfocused = [[NSUserDefaults standardUserDefaults] boolForKey:@"pauseWhenUnfocused"];
    
    if ([self isStarted])
    {
        if (isKey)
        {
            if ([self isPaused] && pausedDueToLostFocus)
                [self resume];
            
            pausedDueToLostFocus = NO;
        }
        else
        {
            if (![self isPaused] && pauseWhenUnfocused)
            {
                [self pause];
                pausedDueToLostFocus = YES;
            }
        }
    }
}

- (BOOL)isLionFullscreenAvailable
{
    return [self.window respondsToSelector:@selector(toggleFullScreen:)];
}

- (NSWindow *)activeWindow
{
    return [[self screen] window];
}

- (BOOL)isInFullScreenMode
{
    if ([self isLionFullscreenAvailable])
        return (self.window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask;
    else
        return [self.window.contentView isInFullScreenMode];
}

- (void)enterLegacyFullscreen
{
    // Save screen size
    CMSetIntPref(@"screenWidth", [screen bounds].size.width);
    CMSetIntPref(@"screenHeight", [screen bounds].size.height);
    
    // Set options (hide dock, auto-hide menu bar)
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @(NSApplicationPresentationHideDock
                             | NSApplicationPresentationAutoHideMenuBar), NSFullScreenModeApplicationPresentationOptions,
                             nil];
    
    // Switch to full screen
    [[[self window] contentView] enterFullScreenMode:[NSScreen mainScreen]
                                         withOptions:options];
    
    // Hide the original window
    [[self window] orderOut:self];
    
    // Set a black background color to the full screen window
    [[self activeWindow] setBackgroundColor:[NSColor blackColor]];
    
    NSSize screenSize = [[NSScreen mainScreen] frame].size;
    CGFloat fullWidth = screenSize.width;
    CGFloat screenWidth = screenSize.height * WIDTH_TO_HEIGHT_RATIO;
    CGFloat x = (fullWidth - screenWidth) / 2.0;
    
    // Proportionally resize the screen and hide the status bar items
    [[self screen] setFrame:NSMakeRect(x, 0, screenWidth, screenSize.height)];
    [statusBar setHidden:YES];
    
    // Set EmulatorController as the full screen window's delegate
    [[self activeWindow] setDelegate:self];
    
    // Toggle auto-pause/auto-resume
    [self windowKeyDidChange:[[self activeWindow] isKeyWindow]];
    
    // Make the screen the first responder
    [[self activeWindow] makeFirstResponder:self.screen];
}

- (void)exitLegacyFullscreen
{
    // Un-hide the original window
    [[self window] orderBack:self];
    
    // Exit full screen mode
    [[[self window] contentView] exitFullScreenModeWithOptions:nil];
    
    // Resize the screen and show the status section
    NSSize contentSize = [[[self window] contentView] bounds].size;
    
    CGFloat yOffset = 0;
    if (CMGetBoolPref(@"isStatusBarVisible"))
        yOffset += CMMinYEdgeHeight;
    
    [[self screen] setFrame:NSMakeRect(0, yOffset,
                                       contentSize.width,
                                       contentSize.height - yOffset)];
    
    [statusBar setHidden:NO];
    
    // Make the screen the first responder
    [[self window] makeFirstResponder:self.screen];
}

- (void)toggleFullScreen
{
    if ([self isLionFullscreenAvailable])
    {
        [self.window toggleFullScreen:nil];
    }
    else
    {
        if (![self isInFullScreenMode])
            [self enterLegacyFullscreen];
        else
            [self exitLegacyFullscreen];
    }
}

- (BOOL)isStatusBarVisible
{
    return ![statusBar isHidden];
}

- (void)setIsStatusBarVisible:(BOOL)isVisible
{
    NSRect windowFrame = [[self window] frame];
    NSRect screenFrame = [[self screen] frame];
    
    CGFloat screenHeight = [[self screen] frame].size.height;
    CGFloat contentSizeDifference = [[self window] frame].size.height -
        [[[self window] contentView] frame].size.height;
    
    windowFrame.size.height = contentSizeDifference + screenHeight;
    screenFrame.origin.y = 0;
    screenFrame.size.height = screenHeight;
    
    if (isVisible)
    {
        // Show the status bar
        [[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
        [[self window] setContentBorderThickness:CMMinYEdgeHeight forEdge:NSMinYEdge];
        
        windowFrame.origin.y -= CMMinYEdgeHeight;
        windowFrame.size.height += CMMinYEdgeHeight;
        screenFrame.origin.y += CMMinYEdgeHeight;
    }
    else
    {
        // Hide the status bar
        [[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
        [[self window] setContentBorderThickness:0 forEdge:NSMinYEdge];
        
        windowFrame.origin.y += CMMinYEdgeHeight;
    }
    
    [statusBar setHidden:!isVisible];
    
    // Constrain the window frame within the available area
    NSRect constrainedRect = [[self window] constrainFrameRect:windowFrame
                                                      toScreen:[[self window] screen]];
    
    if (!NSEqualRects(constrainedRect, windowFrame))
    {
        // Looks like the window frame doesn't fit within the screen
        // Recompute the sizes in relation to the window height
        
        screenFrame.size.height = constrainedRect.size.height - contentSizeDifference - screenFrame.origin.y;
        screenFrame.size.width = screenFrame.size.height * WIDTH_TO_HEIGHT_RATIO;
        constrainedRect.size.width = screenFrame.size.width;
        
        windowFrame = constrainedRect;
    }
    
    NSDisableScreenUpdates();
    [[self screen] setHidden:YES];
    [[self window] setFrame:windowFrame display:YES];
    [[self screen] setFrame:screenFrame];
    [[self screen] setHidden:NO];
    NSEnableScreenUpdates();
}

- (void)cleanupTemporaryCaptureFile
{
    if (!gameplayCaptureTempFilename)
        return;
    
    // Remove the temp file, if any
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:gameplayCaptureTempFilename])
        [[NSFileManager defaultManager] removeItemAtPath:gameplayCaptureTempFilename
                                                   error:&error];
    
    [gameplayCaptureTempFilename release];
    gameplayCaptureTempFilename = nil;
}

#pragma mark - IBActions

- (void)clearRecentItems:(id)sender
{
    [[NSDocumentController sharedDocumentController] clearRecentDocuments:sender];
    [self rebuildRecentItemsMenus];
}

- (void)insertRecentCartridgeA:(id)sender
{
    [self insertCartridge:[[sender representedObject] path]
                     slot:0
                     type:ROM_UNKNOWN];
}

- (void)insertRecentCartridgeB:(id)sender
{
    [self insertCartridge:[[sender representedObject] path]
                     slot:1
                     type:ROM_UNKNOWN];
}

- (void)insertRecentDiskA:(id)sender
{
    [self insertDiskAtPath:[[sender representedObject] path]
                      slot:0];
}

- (void)insertRecentDiskB:(id)sender
{
    [self insertDiskAtPath:[[sender representedObject] path]
                      slot:1];
}

- (void)insertRecentCassette:(id)sender
{
    [self insertCassetteAtPath:[[sender representedObject] path]];
}

- (void)openAnyFile:(id)sender
{
    BOOL canOpenAnyFile = [sender state];
    CMSetBoolPref(@"openAnyFile", canOpenAnyFile);
    
    if (canOpenAnyFile)
        [currentlyActiveOpenPanel setAllowedFileTypes:nil];
    else
        [currentlyActiveOpenPanel setAllowedFileTypes:currentlySupportedFileTypes];
    
}

- (void)openAbout:(id)sender
{
    if (!aboutController)
        aboutController = [[CMAboutController alloc] init];
    
    [aboutController showWindow:self];
}

- (void)openPreferences:(id)sender
{
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
    if ([self isInitialized])
        properties->cartridge.autoReset = !properties->cartridge.autoReset;
}

- (void)insertDiskSlot1:(id)sender
{
    if (![self isInitialized])
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"Insert Disk", @"Dialog title")
                     allowedFileTypes:openDiskFileTypes
                      openInDirectory:[[CMPreferences preferences] diskDirectory]
                 canChooseDirectories:YES
                     useAccessoryView:unrecognizedFileAccessoryView
                    completionHandler:^(NSString *file, NSString *path)
     
     {
         if (file)
             [self insertDiskAtPath:file
                               slot:0];
     }];
}

- (void)insertDiskSlot2:(id)sender
{
    if (![self isInitialized])
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"Insert Disk", @"Dialog title")
                     allowedFileTypes:openDiskFileTypes
                      openInDirectory:[[CMPreferences preferences] diskDirectory]
                 canChooseDirectories:YES
                     useAccessoryView:unrecognizedFileAccessoryView
                    completionHandler:^(NSString *file, NSString *path)
     
     {
         if (file)
             [self insertDiskAtPath:file
                               slot:1];
     }];
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
    if (![self isInitialized])
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"Insert Cassette", @"Dialog title")
                     allowedFileTypes:openCassetteFileTypes
                      openInDirectory:[[CMPreferences preferences] cassetteDirectory]
                 canChooseDirectories:NO
                     useAccessoryView:unrecognizedFileAccessoryView
                    completionHandler:^(NSString *file, NSString *path)
    {
        if (file)
            [self insertCassetteAtPath:file];
    }];
}

- (void)ejectCassette:(id)sender
{
    actionCasRemove();
}

- (void)toggleCassetteAutoRewind:(id)sender
{
    if ([self isInitialized])
        properties->cassette.rewindAfterInsert = !properties->cassette.rewindAfterInsert;
}

- (void)toggleCassetteWriteProtect:(id)sender
{
    if ([self isInitialized])
        properties->cassette.readOnly ^= 1;
}

- (void)rewindCassette:(id)sender
{
    if ([self isInitialized])
        actionCasRewind();
}

- (void)repositionCassette:(id)sender
{
    if (![self isInitialized] || !(*properties->media.tapes[0].fileName))
        return;
    
    [cassetteRepositioner release];
    cassetteRepositioner = [[CMRepositionCassetteController alloc] init];
    cassetteRepositioner.delegate = self;
    
    [cassetteRepositioner showSheetForWindow:self.window];
}

- (BOOL)canInsertDiskettes
{
    NSString *runningMachine = [self runningMachineConfiguration];
    return runningMachine && ![runningMachine containsString:@"C-BIOS"];
}

- (BOOL)canInsertCassettes
{
    NSString *runningMachine = [self runningMachineConfiguration];
    return runningMachine && ![runningMachine containsString:@"C-BIOS"];
}

// MSX menu

- (void)statusMsx:(id)sender
{
}

- (void)hardResetMsx:(id)sender
{
    if ([self isStarted])
    {
        [[self input] resetState];
        actionEmuResetHard();
    }
}

- (void)resetMsx:(id)sender
{
    if ([self isStarted])
    {
        [[self input] resetState];
        actionEmuResetSoft();
    }
}

- (void)shutDownMsx:(id)sender
{
    if ([self isStarted])
    {
        [[self input] resetState];
        
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
    if (![self isInitialized])
        return;
    
    NSInteger emulatorState = emulatorGetState();
    if (emulatorState != EMU_RUNNING && emulatorState != EMU_PAUSED)
        return;
    
    [self showOpenFileDialogWithTitle:CMLoc(@"Load Snapshot", @"Dialog title")
                     allowedFileTypes:stateFileTypes
                      openInDirectory:[[CMPreferences preferences] snapshotDirectory]
                    completionHandler:^(NSString *file, NSString *path)
    {
        if (file)
        {
            emulatorSuspend();
            emulatorStop();
            emulatorStart([file UTF8String]);
            
            [[CMPreferences preferences] setSnapshotDirectory:path];
            [self setLastLoadedState:file];
        }
    }];
}

- (void)reloadState:(id)sender
{
    if (![self isInitialized])
        return;

    NSString *statePath = [self lastLoadedState];
    if (statePath == nil)
    {
        [self loadState:sender];
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:statePath])
    {
        emulatorSuspend();
        emulatorStop();
        emulatorStart([statePath UTF8String]);
    }
}

- (void)saveState:(id)sender
{
    if (![self isInitialized] || ![self isStarted])
        return;
    
    emulatorSuspend();
    
    [self showSaveFileDialogWithTitle:CMLoc(@"Save Snapshot", @"Dialog title")
                     allowedFileTypes:stateFileTypes
                      openInDirectory:[[CMPreferences preferences] snapshotDirectory]
                    completionHandler:^(NSString *file, NSString *path)
     {
         if (file)
         {
             [[CMPreferences preferences] setSnapshotDirectory:path];
             
             [self saveStateToFile:file];
             [self setLastLoadedState:file];
             [self setLastSavedState:file];
         }
         
         emulatorResume();
     }];
}

- (void)overwriteState:(id)sender
{
    if (![self isInitialized] || ![self isStarted])
        return;

    NSString *statePath = [self lastSavedState];
    if (statePath == nil)
    {
        [self saveState:sender];
        return;
    }
    
    emulatorSuspend();

    if ([[NSFileManager defaultManager] fileExistsAtPath:statePath])
    {
        [self saveStateToFile:statePath];
    }

    emulatorResume();
}

- (void)saveScreenshot:(id)sender
{
    if (![self isInitialized] || ![self isStarted])
        return;
    
    emulatorSuspend();
    
    [self showSaveFileDialogWithTitle:CMLoc(@"Save Screenshot", @"Dialog title")
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
    if (![self isInitialized] || ![self isStarted])
        return;
    
    if (mixerIsLogging(mixer))
        mixerStopLog(mixer);
    else
    {
        emulatorSuspend();
        
        [self showSaveFileDialogWithTitle:CMLoc(@"Record Audio", @"Dialog title")
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
    if (!self.isInitialized || ![self isStarted])
        return;
    
    if (!boardCaptureIsRecording())
    {
        emulatorSuspend();
        
        [self cleanupTemporaryCaptureFile];
        
        gameplayCaptureTempFilename = [NSString pathForTemporaryFileWithPrefix:@"cocoaMsxCapture"];
        if (gameplayCaptureTempFilename)
        {
#ifdef DEBUG
            NSLog(@"Capturing to %@", gameplayCaptureTempFilename);
#endif
            [self setCurrentlyLoadedCaptureFilePath:gameplayCaptureTempFilename];
            
            const char *destination = [gameplayCaptureTempFilename UTF8String];
            strncpy(properties->filehistory.videocap, destination, PROP_MAXPATH - 1);
            
            boardCaptureStart(properties->filehistory.videocap);
        }
        
        emulatorResume();
    }
}

- (void)openGameplayRecording:(id)sender
{
    if (![self isInitialized] || ![self isStarted])
        return;
    
    emulatorSuspend();
    
    [self showOpenFileDialogWithTitle:CMLoc(@"Load Gameplay Recording", @"Dialog title")
                     allowedFileTypes:captureGameplayTypes
                      openInDirectory:[CMPreferences preferences].videoCaptureDirectory
                    completionHandler:^(NSString *file, NSString *path)
     {
         if (file)
         {
             [[CMPreferences preferences] setVideoCaptureDirectory:path];
             
             [self setCurrentlyLoadedCaptureFilePath:file];
             
             const char *recording = [file UTF8String];
             
             strncpy(properties->filehistory.videocap, recording, PROP_MAXPATH - 1);
             
             emulatorStop();
             emulatorStart(recording);
         }
         else
         {
             emulatorResume();
         }
     }];
}

- (void)saveGameplayRecording:(id)sender
{
    if (!self.isInitialized || ![self isStarted])
        return;
    
    if ([self currentlyLoadedCaptureFilePath] && !boardCaptureIsRecording())
    {
        emulatorSuspend();
        
        [self showSaveFileDialogWithTitle:CMLoc(@"Save Gameplay Recording", @"Dialog title")
                         allowedFileTypes:captureGameplayTypes
                          openInDirectory:[CMPreferences preferences].videoCaptureDirectory
                        completionHandler:^(NSString *file, NSString *path)
         {
             if (file)
             {
                 [[CMPreferences preferences] setVideoCaptureDirectory:path];
                 
                 NSError *error = NULL;
                 [[NSFileManager defaultManager] copyItemAtPath:[self currentlyLoadedCaptureFilePath]
                                                         toPath:file
                                                          error:&error];
                 
                 if (error)
                 {
                     NSString *message = [NSString stringWithFormat:CMLoc(@"An error occurred while attempting to save to \"%@\".", @""),
                                          file];
                     
                     NSAlert *alert = [NSAlert alertWithMessageText:message
                                                      defaultButton:CMLoc(@"OK", @"")
                                                    alternateButton:nil
                                                        otherButton:nil
                                          informativeTextWithFormat:@""];
                     
                     [alert beginSheetModalForWindow:[self window]
                                       modalDelegate:self
                                      didEndSelector:nil
                                         contextInfo:nil];
                 }
             }
             
             emulatorResume();
         }];
    }
}

- (void)stopGameplayRecording:(id)sender
{
    if (!self.isInitialized || ![self isStarted])
        return;
    
    if (boardCaptureIsRecording() || boardCaptureIsPlaying())
    {
        emulatorSuspend();
        boardCaptureStop();
        emulatorResume();
    }
}

- (void)playBackGameplay:(id)sender
{
    if ([self currentlyLoadedCaptureFilePath] != nil &&
        [[NSFileManager defaultManager] fileExistsAtPath:[self currentlyLoadedCaptureFilePath]])
    {
        if ([self machineState] != EMU_STOPPED)
        {
            emulatorSuspend();
            emulatorStop();
        }
        
        const char *recording = [[self currentlyLoadedCaptureFilePath] UTF8String];
        strncpy(properties->filehistory.videocap, recording, PROP_MAXPATH - 1);
        
        emulatorStart(recording);
    }
}

// View menu

- (void)normalSize:(id)sender
{
    [self zoomWindowBy:1.0];
}

- (void)toggleFullScreen:(id)sender
{
    [self toggleFullScreen];
}

- (void)toggleStatusBar:(id)sender
{
    if (![self isInFullScreenMode])
    {
        // Toggle status
        BOOL isVisible = !CMGetBoolPref(@"isStatusBarVisible");
        CMSetBoolPref(@"isStatusBarVisible", isVisible);
        
        // Update UI
        [self setIsStatusBarVisible:isVisible];
    }
}

#pragma mark - Key events

- (void)keyDown:(NSEvent *)theEvent
{
    // Intercept default behavior - which is beeps
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

- (void)receivedPasteStartedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"receivedPasteStartedNotification");
#endif
    
    // Set speed to normal
    [self setEmulationSpeedAsPercentage:100];
}

- (void)receivedPasteEndedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"receivedPasteEndedNotification");
#endif
    
    // Resume at selected speed
    [self setEmulationSpeedAsPercentage:CMGetIntPref(@"emulationSpeedPercentage")];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"pauseWhenUnfocused"])
    {
        [self windowKeyDidChange:[[self activeWindow] isKeyWindow]];
    }
    
    if ([self isInitialized])
    {
        if ([keyPath isEqualToString:@"emulationSpeedPercentage"])
        {
            [self setEmulationSpeedAsPercentage:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
        }
        else if ([keyPath isEqualToString:@"videoBrightness"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->video.brightness = newValue;
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"videoContrast"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->video.contrast = newValue;
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"videoSaturation"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->video.saturation = newValue;
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"videoGamma"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->video.gamma = newValue;
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"videoRfModulation"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->video.colorSaturationWidth = newValue;
            properties->video.colorSaturationEnable = (newValue > 0);
            
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"videoEnableDeInterlacing"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->video.deInterlace = newValue;
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"videoSignalMode"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->video.monitorType = newValue;
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"videoColorMode"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->video.monitorColor = newValue;
            videoUpdateAll(video, properties);
        }
        else if ([keyPath isEqualToString:@"enableFloppyTiming"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->emulation.enableFdcTiming = newValue;
            boardSetFdcTimingEnable(newValue);
        }
        else if ([keyPath isEqualToString:@"audioVolumePsg"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_PSG].volume = newValue;
            mixerSetChannelTypeVolume(mixer, MIXER_CHANNEL_PSG, newValue);
        }
        else if ([keyPath isEqualToString:@"audioBalancePsg"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_PSG].pan = newValue;
            mixerSetChannelTypePan(mixer, MIXER_CHANNEL_PSG, newValue);
        }
        else if ([keyPath isEqualToString:@"audioEnablePsg"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_PSG].enable = newValue;
            mixerEnableChannelType(mixer, MIXER_CHANNEL_PSG, newValue);
        }
        else if ([keyPath isEqualToString:@"audioVolumeScc"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_SCC].volume = newValue;
            mixerSetChannelTypeVolume(mixer, MIXER_CHANNEL_SCC, newValue);
        }
        else if ([keyPath isEqualToString:@"audioBalanceScc"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_SCC].pan = newValue;
            mixerSetChannelTypePan(mixer, MIXER_CHANNEL_SCC, newValue);
        }
        else if ([keyPath isEqualToString:@"audioEnableScc"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_SCC].enable = newValue;
            mixerEnableChannelType(mixer, MIXER_CHANNEL_SCC, newValue);
        }
        else if ([keyPath isEqualToString:@"audioVolumeMsxMusic"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].volume = newValue;
            mixerSetChannelTypeVolume(mixer, MIXER_CHANNEL_MSXMUSIC, newValue);
        }
        else if ([keyPath isEqualToString:@"audioBalanceMsxMusic"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].pan = newValue;
            mixerSetChannelTypePan(mixer, MIXER_CHANNEL_MSXMUSIC, newValue);
        }
        else if ([keyPath isEqualToString:@"audioEnableMsxMusic"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MSXMUSIC].enable = newValue;
            mixerEnableChannelType(mixer, MIXER_CHANNEL_MSXMUSIC, newValue);
        }
        else if ([keyPath isEqualToString:@"audioVolumeMsxAudio"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].volume = newValue;
            mixerSetChannelTypeVolume(mixer, MIXER_CHANNEL_MSXAUDIO, newValue);
        }
        else if ([keyPath isEqualToString:@"audioBalanceMsxAudio"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].pan = newValue;
            mixerSetChannelTypePan(mixer, MIXER_CHANNEL_MSXAUDIO, newValue);
        }
        else if ([keyPath isEqualToString:@"audioEnableMsxAudio"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MSXAUDIO].enable = newValue;
            mixerEnableChannelType(mixer, MIXER_CHANNEL_MSXAUDIO, newValue);
        }
        else if ([keyPath isEqualToString:@"audioVolumeKeyboard"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].volume = newValue;
            mixerSetChannelTypeVolume(mixer, MIXER_CHANNEL_KEYBOARD, newValue);
        }
        else if ([keyPath isEqualToString:@"audioBalanceKeyboard"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].pan = newValue;
            mixerSetChannelTypePan(mixer, MIXER_CHANNEL_KEYBOARD, newValue);
        }
        else if ([keyPath isEqualToString:@"audioEnableKeyboard"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_KEYBOARD].enable = newValue;
            mixerEnableChannelType(mixer, MIXER_CHANNEL_KEYBOARD, newValue);
        }
        else if ([keyPath isEqualToString:@"audioVolumeMoonSound"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].volume = newValue;
            mixerSetChannelTypeVolume(mixer, MIXER_CHANNEL_MOONSOUND, newValue);
        }
        else if ([keyPath isEqualToString:@"audioBalanceMoonSound"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].pan = newValue;
            mixerSetChannelTypePan(mixer, MIXER_CHANNEL_MOONSOUND, newValue);
        }
        else if ([keyPath isEqualToString:@"audioEnableMoonSound"])
        {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            properties->sound.mixerChannel[MIXER_CHANNEL_MOONSOUND].enable = newValue;
            mixerEnableChannelType(mixer, MIXER_CHANNEL_MOONSOUND, newValue);
        }
        else if ([keyPath isEqualToString:@"joystickDevicePort1"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->joy1.typeId = newValue;
            joystickPortSetType(0, newValue);
        }
        else if ([keyPath isEqualToString:@"joystickDevicePort2"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            properties->joy2.typeId = newValue;
            joystickPortSetType(1, newValue);
        }
        else if ([keyPath isEqualToString:@"joystickRenshaTurbo"])
        {
            NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];

            properties->joy1.autofire = newValue; //(int)ceil((11 - 1) * value / 100.0);
            switchSetRensha(properties->joy1.autofire);
        }
    }
}

#pragma mark - NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - NSOpenSavePanelDelegate

- (void)panelSelectionDidChange:(id)sender
{
    NSString *path = [[sender URL] path];
    if (!path)
    {
        [romTypeDropdown selectItemAtIndex:0];
        [romTypeDropdown setEnabled:NO];
    }
    else
    {
        const char *cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
        MediaType *mediaType = mediaDbLookupRomByPath(cpath);
        if (!mediaType)
            mediaType = mediaDbGuessRomByPath(cpath);
        
        if (!mediaType)
        {
            [romTypeDropdown setEnabled:NO];
            [romTypeDropdown selectItemAtIndex:0];
        }
        else
        {
            RomType romType = mediaDbGetRomType(mediaType);
            NSNumber *index = [romTypeIndices objectForKey:@(romType)];
            
            [romTypeDropdown setEnabled:YES];
            [romTypeDropdown selectItemAtIndex:[index intValue]];
        }
    }
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
    frameSize.width = (frameSize.height - marginY) / (1 / WIDTH_TO_HEIGHT_RATIO) + marginX;
    
    return frameSize;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self stop];
    [self destroy];
    
    if (![self isInFullScreenMode])
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

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"EmulatorController: willEnterFullScreen");
#endif
    
    // Save the screen size first
    CMSetIntPref(@"screenWidth", [screen bounds].size.width);
    CMSetIntPref(@"screenHeight", [screen bounds].size.height);
    
    if ([self isStatusBarVisible])
    {
        [self setIsStatusBarVisible:NO];
    }
}

- (void)windowWillExitFullScreen:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"EmulatorController: willExitFullScreen");
#endif
    
    if (CMGetBoolPref(@"isStatusBarVisible"))
    {
        [self setIsStatusBarVisible:YES];
    }
}

#pragma mark - SpecialCartSelectedDelegate

- (void)cartSelectedOfType:(NSInteger)romType romName:(const char*)romName slot:(NSInteger)slot;
{
#ifdef DEBUG
    NSLog(@"EmulatorController:cartSelectedOfType %d '%s'",
          (int)romType, romName);
#endif
    
    emulatorSuspend();
    insertCartridge([self properties], slot, romName, NULL, romType, 0);
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
    BOOL isRunning = [self isStarted];
    
    if ([item action] == @selector(toggleCartAutoReset:))
    {
        menuItem.state = (properties->cartridge.autoReset) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if ([item action] == @selector(insertCartridgeSlot1:) ||
             [item action] == @selector(insertCartridgeSlot2:))
    {
        return isRunning;
    }
    else if ([item action] == @selector(insertDiskSlot1:) ||
             [item action] == @selector(insertDiskSlot2:) ||
             [item action] == @selector(insertRecentDiskA:) ||
             [item action] == @selector(insertRecentDiskB:))
    {
        return isRunning && [self canInsertDiskettes];
    }
    else if ([item action] == @selector(insertCassette:) ||
             [item action] == @selector(insertRecentCassette:))
    {
        return isRunning && [self canInsertCassettes];
    }
    else if ([item action] == @selector(ejectCartridgeSlot1:))
        return [self toggleEjectCartridgeMenuItemStatus:menuItem slot:0];
    else if ([item action] == @selector(ejectCartridgeSlot2:))
        return [self toggleEjectCartridgeMenuItemStatus:menuItem slot:1];
    else if ([item action] == @selector(toggleDiskAutoReset:))
    {
        menuItem.state = (properties->diskdrive.autostartA) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if ([item action] == @selector(ejectDiskSlot1:))
        return [self toggleEjectDiskMenuItemStatus:menuItem slot:0];
    else if ([item action] == @selector(ejectDiskSlot2:))
        return [self toggleEjectDiskMenuItemStatus:menuItem slot:1];
    else if ([item action] == @selector(ejectCassette:))
        return [self toggleEjectCassetteMenuItemStatus:menuItem];
    else if ([item action] == @selector(toggleCassetteAutoRewind:))
    {
        menuItem.state = (properties->cassette.rewindAfterInsert) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if ([item action] == @selector(toggleCassetteWriteProtect:))
    {
        menuItem.state = (properties->cassette.readOnly) ? NSOnState : NSOffState;
        return isRunning;
    }
    else if ([item action] == @selector(rewindCassette:))
        return (*properties->media.tapes[0].fileName) ? NSOnState : NSOffState;
    else if ([item action] == @selector(repositionCassette:))
        return (*properties->media.tapes[0].fileName) ? NSOnState : NSOffState;
    else if ([item action] == @selector(normalSize:))
    {
        return ![self isInFullScreenMode];
    }
    else if ([item action] == @selector(toggleStatusBar:))
    {
        menuItem.state = CMGetBoolPref(@"isStatusBarVisible") ? NSOnState : NSOffState;
        return ![self isInFullScreenMode]; // Can't toggle in fullscreen mode
    }
    else if ([item action] == @selector(toggleFullScreen:))
    {
        if ([self isInFullScreenMode])
            [menuItem setTitle:CMLoc(@"Exit Full Screen", @"")];
        else
            [menuItem setTitle:CMLoc(@"Enter Full Screen", @"")];
    }
    else if ([item action] == @selector(loadState:))
    {
        return isRunning;
    }
    else if ([item action] == @selector(saveState:))
    {
        return isRunning;
    }
    else if ([item action] == @selector(statusMsx:))
    {
        if (machineState == EMU_RUNNING)
            [menuItem setTitle:CMLoc(@"MSX Running", @"Menu item title")];
        else if (machineState == EMU_PAUSED)
            [menuItem setTitle:CMLoc(@"MSX Paused", @"Menu item title")];
        else if (machineState == EMU_SUSPENDED)
            [menuItem setTitle:CMLoc(@"MSX Suspended", @"Menu item title")];
        else if (machineState == EMU_STOPPED)
            [menuItem setTitle:CMLoc(@"MSX Powered Off", @"Menu item title")];
        else
            [menuItem setTitle:CMLoc(@"MSX State Unknown", @"Menu item title")];
        
        return NO; // always disabled
    }
    else if ([item action] == @selector(resetMsx:) ||
             [item action] == @selector(hardResetMsx:))
    {
        // Resetting while paused leads to some odd behavior
        return (machineState == EMU_RUNNING);
    }
    else if ([item action] == @selector(shutDownMsx:))
    {
        if (isRunning)
            [menuItem setTitle:CMLoc(@"Shut Down", @"Menu item title")];
        else
            [menuItem setTitle:CMLoc(@"Start Up", @"Menu item title")];
    }
    else if ([item action] == @selector(pauseMsx:))
    {
        if (machineState == EMU_PAUSED)
            [menuItem setTitle:CMLoc(@"Resume", @"Menu item title")];
        else
            [menuItem setTitle:CMLoc(@"Pause", @"Menu item title")];
        
        return isRunning;
    }
    else if ([item action] == @selector(saveScreenshot:))
    {
        return isRunning;
    }
    else if ([item action] == @selector(clearRecentItems:))
    {
        return [[[NSDocumentController sharedDocumentController] recentDocumentURLs] count] > 0;
    }
    else if ([item action] == @selector(recordAudio:))
    {
        if (!mixerIsLogging(mixer))
            [menuItem setTitle:CMLoc(@"Record Audio…", @"Menu item title")];
        else
            [menuItem setTitle:CMLoc(@"Stop Recording", @"Menu item title")];
        
        return isRunning;
    }
    else if ([item action] == @selector(recordGameplay:))
    {
        [menuItem setState:boardCaptureIsRecording() ? NSOnState : NSOffState];
        
        return isRunning && !boardCaptureIsRecording() && !boardCaptureIsPlaying();
    }
    else if ([item action] == @selector(stopGameplayRecording:))
    {
        return isRunning && (boardCaptureIsRecording() || boardCaptureIsPlaying());
    }
    else if ([item action] == @selector(playBackGameplay:))
    {
        [menuItem setState:boardCaptureIsPlaying() ? NSOnState : NSOffState];
        
        return isRunning
            && [self currentlyLoadedCaptureFilePath] != nil
            && [[NSFileManager defaultManager] fileExistsAtPath:[self currentlyLoadedCaptureFilePath]]
            && !boardCaptureIsPlaying();
    }
    else if ([item action] == @selector(saveGameplayRecording:))
    {
        return isRunning
            && [self currentlyLoadedCaptureFilePath] != nil
            && [[NSFileManager defaultManager] fileExistsAtPath:[self currentlyLoadedCaptureFilePath]]
            && !boardCaptureIsRecording();
    }
    else if ([item action] == @selector(reloadState:))
    {
        return isRunning; // && [self lastLoadedState] != nil;
    }
    else if ([item action] == @selector(overwriteState:))
    {
        return isRunning; // && [self lastSavedState] != nil;
    }
    
    return menuItem.isEnabled;
}

@end
