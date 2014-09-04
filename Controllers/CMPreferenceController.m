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
#import "CMPreferenceController.h"

#import "CMAppDelegate.h"
#import "CMEmulatorController.h"
#import "CMConfigureJoystickController.h"

#import "CMPreferences.h"

#import "NSString+CMExtensions.h"

#import "MGScopeBar.h"
#import "SBJson.h"

#import "CMMSXJoystick.h"
#import "CMKeyboardInput.h"
#import "CMMachine.h"
#import "CMMixerChannel.h"

#import "CMCocoaInput.h"
#import "CMKeyCaptureView.h"
#import "CMHeaderRowCell.h"
#import "CMMachineSelectionCell.h"

#import "CMMachineInstallationOperation.h"

#include "InputEvent.h"
#include "JoystickPort.h"

#pragma mark - KeyCategory

@interface CMKeyCategory : NSObject
{
    NSString *_categoryName;
    NSString *_title;
    
    NSMutableArray *items;
}

@property (nonatomic, copy) NSString *categoryName;
@property (nonatomic, copy) NSString *title;

- (NSMutableArray *)items;
- (void)sortItems;

@end

@implementation CMKeyCategory

@synthesize categoryName = _categoryName;
@synthesize title = _title;

static NSArray *keysInOrderOfAppearance;

+ (void)initialize
{
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"MSXKeysInOrderOfAppearance"
                                                             ofType:@"plist"
                                                        inDirectory:@"Data"];
    
    keysInOrderOfAppearance = [[NSArray alloc] initWithContentsOfFile:resourcePath];
}

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
    [self setTitle:nil];
    [self setCategoryName:nil];
    
    [items release];
    
    [super dealloc];
}

- (void)sortItems
{
    NSArray *sortedItems = [items sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                            {
                                return [keysInOrderOfAppearance indexOfObject:a] - [keysInOrderOfAppearance indexOfObject:b];
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

#define SCOPEBAR_GROUP_MACHINE_STATUS 0
#define SCOPEBAR_GROUP_MACHINE_FAMILY 1

#define DOWNLOAD_TIMEOUT_SECONDS 10

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

- (void)performBlockOnMainThread:(void(^)(void))block;

- (void)requestMachineFeedUpdate;
- (BOOL)updateMachineFeed:(NSError **)error;
- (BOOL)isDownloadQueuedForMachine:(CMMachine *)machine;

- (NSArray *)machinesAvailableForDownload;
- (void)synchronizeMachineArrayController;
- (void)synchronizeSettings;
- (void)updateCurrentConfigurationInformation;
- (void)sizeWindowToTabContent:(NSString *)tabId;

- (void)configureJoypad:(NSInteger)joypadId;
- (void)resetPredicate;
- (void)clearPredicate;

@end

@implementation CMPreferenceController

@synthesize emulator = _emulator;
@synthesize machines = _machines;
@synthesize channels = _channels;
@synthesize machineNameFilter = _machineNameFilter;

#pragma mark - Init & Dealloc

- (id)initWithEmulator:(CMEmulatorController*)emulator
{
    if ((self = [super initWithWindowNibName:@"Preferences"]))
    {
        [self setEmulator:emulator];
        
        joystickConfigurator = nil;
        
        keyCategories = [[NSMutableArray alloc] init];
        joystickOneCategories = [[NSMutableArray alloc] init];
        joystickTwoCategories = [[NSMutableArray alloc] init];
        _machines = [[NSMutableArray alloc] init];
        
        // Set the virtual emulation speed range
        virtualEmulationSpeedRange = [[NSArray alloc] initWithObjects:@10, @100, @250, @500, @1000, nil];

        // Set up channels
        _channels = [[NSArray alloc] initWithObjects:
                     [CMMixerChannel mixerChannelNamed:CMLoc(@"PSG", "Audio Channel")
                                   enabledPropertyName:@"audioEnablePsg"
                                    volumePropertyName:@"audioVolumePsg"
                                   balancePropertyName:@"audioBalancePsg"],
                     [CMMixerChannel mixerChannelNamed:CMLoc(@"SCC", "Audio Channel")
                                   enabledPropertyName:@"audioEnableScc"
                                    volumePropertyName:@"audioVolumeScc"
                                   balancePropertyName:@"audioBalanceScc"],
                     [CMMixerChannel mixerChannelNamed:CMLoc(@"MSX Music", "Audio Channel")
                                   enabledPropertyName:@"audioEnableMsxMusic"
                                    volumePropertyName:@"audioVolumeMsxMusic"
                                   balancePropertyName:@"audioBalanceMsxMusic"],
                     [CMMixerChannel mixerChannelNamed:CMLoc(@"MSX Audio", "Audio Channel")
                                   enabledPropertyName:@"audioEnableMsxAudio"
                                    volumePropertyName:@"audioVolumeMsxAudio"
                                   balancePropertyName:@"audioBalanceMsxAudio"],
                     [CMMixerChannel mixerChannelNamed:CMLoc(@"Moonsound", "Audio Channel")
                                   enabledPropertyName:@"audioEnableMoonSound"
                                    volumePropertyName:@"audioVolumeMoonSound"
                                   balancePropertyName:@"audioBalanceMoonSound"],
                     [CMMixerChannel mixerChannelNamed:CMLoc(@"Keyboard", "Audio Channel")
                                   enabledPropertyName:@"audioEnableKeyboard"
                                    volumePropertyName:@"audioVolumeKeyboard"
                                   balancePropertyName:@"audioBalanceKeyboard"], nil];
        
        downloadQueue = [[NSOperationQueue alloc] init];
        [downloadQueue setMaxConcurrentOperationCount:1];
        
        jsonParser = [[SBJsonParser alloc] init];
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
                        scanlineSlider,
                        balanceSlider,
                        volumeSlider, nil];
    
    [sliders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSSlider *slider = (NSSlider*)obj;
        
        [slider setAction:@selector(sliderValueChanged:)];
        [slider setTarget:self];
    }];
    
    machineStatusFilter = CMMachineInstalled;
    machineFamilyFilter = 0;
    
    // Input devices devices
    [self initializeInputDeviceCategories:keyCategories
                               withLayout:[[self emulator] keyboardLayout]];
    [self initializeInputDeviceCategories:joystickOneCategories
                               withLayout:[[self emulator] joystickOneLayout]];
    [self initializeInputDeviceCategories:joystickTwoCategories
                               withLayout:[[self emulator] joystickTwoLayout]];
    
    // Scope Bar
    [keyboardScopeBar setSelected:YES forItem:@(CMMSXKeyStateDefault)  inGroup:SCOPEBAR_GROUP_SHIFTED];
    [keyboardScopeBar setSelected:YES forItem:[CMMSXKeyboard defaultLayoutName] inGroup:SCOPEBAR_GROUP_REGIONS];
    
    [self synchronizeSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedInstallStartedNotification:)
                                                 name:CMInstallStartedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedInstallCompletedNotification:)
                                                 name:CMInstallCompletedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedInstallErrorNotification:)
                                                 name:CMInstallErrorNotification
                                               object:nil];
    
    // Observe the machineNameFilter (bound to the machine search textbox)
    [self addObserver:self
           forKeyPath:@"machineNameFilter"
              options:0
              context:NULL];
    
    // Observe the active machine
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"machineConfiguration"
                                               options:0
                                               context:NULL];
    
    [machineScopeBar setSelected:YES forItem:@(machineFamilyFilter) inGroup:SCOPEBAR_GROUP_MACHINE_FAMILY];
    [machineScopeBar setSelected:YES forItem:@(machineStatusFilter) inGroup:SCOPEBAR_GROUP_MACHINE_STATUS];
    
    [self sizeWindowToTabContent:[[contentTabView selectedTabViewItem] identifier]];
    
    [keyboardLayoutEditor reloadData];
    [joystickOneLayoutEditor reloadData];
    [joystickTwoLayoutEditor reloadData];
    
    [keyboardLayoutEditor expandItem:nil expandChildren:YES];
    [joystickOneLayoutEditor expandItem:nil expandChildren:YES];
    [joystickTwoLayoutEditor expandItem:nil expandChildren:YES];
}

