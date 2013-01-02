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
#import "CMPreferenceController.h"

#import "CMEmulatorController.h"
#import "CMCocoaJoystick.h"
#import "CMPreferences.h"

#import "CMKeyboardInput.h"

#import "SRRecorderTableCellView.h"
#import "SRRecorderControl.h"

#import "MGScopeBar.h"

#include "InputEvent.h"

#pragma mark - CMOutlineHeaderRowView

@interface CMOutlineHeaderRowView : NSTableRowView

@end

@implementation CMOutlineHeaderRowView

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
    NSColor *gradientStartColor = [[NSColor alternateSelectedControlColor] highlightWithLevel:0.8f];
    NSColor *gradientEndColor = [[NSColor alternateSelectedControlColor] highlightWithLevel:0.4f];
    
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:gradientStartColor
                                                          endingColor:gradientEndColor] autorelease];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    [[NSColor gridColor] set];
    [[NSBezierPath bezierPathWithRect:self.bounds] fill];
    
    [gradient drawInRect:NSInsetRect(self.bounds, 0, 1) angle:90.0f];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end

#pragma mark - KeyCategory

@interface CMKeyCategory : NSObject
{
    NSMutableArray *items;
}

@property (nonatomic, copy) NSNumber *category;
@property (nonatomic, copy) NSString *title;

- (NSMutableArray *)items;
- (void)sortItems;

@end

@implementation CMKeyCategory

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

@end

@implementation CMPreferenceController

@synthesize emulator = _emulator;

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
    }
    
    return self;
}

- (void)awakeFromNib
{
    CMPreferences *prefs = [CMPreferences preferences];
    
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
    
    // Set the virtual emulation speed range
    
    virtualEmulationSpeedRange = [[NSArray alloc] initWithObjects:
                                  [NSNumber numberWithInteger:10],
                                  [NSNumber numberWithInteger:100],
                                  [NSNumber numberWithInteger:250],
                                  [NSNumber numberWithInteger:500],
                                  [NSNumber numberWithInteger:1000], nil];
    
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
    
    // Machine configurations
    
    NSArray *machineConfigurations = [CMEmulatorController machineConfigurations];
    [availableMachineArrayController addObjects:machineConfigurations];
    
    // If there is no matching configuration, use the first available
    NSString *currentConfiguration = [prefs machineConfiguration];
    BOOL configurationFound = [machineConfigurations containsObject:currentConfiguration];
    
    if (!configurationFound && machineConfigurations.count > 0)
        [prefs setMachineConfiguration:[machineConfigurations objectAtIndex:0]];
    
    // FIXME: These need to be synchronized when the window re-opens
    
    [emulationSpeedSlider setDoubleValue:[self physicalPositionOfSlider:emulationSpeedSlider
                                                            fromVirtual:prefs.emulationSpeedPercentage
                                                             usingTable:virtualEmulationSpeedRange]];
    
    [self initializeInputDeviceCategories:keyCategories
                               withLayout:self.emulator.keyboardLayout];
    [self initializeInputDeviceCategories:joystickOneCategories
                               withLayout:self.emulator.joystickOneLayout];
    [self initializeInputDeviceCategories:joystickTwoCategories
                               withLayout:self.emulator.joystickTwoLayout];
    
    [scopeBar setSelected:YES forItem:CMMakeNumber(CMKeyShiftStateNormal) inGroup:SCOPEBAR_GROUP_SHIFTED];
    [scopeBar setSelected:YES forItem:CMMakeNumber(CMKeyLayoutEuropean) inGroup:SCOPEBAR_GROUP_REGIONS];
    
    [keyboardLayoutEditor expandItem:nil expandChildren:YES];
    [joystickOneLayoutEditor expandItem:nil expandChildren:YES];
    [joystickTwoLayoutEditor expandItem:nil expandChildren:YES];
}

