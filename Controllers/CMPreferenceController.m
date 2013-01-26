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
#import "CMPreferenceController.h"

#import "CMEmulatorController.h"
#import "CMCocoaJoystick.h"
#import "CMPreferences.h"
#import "NSString+CMExtensions.h"

#import "CMKeyboardInput.h"
#import "CMMachine.h"

#import "MGScopeBar.h"
#import "CMKeyCaptureView.h"
#import "CMHeaderRowCell.h"

#include "InputEvent.h"
#include "JoystickPort.h"

#pragma mark - KeyCategory

@interface CMKeyCategory : NSObject
{
    NSNumber *_category;
    NSString *_title;
    
    NSMutableArray *items;
}

@property (nonatomic, copy) NSNumber *category;
@property (nonatomic, copy) NSString *title;

- (NSMutableArray *)items;
- (void)sortItems;

@end

@implementation CMKeyCategory

@synthesize category = _category;
@synthesize title = _title;

- (id)init
{
    if ((self = [super init]))
    {
        items = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSMutableArray *)items
{
    return items;
}

- (void)dealloc
{
    self.title = nil;
    self.category = nil;
    
    [items release];
    
    [super dealloc];
}

- (void)sortItems
{
    NSArray *sortedItems = [items sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        return [CMCocoaKeyboard compareKeysByOrderOfAppearance:a
                                                    keyCodeTwo:b];
    }];
    
    [items removeAllObjects];
    [items addObjectsFromArray:sortedItems];
}

@end

#pragma mark - PreferenceController

#define ALERT_RESTART_SYSTEM 1
#define ALERT_REMOVE_SYSTEM  2

#define SCOPEBAR_GROUP_SHIFTED 0
#define SCOPEBAR_GROUP_REGIONS 1

@interface CMPreferenceController ()

- (void)sliderValueChanged:(id)sender;

- (NSInteger)virtualPositionOfSlider:(NSSlider *)slider
                          usingTable:(NSArray *)table;
- (double)physicalPositionOfSlider:(NSSlider *)slider
                       fromVirtual:(NSInteger)virtualPosition
                        usingTable:(NSArray *)table;
- (CMInputDeviceLayout *)inputDeviceLayoutFromOutlineView:(NSOutlineView *)outlineView;
- (void)initializeInputDeviceCategories:(NSMutableArray *)categoryArray
                             withLayout:(CMInputDeviceLayout *)layout;

- (void)synchronizeSettings;
- (NSString *)selectedConfigurationName;
- (void)toggleSystemSpecificButtons;
- (void)updateCurrentConfigurationInformation;

- (void)setDeviceForJoystickPort:(NSInteger)joystickPort
                      toDeviceId:(NSInteger)deviceId;

@end

@implementation CMPreferenceController

@synthesize emulator = _emulator;
@synthesize isSaturationEnabled = _isSaturationEnabled;
@synthesize colorMode = _colorMode;
@synthesize joystickPortPeripherals = _joystickPortPeripherals;
@synthesize joystickPort1Selection = _joystickPort1Selection;
@synthesize joystickPort2Selection = _joystickPort2Selection;

#pragma mark - Init & Dealloc

- (id)initWithEmulator:(CMEmulatorController*)emulator
{
    if ((self = [super initWithWindowNibName:@"Preferences"]))
    {
        self.emulator = emulator;
        
        keyCategories = [[NSMutableArray alloc] init];
        joystickOneCategories = [[NSMutableArray alloc] init];
        joystickTwoCategories = [[NSMutableArray alloc] init];
        availableMachines = [[NSMutableArray alloc] init];
        
        // Set the virtual emulation speed range
        virtualEmulationSpeedRange = [[NSArray alloc] initWithObjects:
                                      [NSNumber numberWithInteger:10],
                                      [NSNumber numberWithInteger:100],
                                      [NSNumber numberWithInteger:250],
                                      [NSNumber numberWithInteger:500],
                                      [NSNumber numberWithInteger:1000],
                                      
                                      nil];
    }
    
    return self;
}