- (void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"machineNameFilter"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:@"machineConfiguration"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CMInstallStartedNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CMInstallCompletedNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CMInstallErrorNotification
                                                  object:nil];
    
    [downloadQueue release];
    [jsonParser release];
    
    [joystickConfigurator release];
    
    [keyCaptureView release];
    
    [_activeMachine release];
    [_machineNameFilter release];
    [_machines release];
    [_channels release];
    [keyCategories release];
    [joystickOneCategories release];
    [joystickTwoCategories release];
    
    [virtualEmulationSpeedRange release];
    
    [super dealloc];
}

#pragma mark - Private Methods

- (void)updateCurrentConfigurationInformation
{
    NSString *layoutName = [CMMSXKeyboard layoutNameOfMachineWithIdentifier:CMGetObjPref(@"machineConfiguration")];
    if (!layoutName)
        layoutName = [CMMSXKeyboard defaultLayoutName];
    
    [keyboardScopeBar setSelected:YES
                          forItem:layoutName
                          inGroup:SCOPEBAR_GROUP_REGIONS];
}

- (void)performBlockOnMainThread:(void(^)(void))block
{
    if (dispatch_get_current_queue() == dispatch_get_main_queue())
    {
        block();
    }
    else
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
    }
}

- (NSArray *)machinesAvailableForDownload
{
    NSDate *feedLastDownloaded = CMGetObjPref(@"machineFeedLastDownloaded");
    if (!feedLastDownloaded)
        feedLastDownloaded = [NSDate distantPast];
    
    NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
    [components setMinute:-CMGetIntPref(@"machineFeedExpirationInMinutes")];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *feedFreshnessThreshold = [cal dateByAddingComponents:components
                                                          toDate:[NSDate date]
                                                         options:0];
    
    NSArray *machineList = nil;
    NSData *machineListAsData = CMGetObjPref(@"machineList");
    
    if (machineListAsData)
    {
#if DEBUG
        NSLog(@"Have an existing machine list, downloaded %@", feedLastDownloaded);
#endif
        machineList = [NSKeyedUnarchiver unarchiveObjectWithData:machineListAsData];
    }
    
    if ([feedLastDownloaded isLessThan:feedFreshnessThreshold])
    {
#if DEBUG
        if (machineList)
            NSLog(@"Machine list expired (downloaded %@); requesting update", feedLastDownloaded);
        else
            NSLog(@"Machine list not found; requesting download");
#endif
        
        // We don't have any machine data (or it's expired). Refresh our list of
        // available machines
        
        [self requestMachineFeedUpdate];
    }
    
    return machineList;
}

