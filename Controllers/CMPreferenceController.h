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
#import <Cocoa/Cocoa.h>

#import "MGScopeBarDelegateProtocol.h"

#import "CMConfigureJoystickController.h"
#import "CMKeyboardManager.h"

@class CMEmulatorController;
@class CMMsxKeyLayout;
@class MGScopeBar;
@class CMKeyCaptureView;
@class SBJsonParser;
@class CMMachine;

@interface CMPreferenceController : NSWindowController<NSWindowDelegate, NSToolbarDelegate, NSTabViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, MGScopeBarDelegate, CMGamepadConfigurationDelegate, CMKeyboardEventDelegate>
{
    CMEmulatorController *_emulator;
    NSMutableArray *_machines;
    NSArray *_channels;
    NSString *_machineNameFilter;
    NSInteger machineFamilyFilter;
    NSInteger machineStatusFilter;
    CMMachine *_activeMachine;
    
    CMConfigureJoystickController *joystickConfigurator;
    
    IBOutlet NSButton *configureJoypadOneButton;
    IBOutlet NSButton *configureJoypadTwoButton;
    
    IBOutlet NSToolbar *toolbar;
    
    IBOutlet MGScopeBar *keyboardScopeBar;
    IBOutlet MGScopeBar *machineScopeBar;
    
    CMKeyCaptureView *keyCaptureView;
    
    IBOutlet NSTabView *contentTabView;
    
    IBOutlet NSOutlineView *keyboardLayoutEditor;
    IBOutlet NSOutlineView *joystickOneLayoutEditor;
    IBOutlet NSOutlineView *joystickTwoLayoutEditor;
    
    IBOutlet NSSlider *volumeSlider;
    IBOutlet NSSlider *balanceSlider;
    
    IBOutlet NSSlider *brightnessSlider;
    IBOutlet NSSlider *contrastSlider;
    IBOutlet NSSlider *saturationSlider;
    IBOutlet NSSlider *gammaSlider;
    IBOutlet NSSlider *scanlineSlider;
    
    IBOutlet NSArrayController *machinesArrayController;
    IBOutlet NSArrayController *channelsArrayController;

    IBOutlet NSSlider *emulationSpeedSlider;
    IBOutlet NSSearchField *machineSearchField;
    
    NSMutableArray *keyCategories;
    NSMutableArray *joystickOneCategories;
    NSMutableArray *joystickTwoCategories;
    
    NSArray *virtualEmulationSpeedRange;
    
    NSString *selectedKeyboardRegion;
    NSInteger selectedKeyboardShiftState;
    
    NSOperationQueue *downloadQueue;
    SBJsonParser *jsonParser;
}

@property (nonatomic, retain) CMEmulatorController *emulator;
@property (nonatomic, copy) NSMutableArray *machines;
@property (nonatomic, copy) NSArray *channels;
@property (nonatomic, copy) CMMachine *activeMachine;
@property (nonatomic, copy) NSString *machineNameFilter;

- (id)initWithEmulator:(CMEmulatorController *)emulator;

- (IBAction)tabChanged:(id)sender;
- (IBAction)revertAudioClicked:(id)sender;
- (IBAction)revertVideoClicked:(id)sender;
- (IBAction)revertKeyboardClicked:(id)sender;
- (IBAction)revertJoystickOneClicked:(id)sender;
- (IBAction)revertJoystickTwoClicked:(id)sender;

- (IBAction)showMachinesInFinder:(id)sender;
- (IBAction)refreshMachineList:(id)sender;
- (IBAction)installMachineConfiguration:(id)sender;
- (IBAction)removeMachineConfiguration:(id)sender;

- (IBAction)configureJoypadOne:(id)sender;
- (IBAction)configureJoypadTwo:(id)sender;

- (IBAction)performColdRebootClicked:(id)sender;

- (IBAction)emulationSpeedSliderMoved:(id)sender;

@end