- (void)awakeFromNib
{
    keyCaptureView = nil;
    
    // Initialize sliders
    NSArray *sliders = [NSArray arrayWithObjects:
                        brightnessSlider,
                        contrastSlider,
                        saturationSlider,
                        gammaSlider,
                        scanlineSlider, nil];
    
    [sliders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSSlider *slider = (NSSlider*)obj;
        
        slider.action = @selector(sliderValueChanged:);
        slider.target = self;
    }];
    
    self.isSaturationEnabled = (self.emulator.colorMode == 0);
    
    // Joystick devices
    self.joystickPortPeripherals = [NSMutableArray array];
    NSMutableArray *kvoProxy = [self mutableArrayValueForKey:@"joystickPortPeripherals"];
    NSArray *supportedDevices = [CMCocoaJoystick supportedDevices];
    
    self.joystickPort1Selection = [supportedDevices objectAtIndex:0];
    self.joystickPort2Selection = [supportedDevices objectAtIndex:0];
    
    [supportedDevices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMJoyPortDevice *jd = obj;
        if (self.emulator.deviceInJoystickPort1 == jd.deviceId)
            self.joystickPort1Selection = jd;
        if (self.emulator.deviceInJoystickPort2 == jd.deviceId)
            self.joystickPort2Selection = jd;
        
        [kvoProxy addObject:jd];
    }];
    
    [self initializeInputDeviceCategories:keyCategories
                               withLayout:self.emulator.keyboardLayout];
    [self initializeInputDeviceCategories:joystickOneCategories
                               withLayout:self.emulator.joystickOneLayout];
    [self initializeInputDeviceCategories:joystickTwoCategories
                               withLayout:self.emulator.joystickTwoLayout];
    
    [keyboardLayoutEditor expandItem:nil expandChildren:YES];
    [joystickOneLayoutEditor expandItem:nil expandChildren:YES];
    [joystickTwoLayoutEditor expandItem:nil expandChildren:YES];
    
    // Scope Bar
    [scopeBar setSelected:YES forItem:CMMakeNumber(CMKeyShiftStateNormal) inGroup:SCOPEBAR_GROUP_SHIFTED];
    [scopeBar setSelected:YES forItem:CMMakeNumber(CMKeyLayoutEuropean) inGroup:SCOPEBAR_GROUP_REGIONS];
    
    [self synchronizeSettings];
}

- (void)dealloc
{
    self.joystickPortPeripherals = nil;
    self.joystickPort1Selection = nil;
    self.joystickPort2Selection = nil;
    
    [keyCaptureView release];
    
    [keyCategories release];
    [joystickOneCategories release];
    [joystickTwoCategories release];
    [availableMachines release];
    
    [virtualEmulationSpeedRange release];
    
    [super dealloc];
}

#pragma mark - Private Methods

- (void)updateCurrentConfigurationInformation
{
    CMMachine *selected = [CMMachine machineWithPath:CMGetObjPref(@"machineConfiguration")];
    
    if (selected && [availableMachines containsObject:selected])
        [activeSystemTextView setStringValue:[NSString stringWithFormat:CMLoc(@"YouHaveSelectedSystem_f"),
                                              [selected name], [selected systemName]]];
    else
        [activeSystemTextView setStringValue:CMLoc(@"YouHaveNotSelectedAnySystem")];
}

- (void)synchronizeSettings
{
#ifdef DEBUG
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
#endif
    // Machine configurations
    CMMachine *selectedMachine = [CMMachine machineWithPath:CMGetObjPref(@"machineConfiguration")];
    NSArray *foundConfigurations = [CMEmulatorController machineConfigurations];
    
    [availableMachines removeAllObjects];
    [foundConfigurations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [availableMachines addObject:[CMMachine machineWithPath:obj]];
    }];
    [availableMachines sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
        return [[obj1 name] localizedCaseInsensitiveCompare:[obj2 name]];
    }];
    
    // Selected machine is no longer available found - select closest
    if (![availableMachines containsObject:selectedMachine])
    {
        __block CMMachine *machine = [availableMachines lastObject];
        [availableMachines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            NSInteger comparison = [[selectedMachine name] caseInsensitiveCompare:[obj name]];
            if (comparison == NSOrderedAscending || comparison == NSOrderedSame)
            {
                machine = obj;
                *stop = YES;
            }
        }];
        
        if (machine)
            CMSetObjPref(@"machineConfiguration", [machine path]);
    }
    
    [systemTableView reloadData];
    
    [self toggleSystemSpecificButtons];
    [self updateCurrentConfigurationInformation];
    
    // Update emulation speed
    [emulationSpeedSlider setDoubleValue:[self physicalPositionOfSlider:emulationSpeedSlider
                                                            fromVirtual:CMGetIntPref(@"emulationSpeedPercentage")
                                                             usingTable:virtualEmulationSpeedRange]];
    
    // Update joystick device view
    [self setDeviceForJoystickPort:0
                        toDeviceId:[[self joystickPort1Selection] deviceId]];
    
    [self setDeviceForJoystickPort:1
                        toDeviceId:[[self joystickPort2Selection] deviceId]];