- (void)requestMachineFeedUpdate
{
    NSOperation *downloadOp = [NSBlockOperation blockOperationWithBlock:^
                               {
                                   NSError *error = nil;
                                   BOOL success;
                                   
                                   @try
                                   {
                                       success = [self updateMachineFeed:&error];
                                   }
                                   @catch (NSException *e)
                                   {
                                       success = NO;
                                       error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                                                   code:CMErrorCritical
                                                               userInfo:[NSMutableDictionary dictionaryWithObject:CMLoc(@"Could not complete download - an unexpected error occurred.", @"")
                                                                                                           forKey:NSLocalizedDescriptionKey]];
                                   }
                                   
                                   if (success)
                                   {
                                       [self performBlockOnMainThread:^
                                        {
                                            [self synchronizeMachineArrayController];
                                        }];
                                   }
                                   
                                   if (!success && error)
                                   {
                                       // Prevent feed from being auto-loaded too soon
                                       CMSetObjPref(@"machineFeedLastDownloaded", [NSDate date]);
                                       
                                       [self performBlockOnMainThread:^
                                        {
                                            NSAlert *alert = [NSAlert alertWithMessageText:[error localizedDescription]
                                                                             defaultButton:CMLoc(@"OK", @"")
                                                                           alternateButton:nil
                                                                               otherButton:nil
                                                                 informativeTextWithFormat:@""];
                                            
                                            [alert beginSheetModalForWindow:[self window]
                                                              modalDelegate:self
                                                             didEndSelector:nil
                                                                contextInfo:nil];
                                        }];
                                   }
                               }];
    
    [downloadQueue addOperation:downloadOp];
}

- (BOOL)updateMachineFeed:(NSError **)error
{
    NSURL *feedUrl = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CMMachineFeedURL"]];
    
#if DEBUG
    NSLog(@"Downloading feed from %@...", feedUrl);
#endif
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:feedUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:DOWNLOAD_TIMEOUT_SECONDS];
    
    [request setHTTPMethod:@"GET"];
    
    NSURLResponse *response = nil;
    NSError *netError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&netError];
    
    if (!data)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorDownloading
                                     userInfo:[NSMutableDictionary dictionaryWithObject:CMLoc(@"An error occurred while attempting to download available machines.", @"")
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
#if DEBUG
    NSLog(@"done. Parsing JSON...");
#endif
    
    NSDictionary *dict = [jsonParser objectWithData:data];
    
    if (!dict)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorParsingJson
                                     userInfo:[NSMutableDictionary dictionaryWithObject:CMLoc(@"An error occurred while reading the list of downloadable machines.", @"")
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
#if DEBUG
    NSLog(@"done. Creating machines...");
#endif
    
    NSURL *downloadRoot = [NSURL URLWithString:[dict objectForKey:@"downloadRoot"]];
    NSArray *machinesJson = [dict objectForKey:@"machines"];
    NSMutableArray *remoteMachineList = [NSMutableArray array];
    
    NSDate *lastModified = [NSDate dateWithNaturalLanguageString:[dict objectForKey:@"lastModified"]];
    
    if (![CMGetObjPref(@"machineFeedLastModified") isEqualToDate:lastModified])
    {
        [machinesJson enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             CMMachine *machine = [[[CMMachine alloc] initWithPath:[obj objectForKey:@"id"]
                                                         machineId:[obj objectForKey:@"id"]
                                                              name:[obj objectForKey:@"name"]
                                                        systemName:[obj objectForKey:@"system"]] autorelease];
             
             [machine setStatus:CMMachineDownloadable];
             [machine setChecksum:[obj objectForKey:@"md5"]];
             [machine setMachineUrl:[downloadRoot URLByAppendingPathComponent:[obj objectForKey:@"file"]]];
             
             [remoteMachineList addObject:machine];
         }];
        
#if DEBUG
        NSLog(@"All done.");
#endif
    
        CMSetObjPref(@"machineList",
                     [NSKeyedArchiver archivedDataWithRootObject:remoteMachineList]);
        CMSetObjPref(@"machineFeedLastModified", lastModified);
    }
#if DEBUG
    else
    {
        NSLog(@"Will not update machine list - feed not modified (have: %@; received: %@)",
              CMGetObjPref(@"machineFeedLastModified"), lastModified);
    }
#endif
    
    CMSetObjPref(@"machineFeedLastDownloaded", [NSDate date]);
    
    return YES;
}

