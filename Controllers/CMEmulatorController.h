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
#import <Foundation/Foundation.h>

#import "CMSpecialCartChooserController.h"
#import "CMRepositionCassetteController.h"
#import "CMPreferenceController.h"
#import "CMMsxDisplayView.h"

#import "CMCocoaKeyboard.h"
#import "CMCocoaMouse.h"
#import "CMCocoaSound.h"
#import "CMCocoaJoystick.h"
#import "CMInputDeviceLayout.h"

#include "Properties.h"
#include "VideoRender.h"

NSString * const CMKeyboardLayoutPrefKey;

@class CMAboutController;
@class CMMachineEditorController;

@interface CMEmulatorController : NSWindowController<NSWindowDelegate, NSUserInterfaceValidations, CMSpecialCartSelectedDelegate, CMCassetteRepositionDelegate>
{
    NSString *_fpsDisplay;
    NSString *_fileToLoadAtStartup;
    BOOL _isInitialized;
    
    Mixer *mixer;
    Properties *properties;
    Video *video;
    
    CMCocoaKeyboard *keyboard;
    CMCocoaMouse *mouse;
    CMCocoaSound *sound;
    CMCocoaJoystick *joystick;
    
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
    
    IBOutlet NSTextField *fpsCounter;
    IBOutlet CMMsxDisplayView *screen;
    
    BOOL pausedDueToLostFocus;
}

@property (nonatomic, assign) BOOL isInitialized;

@property (nonatomic, copy) NSString *fpsDisplay;
@property (nonatomic, copy) NSString *fileToLoadAtStartup;

- (Properties *)properties;
- (Video *)video;

- (CMCocoaKeyboard *)keyboard;
- (CMCocoaMouse *)mouse;
- (CMCocoaSound *)sound;
- (CMCocoaJoystick *)joystick;
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

- (void)performColdReboot;
- (BOOL)isStarted;
- (BOOL)isPaused;
- (NSInteger)machineState;

- (BOOL)isInFullScreenMode;

- (void)updateFps:(CGFloat)fps;

- (BOOL)insertCartridge:(NSString *)cartridge
                   slot:(NSInteger)slot;

- (BOOL)insertUnknownMedia:(NSString *)media;

@property NSInteger brightness;
@property NSInteger contrast;
@property NSInteger saturation;
@property NSInteger gamma;
@property NSInteger colorMode;
@property NSInteger signalMode;
@property NSInteger rfModulation;
@property NSInteger scanlines;

@property BOOL stretchHorizontally;
@property BOOL deinterlace;
@property BOOL fdcTimingDisabled;

@property BOOL msxAudioEnabled;
@property BOOL msxMusicEnabled;
@property BOOL moonSoundEnabled;

- (NSInteger)emulationSpeedPercentage;
- (void)setEmulationSpeedPercentage:(NSInteger)percentage;

@property NSInteger deviceInJoystickPort1;
@property NSInteger deviceInJoystickPort2;

+ (NSArray *)machineConfigurations;
- (NSString *)currentMachineConfiguration;

// Apple menu

- (IBAction)openAbout:(id)sender;

// File menu

- (IBAction)openPreferences:(id)sender;

// - Carts
- (IBAction)insertCartridgeSlot1:(id)sender;
- (IBAction)insertCartridgeSlot2:(id)sender;
- (IBAction)insertSpecialCartridgeSlot1:(id)sender;
- (IBAction)insertSpecialCartridgeSlot2:(id)sender;
- (IBAction)ejectCartridgeSlot1:(id)sender;
- (IBAction)ejectCartridgeSlot2:(id)sender;

- (IBAction)toggleCartAutoReset:(id)sender;

// - Disks
- (IBAction)insertDiskSlot1:(id)sender;
- (IBAction)insertDiskSlot2:(id)sender;
- (IBAction)ejectDiskSlot1:(id)sender;
- (IBAction)ejectDiskSlot2:(id)sender;

- (IBAction)toggleDiskAutoReset:(id)sender;

// - Cassettes
- (IBAction)insertCassette:(id)sender;
- (IBAction)ejectCassette:(id)sender;
- (IBAction)rewindCassette:(id)sender;
- (IBAction)repositionCassette:(id)sender;

- (IBAction)toggleCassetteAutoRewind:(id)sender;
- (IBAction)toggleCassetteWriteProtect:(id)sender;

// View menu
- (IBAction)normalSize:(id)sender;
- (IBAction)doubleSize:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;

// MSX menu
- (IBAction)statusMsx:(id)sender;
- (IBAction)resetMsx:(id)sender;
- (IBAction)shutDownMsx:(id)sender;
- (IBAction)pauseMsx:(id)sender;

- (IBAction)loadState:(id)sender;
- (IBAction)saveState:(id)sender;

- (IBAction)saveScreenshot:(id)sender;
- (IBAction)recordAudio:(id)sender;
- (IBAction)recordGameplay:(id)sender;

- (IBAction)editMachineSettings:(id)sender;

@end
