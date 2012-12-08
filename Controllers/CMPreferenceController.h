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
#import <Cocoa/Cocoa.h>

@class CMEmulatorController;
@class CMJoyPortDevice;

@class SRRecorderControl;

@interface CMPreferenceController : NSWindowController<NSToolbarDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    IBOutlet NSToolbar *toolbar;
    IBOutlet NSTabView *tabView;
    
    IBOutlet NSOutlineView *keyboardLayoutEditor;
    IBOutlet NSOutlineView *joystickOneLayoutEditor;
    IBOutlet NSOutlineView *joystickTwoLayoutEditor;
    
    IBOutlet NSSlider *brightnessSlider;
    IBOutlet NSSlider *contrastSlider;
    IBOutlet NSSlider *saturationSlider;
    IBOutlet NSSlider *gammaSlider;
    IBOutlet NSSlider *scanlineSlider;
    
    IBOutlet NSSlider *emulationSpeedSlider;
    
    NSMutableArray *keyCategories;
    NSMutableArray *joystickOneCategories;
    NSMutableArray *joystickTwoCategories;
    
    CMEmulatorController *_emulator;
    NSArray *virtualEmulationSpeedRange;
}

@property (nonatomic, retain) CMEmulatorController *emulator;

@property (nonatomic, assign) BOOL isSaturationEnabled;

@property (nonatomic, retain) NSMutableArray *joystickPortPeripherals;
@property (nonatomic, retain) CMJoyPortDevice *joystickPort1Selection;
@property (nonatomic, retain) CMJoyPortDevice *joystickPort2Selection;

@property (nonatomic, retain) NSMutableArray *machineConfigurations;

@property NSInteger colorMode;

- (id)initWithEmulator:(CMEmulatorController *)emulator;

- (IBAction)tabChanged:(id)sender;
- (IBAction)joystickDeviceChanged:(id)sender;
- (IBAction)revertVideoClicked:(id)sender;
- (IBAction)revertKeyboardClicked:(id)sender;
- (IBAction)revertJoystickOneClicked:(id)sender;
- (IBAction)revertJoystickTwoClicked:(id)sender;

- (IBAction)performColdRebootClicked:(id)sender;

- (IBAction)emulationSpeedSliderMoved:(id)sender;

@end