- (void)synchronizeMachineArrayController
{
#ifdef DEBUG
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"machinesArrayController: synchronizing...");
#endif
    // Load downloadable machines
    NSMutableSet *all = [NSMutableSet set];
    [[self machinesAvailableForDownload] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [obj setStatus:CMMachineDownloadable];
        [all addObject:obj];
    }];
    
    NSString *activeMachine = CMGetObjPref(@"machineConfiguration");
    
    // Load installed machines
    NSMutableSet *installed = [NSMutableSet set];
    NSArray *foundNames = [CMEmulatorController machineConfigurations];
    [foundNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMMachine *machine = [CMMachine machineWithPath:obj];
         [machine setStatus:CMMachineInstalled];
         
         if ([[machine machineId] isEqualToString:activeMachine])
         {
             if (![machine active])
                 [machine setActive:YES];
             [self setActiveMachine:machine];
         }
         
         [installed addObject:machine];
     }];

    // From the downloaded list, remove all that are already installed
    [all minusSet:installed];
    // Add the remaining
    [all unionSet:installed];

    // Machines already in the controller
    NSSet *currentlyListed = [NSSet setWithArray:_machines];
    
    // Machines missing from the controller (newly added)
    NSMutableSet *missingInController = [NSMutableSet setWithSet:all];
    [missingInController minusSet:currentlyListed];
    
    // Machines in the controller, but no longer existing
    NSMutableSet *expiredInController = [NSMutableSet setWithSet:currentlyListed];
    [expiredInController minusSet:all];
    
    if ([missingInController count] > 0 || [expiredInController count] > 0)
    {
        // Clear filtering - otherwise [machinesArrayController addObjects:]
        // will fail
        [self clearPredicate];
    }

    // Add new machines to controller
    [machinesArrayController addObjects:[missingInController allObjects]];
    // Remove expired machines from controller
    [machinesArrayController removeObjects:[expiredInController allObjects]];
    
    // Synchronize remaining machines
    __block NSInteger machinesUpdated = 0;
    [[machinesArrayController content] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMMachine *inController = obj;
        CMMachine *updated = [all member:inController];
        
        if ([inController status] != [updated status]
            && [inController status] != CMMachineDownloading)
        {
            // Status has changed for one of the machines
            // Update the item in the controller
            
            [inController setName:[updated name]];
            [inController setPath:[updated path]];
            [inController setMachineId:[updated machineId]];
            [inController setMachineUrl:[updated machineUrl]];
            [inController setChecksum:[updated checksum]];
            [inController setSystem:[updated system]];
            [inController setStatus:[updated status]];
            
            machinesUpdated++;
        }
    }];
    
    // If anything has changed, rearrange the objects
    if (machinesUpdated > 0)
        [machinesArrayController rearrangeObjects];
    
#ifdef DEBUG
    NSLog(@"machinesArrayController: added %ld, removed %ld, updated %ld (took %.02fms)",
          [missingInController count], [expiredInController count],
          machinesUpdated,
          [NSDate timeIntervalSinceReferenceDate] - startTime);
#endif
}

- (void)synchronizeSettings
{
    [self synchronizeMachineArrayController];
    
    // Update emulation speed
    [emulationSpeedSlider setDoubleValue:[self physicalPositionOfSlider:emulationSpeedSlider
                                                            fromVirtual:CMGetIntPref(@"emulationSpeedPercentage")
                                                             usingTable:virtualEmulationSpeedRange]];
}

- (void)initializeInputDeviceCategories:(NSMutableArray *)categoryArray
                             withLayout:(CMInputDeviceLayout *)layout
{
    NSMutableDictionary *categoryToKeyMap = [NSMutableDictionary dictionary];
    NSMutableArray *unsortedCategories = [NSMutableArray array];
    
    [layout enumerateMappingsUsingBlock:^(NSUInteger virtualCode, CMInputMethod *inputMethod, BOOL *stop)
    {
        NSString *categoryName = [CMMSXKeyboard categoryNameForVirtualCode:virtualCode];
        CMKeyCategory *kc = [categoryToKeyMap objectForKey:categoryName];
        
        if (!kc)
        {
            kc = [[[CMKeyCategory alloc] init] autorelease];
            [categoryToKeyMap setObject:kc forKey:categoryName];
            
            [kc setCategoryName:categoryName];
            [kc setTitle:[CMMSXKeyboard categoryLabelForVirtualCode:virtualCode]];
            
            [unsortedCategories addObject:kc];
        }
        
        [kc.items addObject:[NSNumber numberWithInteger:virtualCode]];
    }];
    
    [unsortedCategories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [obj sortItems];
    }];
    
    NSArray *categoriesInSortedOrder = @[@"TypewriterKeys", @"SpecialKeys", @"ModifierKeys", @"FunctionKeys", @"CursorKeys", @"NumericPad", @"Joystick" ];
    NSArray *sortedCategories = [unsortedCategories sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                {
                                    int orderIndexA = [categoriesInSortedOrder indexOfObject:[a categoryName]];
                                    int orderIndexB = [categoriesInSortedOrder indexOfObject:[b categoryName]];
                                    
                                    return orderIndexA - orderIndexB;
                                }];
    
    [categoryArray removeAllObjects];
    [categoryArray addObjectsFromArray:sortedCategories];
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