#ifdef DEBUG
    NSLog(@"synchronizeSettings: Took %.02fms",
           [NSDate timeIntervalSinceReferenceDate] - startTime);
#endif
}

- (void)initializeInputDeviceCategories:(NSMutableArray *)categoryArray
                             withLayout:(CMInputDeviceLayout *)layout
{
    NSMutableDictionary *categoryToKeyMap = [NSMutableDictionary dictionary];
    NSMutableArray *unsortedCategories = [NSMutableArray array];
    
    [layout enumerateMappingsUsingBlock:^(NSUInteger virtualCode, CMInputMethod *inputMethod, BOOL *stop)
    {
        NSNumber *category = [NSNumber numberWithInteger:[self.emulator.keyboard categoryForVirtualCode:virtualCode]];
        
        CMKeyCategory *kc = [categoryToKeyMap objectForKey:category];
        
        if (!kc)
        {
            kc = [[[CMKeyCategory alloc] init] autorelease];
            [categoryToKeyMap setObject:kc forKey:category];
            
            kc.category = category;
            kc.title = [self.emulator.keyboard nameForCategory:[category integerValue]];
            
            [unsortedCategories addObject:kc];
        }
        
        [kc.items addObject:[NSNumber numberWithInteger:virtualCode]];
    }];
    
    [unsortedCategories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMKeyCategory *keyCategory = obj;
        [keyCategory sortItems];
    }];
    
    NSArray *sortedCategories = [unsortedCategories sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                {
                                    CMKeyCategory *first = a;
                                    CMKeyCategory *second = b;
                                    
                                    return [first.category compare:second.category];
                                }];
    
    [categoryArray removeAllObjects];
    [categoryArray addObjectsFromArray:sortedCategories];
}

- (void)setDeviceForJoystickPort:(NSInteger)joystickPort
                      toDeviceId:(NSInteger)deviceId
{
    NSTabView *configurationTabView = nil;
    if (joystickPort == 0)
    {
        configurationTabView = joystickOneDeviceTabView;
        [[self emulator] setDeviceInJoystickPort1:deviceId];
    }
    else
    {
        configurationTabView = joystickTwoDeviceTabView;
        [[self emulator] setDeviceInJoystickPort2:deviceId];
    }
    
    if (deviceId == JOYSTICK_PORT_JOYSTICK)
        [configurationTabView selectTabViewItemWithIdentifier:@"twoButtonJoystick"];
    else if (deviceId == JOYSTICK_PORT_MOUSE)
        [configurationTabView selectTabViewItemWithIdentifier:@"mouse"];
    else
        [configurationTabView selectTabViewItemWithIdentifier:@"configurationless"];
}

- (NSInteger)virtualPositionOfSlider:(NSSlider *)slider
                          usingTable:(NSArray *)table
{
    double physicalRange = slider.maxValue - slider.minValue;
    double relativeValue = slider.doubleValue - slider.minValue;
    double physicalTickRange = physicalRange / (slider.numberOfTickMarks - 1);
    
    // Map the tick to the virtual range
    
    NSInteger currentTickStart = relativeValue / physicalTickRange;
    
    double positionWithinTick = slider.doubleValue - [slider tickMarkValueAtIndex:currentTickStart];
    NSInteger valueCurrentTickStart = [[table objectAtIndex:currentTickStart] integerValue];
    NSInteger virtualValue = valueCurrentTickStart;
    
    if (currentTickStart + 1 < table.count)
    {
        NSInteger virtualTickRange = [[table objectAtIndex:currentTickStart + 1] integerValue] - valueCurrentTickStart;
        virtualValue += (positionWithinTick / physicalTickRange) * virtualTickRange;
    }
    
    return virtualValue;
}

