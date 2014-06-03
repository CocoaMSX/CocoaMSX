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
#import <Foundation/Foundation.h>

#import "CMSpecialCartChooserController.h"
#import "CMRepositionCassetteController.h"
#import "CMPreferenceController.h"
#import "CMMsxDisplayView.h"

#import "CMCocoaInput.h"
#import "CMCocoaMouse.h"
#import "CMCocoaSound.h"
#import "CMInputDeviceLayout.h"

#include "Properties.h"
#include "VideoRender.h"

NSString * const CMKeyboardLayoutPrefKey;

@class CMAboutController;
@class CMMachineEditorController;

@interface CMEmulatorController : NSWindowController<NSWindowDelegate, NSUserInterfaceValidations, CMSpecialCartSelectedDelegate, CMCassetteRepositionDelegate, NSOpenSavePanelDelegate>
{
    NSInteger lastLedState;
    NSString *_fpsDisplay;
    NSString *_fileToLoadAtStartup;
    BOOL _isInitialized;
    NSString *_currentlyLoadedCaptureFilePath;
    NSString *_lastLoadedState;
    NSString *_lastSavedState;
    
    NSString *gameplayCaptureTempFilename;
    
    Mixer *mixer;
    Properties *properties;
    Video *video;
    
    CMCocoaInput *input;
    CMCocoaMouse *mouse;
    CMCocoaSound *sound;
    
    CMAboutController *aboutController;
    CMPreferenceController *preferenceController;
    CMMachineEditorController *machineEditorController;
    CMSpecialCartChooserController *cartChooser;
    CMRepositionCassetteController *cassetteRepositioner;
    
    NSMutableArray *inputDeviceLayouts;
    
    NSArray *openRomFileTypes;
    NSArray *openDiskFileTypes;
    NSArray *openCassetteFileTypes;
    NSArray *stateFileTypes;
    NSArray *captureAudioTypes;
    NSArray *captureGameplayTypes;
    
    NSArray *listOfPreferenceKeysToObserve;
    
    NSMutableDictionary *romTypeIndices;
    NSMutableDictionary *romTypes;
    NSMutableArray *romTypeNames;
    
    IBOutlet NSView *unrecognizedFileAccessoryView;
    IBOutlet NSView *romSelectionAccessoryView;
    
    IBOutlet NSButton *openAnyFileCheckbox;
    IBOutlet NSButton *openAnyRomFileCheckbox;
    IBOutlet NSPopUpButton *romTypeDropdown;
    
    IBOutlet NSBox *statusBar;
    IBOutlet NSTextField *fpsCounter;
    IBOutlet CMMsxDisplayView *screen;
    
    IBOutlet NSMenuItem *recentCartridgesA;
    IBOutlet NSMenuItem *recentCartridgesB;
    IBOutlet NSMenuItem *recentDisksA;
    IBOutlet NSMenuItem *recentDisksB;
    IBOutlet NSMenuItem *recentCassettes;
    
    IBOutlet NSImageView *fdd0Led;
    IBOutlet NSImageView *fdd1Led;
    IBOutlet NSImageView *codeLed;
    IBOutlet NSImageView *capsLed;
    IBOutlet NSImageView *powerLed;
    IBOutlet NSImageView *pauseLed;
    IBOutlet NSImageView *renshaLed;
    IBOutlet NSImageView *casLed;
    
    NSOpenPanel *currentlyActiveOpenPanel;
    NSArray *currentlySupportedFileTypes;
    
    BOOL pausedDueToLostFocus;
}

@property (nonatomic, copy) NSString *fpsDisplay;
@property (nonatomic, copy) NSString *fileToLoadAtStartup;
@property (nonatomic, copy) NSString *currentlyLoadedCaptureFilePath;
@property (nonatomic, copy) NSString *lastSavedState;
@property (nonatomic, copy) NSString *lastLoadedState;

@property (nonatomic, assign) NSInteger scanlines;

@property (nonatomic, assign) BOOL isInitialized;

- (Properties *)properties;
- (Video *)video;