- (BOOL)isDownloadQueuedForMachine:(CMMachine *)machine
{
    __block BOOL machineFound = NO;
    
    [[downloadQueue operations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        if ([obj isKindOfClass:[CMMachineInstallationOperation class]])
        {
            CMMachineInstallationOperation *installOp = (CMMachineInstallationOperation *)obj;
            if ([[installOp machine] isEqual:machine])
            {
                machineFound = YES;
                *stop = YES;
            }
        }
    }];
    
    return machineFound;
}

- (void)sizeWindowToTabContent:(NSString *)tabId
{
    NSRect contentFrame = [[self window] contentRectForFrameRect:[[self window] frame]];
    CGFloat newHeight = contentFrame.size.height;
    
    if ([tabId isEqual:@"general"])
        newHeight = 200;
    else if ([tabId isEqual:@"system"])
        newHeight = 500;
    else if ([tabId isEqual:@"video"])
        newHeight = 400;
    else if ([tabId isEqual:@"audio"])
        newHeight = 400;
    else if ([tabId isEqual:@"keyboard"])
        newHeight = 500;
    else if ([tabId isEqual:@"joystick"])
        newHeight = 460;
    
    NSRect newContentFrame = NSMakeRect(contentFrame.origin.x,
                                        contentFrame.origin.y,
                                        contentFrame.size.width,
                                        newHeight);
    
    NSRect newWindowFrame = [[self window] frameRectForContentRect:newContentFrame];
    newWindowFrame.origin.y -= (newWindowFrame.size.height - [[self window] frame].size.height);
    
    [[self window] setFrame:newWindowFrame
                    display:YES
                    animate:YES];
}

#pragma mark - Actions

- (void)installMachineConfiguration:(id)sender
{
    CMMachine *selection = [[machinesArrayController selectedObjects] firstObject];
    if ([selection status] == CMMachineDownloadable)
    {
        CMMachineInstallationOperation *installOp = [CMMachineInstallationOperation installationOperationWithMachine:selection];
        [selection setStatus:CMMachineDownloading];
        [downloadQueue addOperation:installOp];
    }
}

- (void)removeMachineConfiguration:(id)sender
{
    CMMachine *selection = [[machinesArrayController selectedObjects] firstObject];
    if ([selection status] == CMMachineInstalled)
    {
        NSString *message = [NSString stringWithFormat:CMLoc(@"Are you sure you want to remove \"%1$@\"?", @"Remove machine configuration prompt"), [selection name]];
        NSAlert *alert = [NSAlert alertWithMessageText:message
                                         defaultButton:CMLoc(@"No", @"")
                                       alternateButton:nil
                                           otherButton:CMLoc(@"Yes", @"")
                             informativeTextWithFormat:@""];
        
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:(void *)ALERT_REMOVE_SYSTEM];
    }
}

- (void)configureJoypadOne:(id)sender
{
    [self configureJoypad:[[[self emulator] input] joypadOneId]];
}

- (void)configureJoypadTwo:(id)sender
{
    [self configureJoypad:[[[self emulator] input] joypadTwoId]];
}