- (double)physicalPositionOfSlider:(NSSlider *)slider
                       fromVirtual:(NSInteger)virtualPosition
                        usingTable:(NSArray *)table
{
    __block NSInteger tickIndex = slider.numberOfTickMarks - 1;
    
    [table enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         NSNumber *number = obj;
         if ([number integerValue] > virtualPosition)
         {
             tickIndex = idx - 1;
             *stop = YES;
         }
     }];
    
    double physicalRange = slider.maxValue - slider.minValue;
    double physicalTickRange = physicalRange / (slider.numberOfTickMarks - 1);
    double positionWithinTick = virtualPosition - [[table objectAtIndex:tickIndex] doubleValue];
    
    double physicalValue = [slider tickMarkValueAtIndex:tickIndex];
    if (tickIndex + 1 < slider.numberOfTickMarks)
    {
        NSInteger virtualTickRange = [[table objectAtIndex:tickIndex + 1] integerValue] - [[table objectAtIndex:tickIndex] doubleValue];
        physicalValue += (positionWithinTick / virtualTickRange) * physicalTickRange;
    }
    
    return physicalValue;
}

- (CMInputDeviceLayout *)inputDeviceLayoutFromOutlineView:(NSOutlineView *)outlineView
{
    CMInputDeviceLayout *layout = nil;
    
    if (outlineView == keyboardLayoutEditor)
        layout = self.emulator.keyboardLayout;
    else if (outlineView == joystickOneLayoutEditor)
        layout = self.emulator.joystickOneLayout;
    else if (outlineView == joystickTwoLayoutEditor)
        layout = self.emulator.joystickTwoLayout;
    
    return layout;
}

- (NSString *)selectedConfigurationName
{
    NSInteger selectedRow = [systemTableView selectedRow];
    if (selectedRow < 0)
        return nil;
    
    return [[availableMachines objectAtIndex:selectedRow] path];
}

- (void)toggleSystemSpecificButtons
{
    NSString *selectedConfigurationName = [self selectedConfigurationName];
    BOOL isRemoveButtonEnabled = (selectedConfigurationName != nil)
        && ([availableMachines count] > 1); // At least one machine must remain
    
    [removeMachineButton setEnabled:isRemoveButtonEnabled];
}

#pragma mark - Properties

- (void)setColorMode:(NSInteger)colorMode
{
    self.isSaturationEnabled = (colorMode == 0);
    self.emulator.colorMode = colorMode;
}

- (NSInteger)colorMode
{
    return self.emulator.colorMode;
}

#pragma mark - Actions

- (void)removeMachineConfiguration:(id)sender
{
    NSString *selectedConfigurationName = [self selectedConfigurationName];
    
    if (selectedConfigurationName)
    {
        NSString *message = [NSString stringWithFormat:CMLoc(@"SureYouWantToDeleteTheMachine_f"),
                             selectedConfigurationName];
        NSAlert *alert = [NSAlert alertWithMessageText:message
                                         defaultButton:CMLoc(@"No")
                                       alternateButton:nil
                                           otherButton:CMLoc(@"Yes")
                             informativeTextWithFormat:@""];
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:(void *)ALERT_REMOVE_SYSTEM];
    }
}

- (void)tabChanged:(id)sender
{
    NSToolbarItem *selectedItem = (NSToolbarItem *)sender;
    
    [toolbar setSelectedItemIdentifier:[selectedItem itemIdentifier]];
    [preferenceCategoryTabView selectTabViewItemWithIdentifier:[selectedItem itemIdentifier]];
}

- (void)sliderValueChanged:(id)sender
{
    double range = [sender maxValue] - [sender minValue];
    double tickInterval = range / ([sender numberOfTickMarks] - 1);
    double relativeValue = [sender doubleValue] - [sender minValue];
    
    int nearestTick = round(relativeValue / tickInterval);
    double distance = relativeValue - nearestTick * tickInterval;
    
    if (fabs(distance) < 5.0)
        [sender setDoubleValue:[sender doubleValue] - distance];
}

- (void)revertVideoClicked:(id)sender
{
    self.colorMode = 0;
    self.emulator.brightness = 100;
    self.emulator.contrast = 100;
    self.emulator.saturation = 100;
    self.emulator.gamma = 100;
    
    self.emulator.signalMode = 0;
    self.emulator.rfModulation = 0;
    self.emulator.scanlines = 0;
    self.emulator.deinterlace = YES;
}

