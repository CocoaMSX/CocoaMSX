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
#import <Cocoa/Cocoa.h>

#import "MGScopeBarDelegateProtocol.h"

@class CMEmulatorController;
@class CMMsxKeyLayout;
@class MGScopeBar;
@class CMKeyCaptureView;
@class SBJsonParser;

@interface CMPreferenceController : NSWindowController<NSWindowDelegate, NSToolbarDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTabViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, MGScopeBarDelegate>
{
    CMEmulatorController *_emulator;
    
    NSInteger machineDisplayMode;
    
    IBOutlet NSButton *addMachineButton;
    IBOutlet NSButton *removeMachineButton;
    
    IBOutlet NSToolbar *toolbar;
    
    IBOutlet MGScopeBar *keyboardScopeBar;
    IBOutlet MGScopeBar *machineScopeBar;
    
    CMKeyCaptureView *keyCaptureView;
    
    IBOutlet NSTableView *systemTableView;
    IBOutlet NSTableView *mixerTableView;
    IBOutlet NSTextField *activeSystemTextView;
    
    IBOutlet NSTabView *contentTabView;
    IBOutlet NSTabView *mixerTabView;
    
    IBOutlet NSOutlineView *keyboardLayoutEditor;
    IBOutlet NSOutlineView *joystickOneLayoutEditor;
    IBOutlet NSOutlineView *joystickTwoLayoutEditor;
    
    IBOutlet NSSlider *psgVolumeSlider;
    IBOutlet NSSlider *psgBalanceSlider;
    IBOutlet NSSlider *sccVolumeSlider;
    IBOutlet NSSlider *sccBalanceSlider;
    IBOutlet NSSlider *msxMusicVolumeSlider;
    IBOutlet NSSlider *msxMusicBalanceSlider;
    IBOutlet NSSlider *msxAudioVolumeSlider;
    IBOutlet NSSlider *msxAudioBalanceSlider;
    IBOutlet NSSlider *keyboardVolumeSlider;
    IBOutlet NSSlider *keyboardBalanceSlider;
    IBOutlet NSSlider *moonSoundVolumeSlider;
    IBOutlet NSSlider *moonSoundBalanceSlider;
    
    IBOutlet NSSlider *brightnessSlider;
    IBOutlet NSSlider *contrastSlider;
    IBOutlet NSSlider *saturationSlider;
    IBOutlet NSSlider *gammaSlider;
    IBOutlet NSSlider *scanlineSlider;
    
    IBOutlet NSSlider *emulationSpeedSlider;
    
    NSMutableArray *keyCategories;
    NSMutableArray *joystickOneCategories;
    NSMutableArray *joystickTwoCategories;
    NSArray *mixers;
    
    NSMutableArray *installedMachines;
    NSMutableArray *installableMachines;
    NSMutableArray *allMachines;
    
    NSArray *virtualEmulationSpeedRange;
    
    NSInteger selectedKeyboardRegion;
    NSInteger selectedKeyboardShiftState;
    
    NSOperationQueue *downloadQueue;
    SBJsonParser *jsonParser;
}

@property (nonatomic, retain) CMEmulatorController *emulator;

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

- (IBAction)performColdRebootClicked:(id)sender;

- (IBAction)emulationSpeedSliderMoved:(id)sender;

@end