- (void)configureJoypad:(NSInteger)joypadId
{
    if (!joystickConfigurator)
    {
        joystickConfigurator = [[CMConfigureJoystickController alloc] init];
        [joystickConfigurator setDelegate:self];
    }
    
    if (joypadId != 0)
    {
        [joystickConfigurator showWindow:self];
        [joystickConfigurator restartConfiguration:joypadId];
    }
    else
    {
        NSAlert *alert = [NSAlert alertWithMessageText:CMLoc(@"No devices are currently connected on this port", @"")
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

- (void)tabChanged:(id)sender
{
    NSToolbarItem *selectedItem = (NSToolbarItem *)sender;
    NSString *tabIdentifier = [selectedItem itemIdentifier];
    
    [toolbar setSelectedItemIdentifier:tabIdentifier];
    CMSetObjPref(@"selectedPreferencesTab", tabIdentifier);
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
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundleResourcePath];
    
    CMSetIntPref(@"videoBrightness", [[defaults objectForKey:@"videoBrightness"] integerValue]);
    CMSetIntPref(@"videoContrast", [[defaults objectForKey:@"videoContrast"] integerValue]);
    CMSetIntPref(@"videoSaturation", [[defaults objectForKey:@"videoSaturation"] integerValue]);
    CMSetIntPref(@"videoGamma", [[defaults objectForKey:@"videoGamma"] integerValue]);
    CMSetIntPref(@"videoRfModulation", [[defaults objectForKey:@"videoRfModulation"] integerValue]);
    CMSetIntPref(@"videoScanlineAmount", [[defaults objectForKey:@"videoScanlineAmount"] integerValue]);
    CMSetIntPref(@"videoSignalMode", [[defaults objectForKey:@"videoSignalMode"] integerValue]);
    CMSetIntPref(@"videoColorMode", [[defaults objectForKey:@"videoColorMode"] integerValue]);
    
    CMSetBoolPref(@"videoEnableDeInterlacing", [[defaults objectForKey:@"videoEnableDeInterlacing"] boolValue]);
}

- (void)revertAudioClicked:(id)sender
{
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundleResourcePath];
    
    CMSetIntPref(@"audioEnablePsg", [[defaults objectForKey:@"audioEnablePsg"] boolValue]);
    CMSetIntPref(@"audioVolumePsg", [[defaults objectForKey:@"audioVolumePsg"] integerValue]);
    CMSetIntPref(@"audioBalancePsg", [[defaults objectForKey:@"audioBalancePsg"] integerValue]);
    CMSetIntPref(@"audioEnableScc", [[defaults objectForKey:@"audioEnableScc"] boolValue]);
    CMSetIntPref(@"audioVolumeScc", [[defaults objectForKey:@"audioVolumeScc"] integerValue]);
    CMSetIntPref(@"audioBalanceScc", [[defaults objectForKey:@"audioBalanceScc"] integerValue]);
    CMSetIntPref(@"audioEnableMsxMusic", [[defaults objectForKey:@"audioEnableMsxMusic"] boolValue]);
    CMSetIntPref(@"audioVolumeMsxMusic", [[defaults objectForKey:@"audioVolumeMsxMusic"] integerValue]);
    CMSetIntPref(@"audioBalanceMsxMusic", [[defaults objectForKey:@"audioBalanceMsxMusic"] integerValue]);
    CMSetIntPref(@"audioEnableMsxAudio", [[defaults objectForKey:@"audioEnableMsxAudio"] boolValue]);
    CMSetIntPref(@"audioVolumeMsxAudio", [[defaults objectForKey:@"audioVolumeMsxAudio"] integerValue]);
    CMSetIntPref(@"audioBalanceMsxAudio", [[defaults objectForKey:@"audioBalanceMsxAudio"] integerValue]);
    CMSetIntPref(@"audioEnableKeyboard", [[defaults objectForKey:@"audioEnableKeyboard"] boolValue]);
    CMSetIntPref(@"audioVolumeKeyboard", [[defaults objectForKey:@"audioVolumeKeyboard"] integerValue]);
    CMSetIntPref(@"audioBalanceKeyboard", [[defaults objectForKey:@"audioBalanceKeyboard"] integerValue]);
    CMSetIntPref(@"audioEnableMoonSound", [[defaults objectForKey:@"audioEnableMoonSound"] boolValue]);
    CMSetIntPref(@"audioVolumeMoonSound", [[defaults objectForKey:@"audioVolumeMoonSound"] integerValue]);
    CMSetIntPref(@"audioBalanceMoonSound", [[defaults objectForKey:@"audioBalanceMoonSound"] integerValue]);
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

- (void)refreshMachineList:(id)sender
{
    [self requestMachineFeedUpdate];
}

- (void)alertDidEnd:(NSAlert *)alert
         returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo
{
    if ((int)contextInfo == ALERT_RESTART_SYSTEM)
    {
        if (returnCode == NSAlertOtherReturn)
            [[self emulator] performColdReboot];
    }
    else if ((int)contextInfo == ALERT_REMOVE_SYSTEM)
    {
        if (returnCode == NSAlertOtherReturn)
        {
            CMMachine *selectedMachine = [[machinesArrayController selectedObjects] firstObject];
            if ([selectedMachine status] == CMMachineInstalled)
                [CMEmulatorController removeMachineConfiguration:[selectedMachine path]];
        }
    }
}

- (void)performColdRebootClicked:(id)sender
{
    NSAlert *alert = [NSAlert alertWithMessageText:CMLoc(@"Restart the system? You will lose all changes.", @"")
                                     defaultButton:CMLoc(@"No", @"")
                                   alternateButton:nil
                                       otherButton:CMLoc(@"Yes", @"")
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
    CMMachine *selection = [[machinesArrayController selectedObjects] firstObject];
    if ([selection status] == CMMachineInstalled)
    {
        NSString *path = [CMEmulatorController pathForMachineConfigurationNamed:[selection machineId]];
        NSArray *urls = [NSArray arrayWithObject:[NSURL fileURLWithPath:path]];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
    }
    else
    {
        NSString *path = [[CMPreferences preferences] machineDirectory];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
    }
}

#pragma mark - KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"machineNameFilter"])
        [self resetPredicate];
    else if ([keyPath isEqualToString:@"machineConfiguration"])
    {
        // Active machine has changed. Go through the list of machines and
        // deactivate all except the one active
        
        NSString *active = CMGetObjPref(@"machineConfiguration");
        [_machines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            BOOL matchesActive = [[obj machineId] isEqualToString:active];
            if (!matchesActive && [obj active])
                [obj setActive:NO];
            else if (matchesActive)
            {
                [self setActiveMachine:obj];
                if (![obj active])
                    [obj setActive:YES];
            }
        }];
    }
}

#pragma mark - NSWindowController

- (void)windowDidLoad
{
    // Select first tab
    [toolbar setSelectedItemIdentifier:CMGetObjPref(@"selectedPreferencesTab")];
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

    // Start listening for key events
    [[CMKeyboardManager sharedInstance] addObserver:self];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    // Stop listening for key events
    [[CMKeyboardManager sharedInstance] removeObserver:self];
}

#pragma mark - CMKeyboardEventDelegate

- (void)keyStateChanged:(CMKeyEventData *)event isDown:(BOOL)isDown
{
    if ([event hasKeyCodeEquivalent])
    {
        // Key with a valid keyCode
        if ([[self window] firstResponder] == keyCaptureView)
        {
            // keyCaptureView is in focus
            BOOL isReturn = [event keyCode] == 0x24 || [event keyCode] == 0x4c;
            if (isReturn || !isDown)
            {
                // A key was released while the keyCaptureView has focus
                [keyCaptureView captureKeyCode:[event keyCode]];
            }
        }
    }
}

#pragma mark - NSNotifications

- (void)receivedInstallStartedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    CMMachine *machine = [[notification userInfo] objectForKey:@"machine"];
    NSLog(@"DownloadStarted: %@", [machine name]);
#endif
}