- (void)revertKeyboardClicked:(id)sender
{
    CMInputDeviceLayout *layout = self.emulator.keyboardLayout;
    
    [layout loadLayout:[[CMPreferences preferences] defaultKeyboardLayout]];
    [[CMPreferences preferences] setKeyboardLayout:layout];
    
    [keyboardLayoutEditor reloadData];
}

- (void)revertJoystickOneClicked:(id)sender
{
    CMInputDeviceLayout *layout = self.emulator.joystickOneLayout;
    
    [layout loadLayout:[[CMPreferences preferences] defaultJoystickOneLayout]];
    [[CMPreferences preferences] setJoystickOneLayout:layout];
    
    [joystickOneLayoutEditor reloadData];
}

- (void)revertJoystickTwoClicked:(id)sender
{
    CMInputDeviceLayout *layout = self.emulator.joystickTwoLayout;
    
    [layout loadLayout:[[CMPreferences preferences] defaultJoystickTwoLayout]];
    [[CMPreferences preferences] setJoystickTwoLayout:layout];
    
    [joystickTwoLayoutEditor reloadData];
}

- (void)joystickDeviceChanged:(id)sender
{
    if (sender == joystickOneDevice)
    {
        [self setDeviceForJoystickPort:0
                            toDeviceId:[[self joystickPort1Selection] deviceId]];
    }
    else if (sender == joystickTwoDevice)
    {
        [self setDeviceForJoystickPort:1
                            toDeviceId:[[self joystickPort2Selection] deviceId]];
    }
}

- (void)alertDidEnd:(NSAlert *)alert
         returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo
{
    if ((int)contextInfo == ALERT_RESTART_SYSTEM)
    {
        if (returnCode == NSAlertOtherReturn)
            [self.emulator performColdReboot];
    }
    else if ((int)contextInfo == ALERT_REMOVE_SYSTEM)
    {
        if (returnCode == NSAlertOtherReturn)
        {
            NSString *selectedConfigurationName = [self selectedConfigurationName];
            if (selectedConfigurationName)
            {
                // FIXME: show dialog if error
                [CMEmulatorController removeMachineConfiguration:selectedConfigurationName];
            }
        }
    }
}

- (void)performColdRebootClicked:(id)sender
{
    NSAlert *alert = [NSAlert alertWithMessageText:CMLoc(@"SureYouWantToRestartTheMachine")
                                     defaultButton:CMLoc(@"No")
                                   alternateButton:nil
                                       otherButton:CMLoc(@"Yes")
                         informativeTextWithFormat:@""];
    
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:(void *)ALERT_RESTART_SYSTEM];
}

- (void)emulationSpeedSliderMoved:(id)sender
{
    NSSlider *slider = sender;
    
    // Snap to the closest tick
    
    double physicalRange = slider.maxValue - slider.minValue;
    double relativeValue = slider.doubleValue - slider.minValue;
    double physicalTickRange = physicalRange / (slider.numberOfTickMarks - 1);
    
    int nearestTick = round(relativeValue / physicalTickRange);
    double distance = relativeValue - nearestTick * physicalTickRange;
    
    if (fabs(distance) < (physicalTickRange / 10))
        slider.doubleValue = (NSInteger)(slider.doubleValue - distance);
    
    NSInteger percentage = [self virtualPositionOfSlider:slider
                                              usingTable:virtualEmulationSpeedRange];
    
    CMSetIntPref(@"emulationSpeedPercentage", percentage);
}

- (void)showMachinesInFinder:(id)sender
{
    NSString *selectedConfigurationName = [self selectedConfigurationName];
    NSString *finderPath;
    
    if (selectedConfigurationName)
        finderPath = [CMEmulatorController pathForMachineConfigurationNamed:selectedConfigurationName];
    else
        finderPath = [[CMPreferences preferences] machineDirectory];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:finderPath]];
}

#pragma mark - KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
}

#pragma mark - NSWindowController

- (void)windowDidLoad
{
    NSToolbarItem *firstItem = (NSToolbarItem*)[toolbar.items objectAtIndex:0];
    NSString *selectedIdentifier = firstItem.itemIdentifier;
    
    // Select first tab
    toolbar.selectedItemIdentifier = selectedIdentifier;
    [preferenceCategoryTabView selectTabViewItemWithIdentifier:toolbar.selectedItemIdentifier];
}

