/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012 Akop Karapetyan
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

#include "Properties.h"
#include "VideoRender.h"

NSString * const CMKeyboardLayoutPrefKey;

@class CMMachineEditorController;

@interface CMEmulatorController : NSWindowController<NSWindowDelegate, NSUserInterfaceValidations, CMSpecialCartSelectedDelegate, CMCassetteRepositionDelegate>
{
    Mixer *mixer;
    Properties *properties;
    Video *video;
    
    CMCocoaKeyboard *keyboard;
    CMCocoaMouse *mouse;
    CMCocoaSound *sound;
    CMCocoaJoystick *joystick;
    
    CMPreferenceController *preferenceController;
    CMMachineEditorController *machineEditorController;
    
    NSArray *openRomFileTypes;
    NSArray *openDiskFileTypes;
    NSArray *openCassetteFileTypes;
    NSArray *stateFileTypes;
    NSArray *captureAudioTypes;
    NSArray *captureGameplayTypes;
    
    IBOutlet NSTextField *fpsCounter;
    IBOutlet CMMsxDisplayView *screen;
}

@property (nonatomic, copy) NSString *lastOpenSavePanelDirectory;

@property (nonatomic, copy) NSString *fpsDisplay;

@property (nonatomic, retain) CMSpecialCartChooserController *cartChooser;
@property (nonatomic, retain) CMRepositionCassetteController *cassetteRepositioner;

+ (CMEmulatorController *)emulator;

- (Properties *)properties;
- (Video *)video;

- (CMCocoaKeyboard *)keyboard;
- (CMCocoaMouse *)mouse;
- (CMCocoaSound *)sound;
- (CMCocoaJoystick *)joystick;
- (CMMsxDisplayView *)screen;

- (void)start;
- (void)stop;
- (void)performColdReboot;
- (BOOL)isRunning;

- (BOOL)isInFullScreenMode;

- (void)updateFps:(CGFloat)fps;

@property (nonatomic, assign) BOOL isInitialized;

@property NSInteger brightness;
@property NSInteger contrast;
@property NSInteger saturation;
@property NSInteger gamma;
@property NSInteger colorMode;
@property NSInteger signalMode;
@property NSInteger rfModulation;
@property NSInteger scanlines;

@property BOOL stretchHorizontally;
@property BOOL stretchVertically;
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
- (IBAction)insertFolderSlot1:(id)sender;
- (IBAction)insertFolderSlot2:(id)sender;
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
- (IBAction)tripleSize:(id)sender;

// MSX menu
- (IBAction)statusMsx:(id)sender;
- (IBAction)resetMsx:(id)sender;
- (IBAction)shutDownMsx:(id)sender;
- (IBAction)pauseMsx:(id)sender;

- (IBAction)loadState:(id)sender;
- (IBAction)saveState:(id)sender;

- (IBAction)recordAudio:(id)sender;
- (IBAction)recordGameplay:(id)sender;

- (IBAction)editMachineSettings:(id)sender;

@end