- (void)receivedInstallCompletedNotification:(NSNotification *)notification
{
    CMMachine *machine = [[notification userInfo] objectForKey:@"machine"];
    [machine setStatus:CMMachineInstalled];

#ifdef DEBUG
    NSLog(@"DownloadCompleted: %@", [machine name]);
#endif
}

- (void)receivedInstallErrorNotification:(NSNotification *)notification
{
    NSError *error = [[notification userInfo] objectForKey:@"error"];
    CMMachine *machine = [[notification userInfo] objectForKey:@"machine"];
    
#ifdef DEBUG
    NSLog(@"DownloadError: %@ (%@)", [machine name], error);
#endif
    
    [machine setStatus:CMMachineDownloadable];
    
    [self performBlockOnMainThread:^
     {
         NSAlert *alert = [NSAlert alertWithMessageText:[error localizedDescription]
                                          defaultButton:CMLoc(@"OK", @"")
                                        alternateButton:nil
                                            otherButton:nil
                              informativeTextWithFormat:@""];
         
         [alert beginSheetModalForWindow:[self window]
                           modalDelegate:self
                          didEndSelector:nil
                             contextInfo:nil];
     }];
}

#pragma mark - NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self sizeWindowToTabContent:[tabViewItem identifier]];
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
        if ([[tableColumn identifier] isEqualToString:@"CMKeyLabelColumn"])
            return [((CMKeyCategory *)item) title];
    }
    else if ([item isKindOfClass:[NSNumber class]])
    {
        CMInputDeviceLayout *layout = [self inputDeviceLayoutFromOutlineView:outlineView];
        NSUInteger virtualCode = [(NSNumber *)item integerValue];
        
        if ([[tableColumn identifier] isEqualToString:@"CMKeyLabelColumn"])
        {
            if (outlineView != keyboardLayoutEditor)
            {
                CMMSXJoystick *joystick = [CMMSXJoystick joystickWithLayout:CMMSXJoystickTwoButton];
                if (joystick)
                {
                    NSString *label = [joystick presentationLabelForVirtualCode:virtualCode];
                    return label ? label : CMLoc(@"Unavailable", @"");
                }
            }
            else
            {
                CMMSXKeyboard *keyboard = [CMMSXKeyboard keyboardWithLayoutName:selectedKeyboardRegion];
                if (keyboard)
                {
                    NSString *label = [keyboard presentationLabelForVirtualCode:virtualCode
                                                                       keyState:selectedKeyboardShiftState];
                    return label ? label : CMLoc(@"Unavailable", @"");
                }
            }
            
            return nil;
        }
        else if ([[tableColumn identifier] isEqualToString:@"CMKeyAssignmentColumn"])
        {
            CMKeyboardInput *keyInput = (CMKeyboardInput *)[layout inputMethodForVirtualCode:virtualCode];
            
            return [CMKeyCaptureView descriptionForKeyCode:@([keyInput keyCode])];
        }
    }
    
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[NSNumber class]]
        && [[tableColumn identifier] isEqualToString:@"CMKeyAssignmentColumn"])
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

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (outlineView == keyboardLayoutEditor)
    {
        if ([[tableColumn identifier] isEqualToString:@"CMKeyLabelColumn"] ||
            [[tableColumn identifier] isEqualToString:@"CMKeyAssignmentColumn"])
        {
            CMMSXKeyboard *keyboard = [CMMSXKeyboard keyboardWithLayoutName:selectedKeyboardRegion];
            BOOL isCellEditable = NO;
            
            if (keyboard)
                isCellEditable = [keyboard supportsVirtualCode:[(NSNumber *)item integerValue]
                                                      forState:selectedKeyboardShiftState];
            
            [cell setEnabled:isCellEditable];
        }
    }
}

#pragma mark MGScopeBarDelegate

- (NSView *)accessoryViewForScopeBar:(MGScopeBar *)theScopeBar
{
    if (theScopeBar == machineScopeBar)
        return machineSearchField;
    
    return nil;
}

- (int)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar
{
    if (theScopeBar == keyboardScopeBar)
        return 2;
    
    if (theScopeBar == machineScopeBar)
        return 2;
    
    return 1;
}