#pragma mark - NSWindowDelegate

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject
{
    if (anObject == keyboardLayoutEditor
        || anObject == joystickOneLayoutEditor
        || anObject == joystickTwoLayoutEditor)
    {
        if (!keyCaptureView)
            keyCaptureView = [[CMKeyCaptureView alloc] init];
        
        return keyCaptureView;
    }
    
    return nil;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self synchronizeSettings];
}

#pragma mark - NSOutlineViewDataSourceDelegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if ([item isKindOfClass:CMKeyCategory.class])
        return ((CMKeyCategory *)item).items.count;
    
    if (outlineView == keyboardLayoutEditor)
    {
        if (!item)
            return keyCategories.count;
    }
    else if (outlineView == joystickOneLayoutEditor)
    {
        if (!item)
            return joystickOneCategories.count;
    }
    else if (outlineView == joystickTwoLayoutEditor)
    {
        if (!item)
            return joystickTwoCategories.count;
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if ([item isKindOfClass:CMKeyCategory.class])
        return [((CMKeyCategory *)item).items objectAtIndex:index];
    
    if (outlineView == keyboardLayoutEditor)
    {
        if (!item)
            return [keyCategories objectAtIndex:index];
    }
    else if (outlineView == joystickOneLayoutEditor)
    {
        if (!item)
            return [joystickOneCategories objectAtIndex:index];
    }
    else if (outlineView == joystickTwoLayoutEditor)
    {
        if (!item)
            return [joystickTwoCategories objectAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass:[CMKeyCategory class]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[CMKeyCategory class]])
    {
        if ([tableColumn.identifier isEqualToString:@"CMKeyLabelColumn"])
            return [((CMKeyCategory *)item) title];
    }
    else if ([item isKindOfClass:[NSNumber class]])
    {
        CMInputDeviceLayout *layout = [self inputDeviceLayoutFromOutlineView:outlineView];
        NSUInteger virtualCode = [(NSNumber *)item integerValue];
        
        if ([tableColumn.identifier isEqualToString:@"CMKeyLabelColumn"])
        {
            return [self.emulator.keyboard inputNameForVirtualCode:virtualCode
                                                        shiftState:selectedKeyboardShiftState
                                                          layoutId:selectedKeyboardRegion];
        }
        else if ([tableColumn.identifier isEqualToString:@"CMKeyAssignmentColumn"])
        {
            CMKeyboardInput *keyInput = (CMKeyboardInput *)[layout inputMethodForVirtualCode:virtualCode];
            
            return [CMKeyCaptureView descriptionForKeyCode:CMMakeNumber([keyInput keyCode])];
        }
    }
    
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[NSNumber class]]
        && [tableColumn.identifier isEqualToString:@"CMKeyAssignmentColumn"])
    {
        NSNumber *keyCode = [CMKeyCaptureView keyCodeForDescription:(NSString *)object];
        
        CMInputDeviceLayout *layout = [self inputDeviceLayoutFromOutlineView:outlineView];
        
        if (layout)
        {
            NSUInteger virtualCode = [(NSNumber *)item integerValue];
            CMInputMethod *currentMethod = [layout inputMethodForVirtualCode:virtualCode];
            CMKeyboardInput *newMethod = [CMKeyboardInput keyboardInputWithKeyCode:[keyCode integerValue]];
            
            if (![newMethod isEqualToInputMethod:currentMethod])
            {
                [layout assignInputMethod:newMethod toVirtualCode:virtualCode];
                
                CMPreferences *preferences = [CMPreferences preferences];
                if (layout == self.emulator.keyboardLayout)
                    [preferences setKeyboardLayout:layout];
                else if (layout == self.emulator.joystickOneLayout)
                    [preferences setJoystickOneLayout:layout];
                else if (layout == self.emulator.joystickTwoLayout)
                    [preferences setJoystickTwoLayout:layout];
            }
        }
    }
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return ![item isKindOfClass:CMKeyCategory.class];
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[CMKeyCategory class]])
    {
        if (!tableColumn)
        {
            CMKeyCategory *category = (CMKeyCategory *)item;
            return [[[CMHeaderRowCell alloc] initWithHeaderText:[category title]] autorelease];
        }
    }
    
    return nil;
}

#pragma mark - NSTableViewDataSourceDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [availableMachines count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    CMMachine *machine = [availableMachines objectAtIndex:rowIndex];
    
    NSString *columnIdentifer = [aTableColumn identifier];
    if ([columnIdentifer isEqualToString:@"isSelected"])
        return [NSNumber numberWithBool:[machine isEqual:CMGetObjPref(@"machineConfiguration")]];
    else if ([columnIdentifer isEqualToString:@"name"])
        return machine;
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CMMachine *machine = [availableMachines objectAtIndex:row];
    
    NSString *columnIdentifer = [tableColumn identifier];
    if ([columnIdentifer isEqualToString:@"isSelected"])
    {
        CMSetObjPref(@"machineConfiguration", [machine path]);
        [self updateCurrentConfigurationInformation];
    }
    
    [tableView reloadData];
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self toggleSystemSpecificButtons];
}

#pragma mark MGScopeBarDelegate

- (int)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar
{
    return 2;
}

- (NSArray *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(int)groupNumber
{
    if (groupNumber == SCOPEBAR_GROUP_SHIFTED)
    {
        return [NSArray arrayWithObjects:
                CMMakeNumber(CMKeyShiftStateNormal),
                CMMakeNumber(CMKeyShiftStateShifted),
                
                nil];
    }
    else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
    {
        return [NSArray arrayWithObjects:
                CMMakeNumber(CMKeyLayoutArabic),
                CMMakeNumber(CMKeyLayoutBrazilian),
                CMMakeNumber(CMKeyLayoutEstonian),
                CMMakeNumber(CMKeyLayoutEuropean),
                CMMakeNumber(CMKeyLayoutFrench),
                CMMakeNumber(CMKeyLayoutGerman),
                CMMakeNumber(CMKeyLayoutJapanese),
                CMMakeNumber(CMKeyLayoutKorean),
                CMMakeNumber(CMKeyLayoutRussian),
                CMMakeNumber(CMKeyLayoutSpanish),
                CMMakeNumber(CMKeyLayoutSwedish),
                
                nil];
    }
    
    return nil;
}

- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(int)groupNumber // return nil or an empty string for no label.
{
    if (groupNumber == SCOPEBAR_GROUP_REGIONS)
        return CMLoc(@"KeyLayoutRegion");
    
    return nil;
}

- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(int)groupNumber
{
    return MGRadioSelectionMode;
}

- (NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(id)identifier inGroup:(int)groupNumber
{
    if (groupNumber == SCOPEBAR_GROUP_SHIFTED)
    {
        NSNumber *shiftState = identifier;
        
        if ([shiftState isEqualToNumber:CMMakeNumber(CMKeyShiftStateNormal)])
            return CMLoc(@"KeyStateNormal");
        if ([shiftState isEqualToNumber:CMMakeNumber(CMKeyShiftStateShifted)])
            return CMLoc(@"KeyStateShifted");
    }
    else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
    {
        NSNumber *layoutId = identifier;
        
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutArabic)])
            return CMLoc(@"MsxKeyLayoutArabic");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutBrazilian)])
            return CMLoc(@"MsxKeyLayoutBrazilian");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutEstonian)])
            return CMLoc(@"MsxKeyLayoutEstonian");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutEuropean)])
            return CMLoc(@"MsxKeyLayoutEuropean");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutFrench)])
            return CMLoc(@"MsxKeyLayoutFrench");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutGerman)])
            return CMLoc(@"MsxKeyLayoutGerman");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutJapanese)])
            return CMLoc(@"MsxKeyLayoutJapanese");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutKorean)])
            return CMLoc(@"MsxKeyLayoutKorean");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutRussian)])
            return CMLoc(@"MsxKeyLayoutRussian");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutSpanish)])
            return CMLoc(@"MsxKeyLayoutSpanish");
        if ([layoutId isEqualToNumber:CMMakeNumber(CMKeyLayoutSwedish)])
            return CMLoc(@"MsxKeyLayoutSwedish");
    }
    
    return nil;
}

- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected forItem:(id)identifier inGroup:(int)groupNumber
{
    if (groupNumber == SCOPEBAR_GROUP_SHIFTED)
    {
        NSNumber *shiftState = identifier;
        selectedKeyboardShiftState = [shiftState integerValue];
        
        [keyboardLayoutEditor reloadData];
    }
    else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
    {
        NSNumber *layoutId = identifier;
        selectedKeyboardRegion = [layoutId integerValue];
        
        [keyboardLayoutEditor reloadData];
    }
}

@end