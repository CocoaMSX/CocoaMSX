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

@property (nonatomic, copy) NSString *title;

- (NSMutableArray *)items;
- (void)sortItemsUsingEmulator:(CMEmulatorController *)emulator;

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
    [items release];
    
    [super dealloc];
}

- (void)sortItemsUsingEmulator:(CMEmulatorController *)emulator
{
    NSArray *sortedItems = [items sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        NSString *first = [emulator.keyboard inputNameForVirtualCode:[(NSNumber *)a integerValue]];
        NSString *second = [emulator.keyboard inputNameForVirtualCode:[(NSNumber *)b integerValue]];
        
        return [first compare:second];
    }];
    
    [items removeAllObjects];
    [items addObjectsFromArray:sortedItems];
}

@end

#pragma mark - PreferenceController

@interface CMPreferenceController ()

- (void)sliderValueChanged:(id)sender;

- (NSInteger)virtualPositionOfSlider:(NSSlider *)slider
                          usingTable:(NSArray *)table;
- (double)physicalPositionOfSlider:(NSSlider *)slider
                       fromVirtual:(NSInteger)virtualPosition
                        usingTable:(NSArray *)table;
- (CMInputDeviceLayout *)inputDeviceLayoutFromOutlineView:(NSOutlineView *)outlineView;

@end

@implementation CMPreferenceController

@synthesize emulator = _emulator;

#pragma mark - Init & Dealloc

- (id)initWithEmulator:(CMEmulatorController*)emulator
{
    if ((self = [super initWithWindowNibName:@"Preferences"]))
    {
        keyCategories = [[NSMutableArray alloc] init];
        joystickOneCategories = [[NSMutableArray alloc] init];
        joystickTwoCategories = [[NSMutableArray alloc] init];
        
        self.emulator = emulator;
    }
    
    return self;
}

- (void)awakeFromNib
{
    CMPreferences *prefs = [CMPreferences preferences];
    
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
    
    self.machineConfigurations = [NSMutableArray array];
    NSMutableArray *machineConfigurationsProxy = [self mutableArrayValueForKey:@"machineConfigurations"];
    NSArray *machineConfigurations = [CMEmulatorController machineConfigurations];
    
    __block BOOL configurationFound = NO;
    NSString *currentConfiguration = [prefs machineConfiguration];
    
    [machineConfigurations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *configurationName = obj;
         
        if ([configurationName isEqualToString:currentConfiguration])
            configurationFound = YES;
         
        [machineConfigurationsProxy addObject:configurationName];
    }];
    
    // If there is no matching configuration, use the first available
    if (!configurationFound && machineConfigurations.count > 0)
        [prefs setMachineConfiguration:[machineConfigurations objectAtIndex:0]];
    
    // FIXME: These need to be synchronized when the window re-opens
    
    [emulationSpeedSlider setDoubleValue:[self physicalPositionOfSlider:emulationSpeedSlider
                                                            fromVirtual:prefs.emulationSpeedPercentage
                                                             usingTable:virtualEmulationSpeedRange]];
    
    NSMutableDictionary *categoryToKeyMap = [NSMutableDictionary dictionary];
    
    [self.emulator.keyboardLayout enumerateMappingsUsingBlock:^(NSUInteger virtualCode, CMInputMethod *inputMethod, BOOL *stop)
    {
        NSString *categoryName = [self.emulator.keyboard categoryNameForVirtualCode:virtualCode];
        
        CMKeyCategory *kc = [categoryToKeyMap objectForKey:categoryName];
        
        if (!kc)
        {
            kc = [[[CMKeyCategory alloc] init] autorelease];
            [categoryToKeyMap setObject:kc forKey:categoryName];
            
            kc.title = categoryName;
            
            [keyCategories addObject:kc];
        }
        
        [kc.items addObject:[NSNumber numberWithInteger:virtualCode]];
    }];
    
    [keyCategories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMKeyCategory *keyCategory = obj;
        [keyCategory sortItemsUsingEmulator:self.emulator];
    }];
    
    [keyboardLayoutEditor expandItem:nil expandChildren:YES];
    
    [categoryToKeyMap removeAllObjects];
    
    [self.emulator.joystickOneLayout enumerateMappingsUsingBlock:^(NSUInteger virtualCode, CMInputMethod *inputMethod, BOOL *stop)
    {
        NSString *categoryName = [self.emulator.keyboard categoryNameForVirtualCode:virtualCode];
        
        CMKeyCategory *kc = [categoryToKeyMap objectForKey:categoryName];
        
        if (!kc)
        {
            kc = [[[CMKeyCategory alloc] init] autorelease];
            [categoryToKeyMap setObject:kc forKey:categoryName];
            
            kc.title = categoryName;
            
            [joystickOneCategories addObject:kc];
        }
        
        [kc.items addObject:[NSNumber numberWithInteger:virtualCode]];
    }];
    
    [joystickOneCategories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMKeyCategory *keyCategory = obj;
        [keyCategory sortItemsUsingEmulator:self.emulator];
    }];
    
    [joystickOneLayoutEditor expandItem:nil expandChildren:YES];
}

- (void)dealloc
{
    self.joystickPortPeripherals = nil;
    self.joystickPort1Selection = nil;
    self.joystickPort2Selection = nil;
    
    self.machineConfigurations = nil;
    
    [keyCategories release];
    [joystickOneCategories release];
    [joystickTwoCategories release];
    
    [virtualEmulationSpeedRange release];
    
    [super dealloc];
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
    
    if (!outlineView)
        return nil; // FIXME: remove this after adding j2layout
    
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
    self.emulator.stretchHorizontally = YES;
    self.emulator.stretchVertically = NO;
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
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"SureYouWantToRestartTheMachine", nil)
                                     defaultButton:NSLocalizedString(@"No", nil)
                                   alternateButton:nil
                                       otherButton:NSLocalizedString(@"Yes", nil)
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
            
            cell.textField.stringValue = [self.emulator.keyboard inputNameForVirtualCode:virtualCode];
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
                srCell.recorderControl.allowedFlags = 1966080;
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
            [preferences setKeyboardLayout:layout];
        }
    }
}

@end