- (void)dealloc
{
    self.joystickPortPeripherals = nil;
    self.joystickPort1Selection = nil;
    self.joystickPort2Selection = nil;
    
    [keyCategories release];
    [joystickOneCategories release];
    [joystickTwoCategories release];
    [availableMachines release];
    
    [virtualEmulationSpeedRange release];
    
    [super dealloc];
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

#pragma mark - Methods

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

#pragma mark - Actions

- (void)tabChanged:(id)sender
{
    NSToolbarItem *selectedItem = (NSToolbarItem*)sender;
    
    [tabView selectTabViewItemWithIdentifier:selectedItem.itemIdentifier];
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
    self.emulator.stretchHorizontally = NO;
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
    NSPopUpButton *button = sender;
    
    if ([button.identifier isEqualToString:@"CMJoystickPortDevice1"])
        self.emulator.deviceInJoystickPort1 = self.joystickPort1Selection.deviceId;
    if ([button.identifier isEqualToString:@"CMJoystickPortDevice2"])
        self.emulator.deviceInJoystickPort2 = self.joystickPort2Selection.deviceId;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertOtherReturn)
        [self.emulator performColdReboot];
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
                        contextInfo:nil];
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
    
    self.emulator.emulationSpeedPercentage = percentage;
    [CMPreferences preferences].emulationSpeedPercentage = percentage;
}

- (void)showMachinesInFinder:(id)sender
{
    CMPreferences *prefs = [CMPreferences preferences];
    NSURL *machinesUrl = [NSURL fileURLWithPath:prefs.machineDirectory];
    
    [[NSWorkspace sharedWorkspace] openURL:machinesUrl];
}

#pragma mark - NSWindowController

- (void)windowDidLoad
{
    NSToolbarItem *firstItem = (NSToolbarItem*)[toolbar.items objectAtIndex:0];
    NSString *selectedIdentifier = firstItem.itemIdentifier;
    
    // Select first tab
    toolbar.selectedItemIdentifier = selectedIdentifier;
    [tabView selectTabViewItemWithIdentifier:toolbar.selectedItemIdentifier];
}

#pragma mark - NSOutlineViewDataSourceDelegate

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