- (CMCocoaInput *)input;
- (CMCocoaMouse *)mouse;
- (CMCocoaSound *)sound;
- (CMMsxDisplayView *)screen;

- (CMInputDeviceLayout *)keyboardLayout;
- (CMInputDeviceLayout *)joystickOneLayout;
- (CMInputDeviceLayout *)joystickTwoLayout;

- (NSArray *)inputDeviceLayouts;

- (void)start;
- (void)stop;
- (void)pause;
- (void)resume;

- (BOOL)saveStateToFile:(NSString *)file;

- (void)setEmulationSpeedAsPercentage:(NSInteger)percentage;

- (void)performColdReboot;
- (BOOL)isStarted;
- (BOOL)isPaused;
- (NSInteger)machineState;

- (BOOL)isInFullScreenMode;

- (void)updateFps:(CGFloat)fps;

- (BOOL)insertCartridge:(NSString *)cartridge
                   slot:(NSInteger)slot
                   type:(RomType)type;

- (BOOL)insertUnknownMedia:(NSString *)media;

+ (NSArray *)machineConfigurations;
+ (BOOL)removeMachineConfiguration:(NSString *)configurationName;
+ (NSString *)pathForMachineConfigurationNamed:(NSString *)name;

- (NSString *)currentMachineConfiguration;

- (NSString *)runningMachineConfiguration;

- (BOOL)canInsertDiskettes;
- (BOOL)canInsertCassettes;

- (IBAction)openAnyFile:(id)sender;

// Apple menu

- (IBAction)openAbout:(id)sender;
- (IBAction)openPreferences:(id)sender;

// File menu

- (IBAction)insertCartridgeSlot1:(id)sender;
- (IBAction)insertCartridgeSlot2:(id)sender;
- (IBAction)insertSpecialCartridgeSlot1:(id)sender;
- (IBAction)insertSpecialCartridgeSlot2:(id)sender;
- (IBAction)ejectCartridgeSlot1:(id)sender;
- (IBAction)ejectCartridgeSlot2:(id)sender;

- (IBAction)toggleCartAutoReset:(id)sender;

- (IBAction)insertDiskSlot1:(id)sender;
- (IBAction)insertDiskSlot2:(id)sender;
- (IBAction)ejectDiskSlot1:(id)sender;
- (IBAction)ejectDiskSlot2:(id)sender;

- (IBAction)toggleDiskAutoReset:(id)sender;

- (IBAction)insertCassette:(id)sender;
- (IBAction)ejectCassette:(id)sender;
- (IBAction)rewindCassette:(id)sender;
- (IBAction)repositionCassette:(id)sender;

- (IBAction)toggleCassetteAutoRewind:(id)sender;
- (IBAction)toggleCassetteWriteProtect:(id)sender;

- (IBAction)loadState:(id)sender;
- (IBAction)reloadState:(id)sender;
- (IBAction)saveState:(id)sender;
- (IBAction)overwriteState:(id)sender;

- (IBAction)saveScreenshot:(id)sender;

- (IBAction)recordAudio:(id)sender;

- (IBAction)openGameplayRecording:(id)sender;
- (IBAction)saveGameplayRecording:(id)sender;
- (IBAction)recordGameplay:(id)sender;
- (IBAction)stopGameplayRecording:(id)sender;
- (IBAction)playBackGameplay:(id)sender;

- (IBAction)insertRecentCartridgeA:(id)sender;
- (IBAction)insertRecentCartridgeB:(id)sender;
- (IBAction)insertRecentDiskA:(id)sender;
- (IBAction)insertRecentDiskB:(id)sender;
- (IBAction)insertRecentCassette:(id)sender;
- (IBAction)clearRecentItems:(id)sender;

// Edit menu

- (IBAction)pasteText:(id)sender;

// View menu

- (IBAction)normalSize:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;

// MSX menu

- (IBAction)statusMsx:(id)sender;
- (IBAction)resetMsx:(id)sender;
- (IBAction)hardResetMsx:(id)sender;
- (IBAction)shutDownMsx:(id)sender;
- (IBAction)pauseMsx:(id)sender;

@end