- (NSArray *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(int)groupNumber
{
    if (theScopeBar == keyboardScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_SHIFTED)
        {
            return [NSArray arrayWithObjects:
                    @(CMMSXKeyStateDefault),
                    @(CMMSXKeyStateShift), nil];
        }
        else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
        {
            return [CMMSXKeyboard availableLayoutNames];
        }
    }
    else if (theScopeBar == machineScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_MACHINE_FAMILY)
            return [NSArray arrayWithObjects:
                    @0,
                    @CMMsx,
                    @CMMsx2,
                    @CMMsx2Plus,
                    @CMMsxTurboR, nil];
        else if (groupNumber == SCOPEBAR_GROUP_MACHINE_STATUS)
            return [NSArray arrayWithObjects:
                    @0,
                    @CMMachineInstalled,
                    @CMMachineDownloadable, nil];
    }
    
    return nil;
}

- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(int)groupNumber
{
    if (theScopeBar == keyboardScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_REGIONS)
            return CMLoc(@"Layout", @"");
    }
    
    return nil;
}

- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(int)groupNumber
{
    return MGRadioSelectionMode;
}

- (NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(id)identifier inGroup:(int)groupNumber
{
    if (theScopeBar == keyboardScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_SHIFTED)
        {
            CMMSXKeyState shiftState = [identifier integerValue];
            
            if (shiftState == CMMSXKeyStateDefault)
                return CMLoc(@"Normal", @"Key state (no modifiers)");
            if (shiftState == CMMSXKeyStateShift)
                return CMLoc(@"Shifted", @"Key state (shift held)");
        }
        else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
        {
            return [[CMMSXKeyboard keyboardWithLayoutName:identifier] label];
        }
    }
    else if (theScopeBar == machineScopeBar)
    {
        NSInteger ident = [identifier integerValue];
        
        if (groupNumber == SCOPEBAR_GROUP_MACHINE_FAMILY)
        {
            if (ident == CMMsx)
                return CMLoc(@"MSX", @"MSX System");
            else if (ident == CMMsx2)
                return CMLoc(@"MSX 2", @"MSX System");
            else if (ident == CMMsx2Plus)
                return CMLoc(@"MSX 2+", @"MSX System");
            else if (ident == CMMsxTurboR)
                return CMLoc(@"Turbo R", @"MSX System");
            else if (ident == 0)
                return CMLoc(@"All", @"");
        }
        else if (groupNumber == SCOPEBAR_GROUP_MACHINE_STATUS)
        {
            if (ident == CMMachineDownloadable)
                return CMLoc(@"Not installed", @"System availability");
            else if (ident == CMMachineInstalled)
                return CMLoc(@"Installed", @"System availability");
            else if (ident == 0)
                return CMLoc(@"All", @"");
        }
    }
    
    return nil;
}

- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected forItem:(id)identifier inGroup:(int)groupNumber
{
    if (theScopeBar == keyboardScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_SHIFTED)
        {
            NSNumber *shiftState = identifier;
            selectedKeyboardShiftState = [shiftState integerValue];
            
            [keyboardLayoutEditor reloadData];
        }
        else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
        {
            selectedKeyboardRegion = identifier;
            
            [keyboardLayoutEditor reloadData];
        }
    }
    else if (theScopeBar == machineScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_MACHINE_FAMILY)
            machineFamilyFilter = [identifier integerValue];
        else if (groupNumber == SCOPEBAR_GROUP_MACHINE_STATUS)
            machineStatusFilter = [identifier integerValue];

        [self resetPredicate];
    }
}

- (void)clearPredicate
{
    [machineScopeBar setSelected:YES forItem:@0 inGroup:SCOPEBAR_GROUP_MACHINE_FAMILY];
    [machineScopeBar setSelected:YES forItem:@0 inGroup:SCOPEBAR_GROUP_MACHINE_STATUS];
    [self setMachineNameFilter:@""];
}

- (void)resetPredicate
{
    NSMutableArray *predicates = [NSMutableArray array];
    if (machineFamilyFilter != 0)
        [predicates addObject:[NSPredicate predicateWithFormat:@"system == %d",
                           machineFamilyFilter]];
    if (machineStatusFilter != 0)
        [predicates addObject:[NSPredicate predicateWithFormat:@"status == %d",
                               machineStatusFilter]];
    NSString *system = [_machineNameFilter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([system length] > 0)
        [predicates addObject:[NSPredicate predicateWithFormat:@"name contains[cd] %@",
                         system]];

    [machinesArrayController setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
}

#pragma mark - CMGamepadConfigurationDelegate

- (void)gamepadDidConfigure:(CMGamepad *)gamepad configuration:(CMGamepadConfiguration *)configuration
{
    NSDictionary *currentConfigurations = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"joypadConfigurations"];
    NSMutableDictionary *newConfigurations = [NSMutableDictionary dictionary];
    
    if (currentConfigurations)
        [newConfigurations addEntriesFromDictionary:currentConfigurations];
    
    [newConfigurations setObject:[NSKeyedArchiver archivedDataWithRootObject:configuration]
                          forKey:[gamepad vendorProductString]];
    
    [[NSUserDefaults standardUserDefaults] setObject:newConfigurations
                                              forKey:@"joypadConfigurations"];
}

@end