- (id)outlineView:(NSOutlineView *)outlineView
viewForTableColumn:(NSTableColumn *)tableColumn
             item:(id)item
{
    NSTableCellView *cell = nil;
    
    if (!item)
        return nil;
    
    if ([item isKindOfClass:[CMKeyCategory class]])
    {
        if ([tableColumn.identifier isEqualToString:@"CMKeyLabelColumn"])
        {
            CMKeyCategory *keyCategory = item;
            cell = [outlineView makeViewWithIdentifier:@"headerColumn" owner:self];
            
            if (!cell)
            {
                NSRect cellFrame = NSMakeRect(0, 0, tableColumn.width, outlineView.rowHeight);
                
                cell = [[[NSTableCellView alloc] initWithFrame:cellFrame] autorelease];
                cell.identifier = @"headerColumn";
                cell.textField = [[[NSTextField alloc] initWithFrame:cell.frame] autorelease];
                
                [cell.textField setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
                [cell.textField setBordered:NO];
                [cell.textField setEditable:NO];
                [cell.textField setDrawsBackground:NO];
                [cell.textField.cell setLineBreakMode:NSLineBreakByTruncatingTail];
                [cell.textField setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
                
                [cell addSubview:cell.textField];
            }
            
            cell.textField.stringValue = keyCategory.title;
        }
    }
    else if ([item isKindOfClass:[NSNumber class]])
    {
        CMInputDeviceLayout *layout = [self inputDeviceLayoutFromOutlineView:outlineView];;
        
        NSUInteger virtualCode = [(NSNumber *)item integerValue];
        CMKeyboardInput *keyInput = (CMKeyboardInput *)[layout inputMethodForVirtualCode:virtualCode];
        
        if ([tableColumn.identifier isEqualToString:@"CMKeyLabelColumn"])
        {
            cell = [outlineView makeViewWithIdentifier:tableColumn.identifier owner:self];
            
            if (!cell)
            {
                NSRect cellFrame = NSMakeRect(0, 0, tableColumn.width, outlineView.rowHeight);
                
                cell = [[[NSTableCellView alloc] initWithFrame:cellFrame] autorelease];
                cell.identifier = tableColumn.identifier;
                cell.textField = [[[NSTextField alloc] initWithFrame:cell.frame] autorelease];
                
                [cell.textField setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
                [cell.textField setBordered:NO];
                [cell.textField setEditable:NO];
                [cell.textField setDrawsBackground:NO];
                [cell.textField.cell setLineBreakMode:NSLineBreakByTruncatingTail];
                [cell.textField setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
                
                [cell addSubview:cell.textField];
            }
            
            cell.textField.stringValue = [self.emulator.keyboard inputNameForVirtualCode:virtualCode
                                                                              shiftState:selectedKeyboardShiftState
                                                                                layoutId:selectedKeyboardRegion];
        }
        else if ([tableColumn.identifier isEqualToString:@"CMKeyAssignmentColumn"])
        {
            SRRecorderTableCellView *srCell = [outlineView makeViewWithIdentifier:tableColumn.identifier owner:self];
            
            if (!srCell)
            {
                NSRect cellFrame = NSMakeRect(0, 0, tableColumn.width, outlineView.rowHeight);
                
                srCell = [[[SRRecorderTableCellView alloc] initWithFrame:cellFrame] autorelease];
                srCell.identifier = tableColumn.identifier;
                srCell.recorderControl = [[[SRRecorderControl alloc] initWithFrame:srCell.frame] autorelease];
                
                srCell.recorderControl.delegate = self;
                srCell.recorderControl.allowedFlags = SRLeftShiftMask | SRRightShiftMask
                    | SRLeftAlternateMask | SRRightAlternateMask
                    | SRLeftControlKeyMask | SRRightControlKeyMask;
                
                srCell.recorderControl.useSingleKeyMode = YES;
                srCell.recorderControl.tableCellMode = YES;
                
                [srCell.recorderControl setAllowsKeyOnly:YES escapeKeysRecord:YES];
                [srCell.recorderControl setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
                
                [srCell addSubview:srCell.recorderControl];
            }
            
            srCell.recorderControl.tag = virtualCode;
            [srCell.recorderControl setKeyCombo:SRMakeKeyCombo((keyInput) ? keyInput.keyCode : ShortcutRecorderEmptyCode,
                                                               ShortcutRecorderEmptyFlags)];
            
            cell = srCell;
        }
    }
    
    return cell;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    NSTableRowView *row = nil;
    
    if ([item isKindOfClass:[CMKeyCategory class]])
    {
        NSRect rowRect = NSMakeRect(0, 0, outlineView.frame.size.width, outlineView.rowHeight);
        row = [[[CMOutlineHeaderRowView alloc] initWithFrame:rowRect] autorelease];
    }
    
    return row;
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return ![item isKindOfClass:CMKeyCategory.class];
}

#pragma mark - SRRecorderDelegate

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    CMPreferences *preferences = [CMPreferences preferences];
    
    NSOutlineView *outlineView = (NSOutlineView *)[[[aRecorder superview] superview] superview];
    CMInputDeviceLayout *layout = [self inputDeviceLayoutFromOutlineView:outlineView];
    
    if (layout)
    {
        NSInteger virtualCode = aRecorder.tag;
        CMInputMethod *currentMethod = [layout inputMethodForVirtualCode:virtualCode];
        CMKeyboardInput *newMethod = [CMKeyboardInput keyboardInputWithKeyCode:newKeyCombo.code];
        
        if (![newMethod isEqualToInputMethod:currentMethod])
        {
            [layout assignInputMethod:newMethod toVirtualCode:virtualCode];
            
            if (layout == self.emulator.keyboardLayout)
                [preferences setKeyboardLayout:layout];
            else if (layout == self.emulator.joystickOneLayout)
                [preferences setJoystickOneLayout:layout];
            else if (layout == self.emulator.joystickTwoLayout)
                [preferences setJoystickTwoLayout:layout];
        }
    }
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
    {
        return CMLoc(@"KeyLayoutRegion");
    }
    
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