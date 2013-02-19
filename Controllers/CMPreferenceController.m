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

#import "CMAppDelegate.h"
#import "CMEmulatorController.h"
#import "CMCocoaJoystick.h"
#import "CMPreferences.h"
#import "NSString+CMExtensions.h"


#import "MGScopeBar.h"
#import "SBJson.h"

#import "CMKeyboardInput.h"
#import "CMMachine.h"

#import "CMKeyCaptureView.h"
#import "CMHeaderRowCell.h"

#include "InputEvent.h"
#include "JoystickPort.h"

#pragma mark - KeyCategory

#define CMShowInstalledMachines 1
#define CMShowAvailableMachines 2
#define CMShowAllMachines       (CMShowInstalledMachines | CMShowAvailableMachines)

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

#define DOWNLOAD_TIMEOUT_SECONDS 10

#define CMErrorDownloading    100
#define CMErrorWriting        101
#define CMErrorExecutingUnzip 102
#define CMErrorUnzipping      103
#define CMErrorDeleting       104
#define CMErrorVerifyingHash  105
#define CMErrorParsingJson    106
#define CMErrorCritical       107

#define CMInstallStartedNotification   @"com.akop.CocoaMSX.InstallStarted"
#define CMInstallCompletedNotification @"com.akop.CocoaMSX.InstallCompleted"
#define CMInstallErrorNotification     @"com.akop.CocoaMSX.InstallError"

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
- (void)startBackgroundDownloadOfMachine:(CMMachine *)machine;
- (BOOL)downloadAndInstallMachine:(CMMachine *)machine error:(NSError **)error;

- (NSArray *)machinesAvailableForDownload;
- (void)synchronizeMachines;
- (void)synchronizeSettings;
- (CMMachine *)machineWithId:(NSString *)machineId;
- (CMMachine *)selectedMachine;
- (NSArray *)machinesCurrentlyVisible;
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
        allMachines = [[NSMutableArray alloc] init];
        installedMachines = [[NSMutableArray alloc] init];
        availableMachines = [[NSMutableArray alloc] init];
        remoteMachines = [[NSMutableArray alloc] init];
        
        // Set the virtual emulation speed range
        virtualEmulationSpeedRange = [[NSArray alloc] initWithObjects:@10, @100, @250, @500, @1000, nil];
        
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
    NSArray *sliders = [NSArray arrayWithObjects:brightnessSlider,
                        contrastSlider, saturationSlider, gammaSlider,
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
    [keyboardScopeBar setSelected:YES forItem:@CMKeyShiftStateNormal inGroup:SCOPEBAR_GROUP_SHIFTED];
    [keyboardScopeBar setSelected:YES forItem:@CMKeyLayoutEuropean inGroup:SCOPEBAR_GROUP_REGIONS];
    
    [self synchronizeSettings];
    
    machineDisplayMode = CMGetIntPref(@"machineDisplayMode");
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"machineDisplayMode"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
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
    
    [machineScopeBar setSelected:YES forItem:@(machineDisplayMode) inGroup:0];
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:@"machineDisplayMode"];
    
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
    
    self.joystickPortPeripherals = nil;
    self.joystickPort1Selection = nil;
    self.joystickPort2Selection = nil;
    
    [keyCaptureView release];
    
    [keyCategories release];
    [joystickOneCategories release];
    [joystickTwoCategories release];
    [allMachines release];
    [installedMachines release];
    [availableMachines release];
    [remoteMachines release];
    
    [virtualEmulationSpeedRange release];
    
    [super dealloc];
}

#pragma mark - Private Methods

- (NSArray *)machinesCurrentlyVisible
{
    if (machineDisplayMode == CMShowAvailableMachines)
        return availableMachines;
    else if (machineDisplayMode == CMShowInstalledMachines)
        return installedMachines;
    else
        return allMachines;
}

- (CMMachine *)machineWithId:(NSString *)machineId
{
    __block CMMachine *found = nil;
    
    [allMachines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        if ([[obj machineId] isEqualToString:machineId])
        {
            found = obj;
            *stop = YES;
        }
    }];
    
    return found;
}

- (void)updateCurrentConfigurationInformation
{
    CMMachine *selected = [self machineWithId:CMGetObjPref(@"machineConfiguration")];
    if (selected)
        [activeSystemTextView setStringValue:[NSString stringWithFormat:CMLoc(@"YouHaveSelectedSystem_f"),
                                              [selected name], [selected systemName]]];
    else
        [activeSystemTextView setStringValue:CMLoc(@"YouHaveNotSelectedAnySystem")];
    
    [keyboardScopeBar setSelected:YES
                          forItem:@([CMCocoaKeyboard layoutIdForMachineIdentifier:[selected machineId]])
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
    NSDate *feedLastLoaded = CMGetObjPref(@"machineFeedLastLoaded");
    if (!feedLastLoaded)
        feedLastLoaded = [NSDate distantPast];
    
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
        NSLog(@"Have an existing machine list, updated %@", feedLastLoaded);
#endif
        machineList = [NSKeyedUnarchiver unarchiveObjectWithData:machineListAsData];
    }
    
    if ([feedLastLoaded isLessThan:feedFreshnessThreshold])
    {
#if DEBUG
        if (machineList)
            NSLog(@"Machine list expired (loaded %@); requesting update", feedLastLoaded);
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
                                                               userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorDownloadCritical"
                                                                                                           forKey:NSLocalizedDescriptionKey]];
                                   }
                                   
                                   if (success)
                                   {
                                       [self performBlockOnMainThread:^
                                        {
                                            [self synchronizeMachines];
                                        }];
                                   }
                                   
                                   if (!success && error)
                                   {
                                       [self performBlockOnMainThread:^
                                        {
                                            NSAlert *alert = [NSAlert alertWithMessageText:CMLoc([error localizedDescription])
                                                                             defaultButton:CMLoc(@"OK")
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
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorDownloadingMachineFeed"
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
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorParsingMachineFeed"
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
    
    [machinesJson enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CMMachine *machine = [[[CMMachine alloc] initWithPath:[obj objectForKey:@"id"]
                                                     machineId:[obj objectForKey:@"id"]
                                                          name:[obj objectForKey:@"name"]
                                                    systemName:[obj objectForKey:@"system"]] autorelease];
         
         [machine setInstalled:NO];
         [machine setMachineUrl:[downloadRoot URLByAppendingPathComponent:[obj objectForKey:@"file"]]];
         
         [remoteMachineList addObject:machine];
     }];
    
#if DEBUG
    NSLog(@"All done.");
#endif
    
    CMSetObjPref(@"machineList",
                 [NSKeyedArchiver archivedDataWithRootObject:remoteMachineList]);
    CMSetObjPref(@"machineFeedLastLoaded", [NSDate date]);
    
    return YES;
}

- (BOOL)downloadAndInstallMachine:(CMMachine *)machine
                            error:(NSError **)error
{
    if ([machine installed] || ![machine machineUrl])
        return NO;
    
//    NSLog(@"Sleeping");
//    [NSThread sleepForTimeInterval:5];
    
#ifdef DEBUG
    NSLog(@"Downloading from %@...", [machine machineUrl]);
#endif
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[machine machineUrl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:DOWNLOAD_TIMEOUT_SECONDS];
    
    [request setHTTPMethod:@"GET"];
    
    NSURLResponse *response = nil;
    NSError *netError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&netError];
    
    if (netError)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorDownloading
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorDownloadingMachine"
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
    NSString *downloadPath = [machine downloadPath];
    
#ifdef DEBUG
    NSLog(@"done. Writing to %@...", downloadPath);
#endif
    
    if (![data writeToFile:downloadPath atomically:NO])
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorWriting
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorWritingMachine"
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
#ifdef DEBUG
    NSLog(@"done. Decompressing...");
#endif
    
    NSTask *unzipTask = [[[NSTask alloc] init] autorelease];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setCurrentDirectoryPath:[downloadPath stringByDeletingLastPathComponent]];
    [unzipTask setArguments:[NSArray arrayWithObjects:@"-u", @"-o", downloadPath, nil]];
    
    @try
    {
        [unzipTask launch];
    }
    @catch (NSException *exception)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorExecutingUnzip
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorExecutingUnzip"
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
    [unzipTask waitUntilExit];
    if ([unzipTask terminationStatus] != 0)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorUnzipping
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorUnzippingMachine"
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
#ifdef DEBUG
    NSLog(@"done. Deleting %@...", downloadPath);
#endif
    
    NSError *deleteError = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:downloadPath error:&deleteError])
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorDeleting
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorDeletingMachine"
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return YES; // No biggie
    }
    
#ifdef DEBUG
    NSLog(@"All done");
#endif
    
    return YES;
}

- (void)startBackgroundDownloadOfMachine:(CMMachine *)machine
{
    NSOperation *downloadOp = [NSBlockOperation blockOperationWithBlock:^
    {
        NSError *error = nil;
        BOOL success = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CMInstallStartedNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:machine
                                                                                               forKey:@"machine"]];
        
        @try
        {
            success = [self downloadAndInstallMachine:machine error:&error];
        }
        @catch (NSException *e)
        {
            success = NO;
            error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                        code:CMErrorCritical
                                    userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorDownloadCritical"
                                                                                forKey:NSLocalizedDescriptionKey]];
        }
        @finally
        {
            [machine setDownloading:NO];
        }
        
        if (success)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:CMInstallCompletedNotification
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:machine
                                                                                                   forKey:@"machine"]];
        }
        
        if (!success && error)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:CMInstallErrorNotification
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:error
                                                                                                   forKey:@"error"]];
        }
    }];
    
    [machine setDownloading:YES];
    
    [self toggleSystemSpecificButtons];
    [systemTableView reloadData];
    
    [downloadQueue addOperation:downloadOp];
}

- (void)synchronizeMachines
{
#ifdef DEBUG
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
#endif
    
    if ([remoteMachines count] < 1)
    {
        NSArray *machines = [self machinesAvailableForDownload];
        if (machines)
            [remoteMachines addObjectsFromArray:machines];
    }
    
    // Machine configurations
    NSArray *foundConfigurations = [CMEmulatorController machineConfigurations];
    
    [installedMachines removeAllObjects];
    [availableMachines removeAllObjects];
    
    [foundConfigurations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMMachine *machine = [[[CMMachine alloc] initWithPath:obj] autorelease];
        [machine setInstalled:YES];
        [installedMachines addObject:machine];
    }];
    
    [availableMachines addObjectsFromArray:remoteMachines];
    [availableMachines removeObjectsInArray:installedMachines];
    
    [allMachines removeAllObjects];
    [allMachines addObjectsFromArray:availableMachines];
    [allMachines addObjectsFromArray:installedMachines];
    
    // Sort the three arrays by 1. system, 2. name
    NSArray *arraysToSort = [NSArray arrayWithObjects:installedMachines, availableMachines, allMachines, nil];
    [arraysToSort enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [obj sortUsingComparator:^NSComparisonResult(CMMachine *obj1, CMMachine *obj2)
         {
             if ([obj1 system] != [obj2 system])
                 return [obj1 system] - [obj2 system];
             
             return [[obj1 name] localizedCompare:[obj2 name]];
         }];
    }];
    
    // If the selected machine is no longer available, select closest
    CMMachine *selectedMachine = [[[self machineWithId:CMGetObjPref(@"machineConfiguration")] copy] autorelease];
    if (![installedMachines containsObject:selectedMachine])
    {
        __block CMMachine *machine = [installedMachines lastObject];
        [installedMachines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            NSInteger systemComparison = [@([selectedMachine system]) compare:@([obj system])];
            NSInteger nameComparison = [[selectedMachine name] caseInsensitiveCompare:[obj name]];
            
            if (systemComparison != NSOrderedAscending && nameComparison != NSOrderedDescending)
            {
                machine = obj;
                *stop = YES;
            }
        }];
        
        if (machine)
            CMSetObjPref(@"machineConfiguration", [machine machineId]);
    }
    
    [systemTableView reloadData];
    
    [self toggleSystemSpecificButtons];
    [self updateCurrentConfigurationInformation];
    
#ifdef DEBUG
    NSLog(@"synchronizeMachines: Took %.02fms",
          [NSDate timeIntervalSinceReferenceDate] - startTime);
#endif
}

- (void)synchronizeSettings
{
    [self synchronizeMachines];
    
    // Update emulation speed
    [emulationSpeedSlider setDoubleValue:[self physicalPositionOfSlider:emulationSpeedSlider
                                                            fromVirtual:CMGetIntPref(@"emulationSpeedPercentage")
                                                             usingTable:virtualEmulationSpeedRange]];
    
    // Update joystick device view
    [self setDeviceForJoystickPort:0
                        toDeviceId:[[self joystickPort1Selection] deviceId]];
    
    [self setDeviceForJoystickPort:1
                        toDeviceId:[[self joystickPort2Selection] deviceId]];
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

- (CMMachine *)selectedMachine
{
    NSInteger selectedRow = [systemTableView selectedRow];
    CMMachine *machine = nil;
    
    if (selectedRow >= 0)
        machine = [[self machinesCurrentlyVisible] objectAtIndex:selectedRow];
    
    return machine;
}

- (void)toggleSystemSpecificButtons
{
    CMMachine *selectedMachine = [self selectedMachine];
    
    BOOL isRemoveButtonEnabled = selectedMachine
        && [selectedMachine installed]
        && [allMachines count] > 1; // At least one machine must remain
    BOOL isAddButtonEnabled = selectedMachine
        && ![selectedMachine installed]
        && ![selectedMachine downloading];
    
    [addMachineButton setEnabled:isAddButtonEnabled];
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

- (void)installMachineConfiguration:(id)sender
{
    CMMachine *selectedMachine = [self selectedMachine];
    
    if (selectedMachine
        && ![selectedMachine installed]
        && ![selectedMachine downloading])
    {
        [self startBackgroundDownloadOfMachine:selectedMachine];
    }
}

- (void)removeMachineConfiguration:(id)sender
{
    NSString *selectedMachineId = [[self selectedMachine] machineId];
    
    if (selectedMachineId)
    {
        NSString *message = [NSString stringWithFormat:CMLoc(@"SureYouWantToDeleteTheMachine_f"),
                             selectedMachineId];
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

- (void)refreshMachineList:(id)sender
{
    [self synchronizeMachines];
    [self requestMachineFeedUpdate];
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
            CMMachine *selectedMachine = [self selectedMachine];
            if (selectedMachine)
            {
                [CMEmulatorController removeMachineConfiguration:[selectedMachine path]];
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
    CMMachine *selectedMachine = [self selectedMachine];
    NSString *finderPath;
    
    if (selectedMachine)
        finderPath = [CMEmulatorController pathForMachineConfigurationNamed:[selectedMachine machineId]];
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
    if ([keyPath isEqualToString:@"machineDisplayMode"])
    {
        machineDisplayMode = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        [systemTableView reloadData];
        [self toggleSystemSpecificButtons];
    }
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

#pragma mark - NSNotifications

- (void)receivedInstallStartedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"Received download started notification");
#endif
    
    [self performBlockOnMainThread:^
     {
         [systemTableView reloadData];
         [self toggleSystemSpecificButtons];
     }];
}

- (void)receivedInstallCompletedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"Received download completed notification");
#endif
    
    [self performBlockOnMainThread:^
     {
         [self synchronizeMachines];
     }];
}

- (void)receivedInstallErrorNotification:(NSNotification *)notification
{
    NSError *error = [[notification userInfo] objectForKey:@"error"];
    
#ifdef DEBUG
    NSLog(@"Received error notification: %@", error);
#endif
    
    if (error)
    {
        [self performBlockOnMainThread:^
         {
             NSAlert *alert = [NSAlert alertWithMessageText:CMLoc([error localizedDescription])
                                              defaultButton:CMLoc(@"OK")
                                            alternateButton:nil
                                                otherButton:nil
                                  informativeTextWithFormat:@""];
             
             [alert beginSheetModalForWindow:[self window]
                               modalDelegate:self
                              didEndSelector:nil
                                 contextInfo:nil];
         }];
    }
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
    return [[self machinesCurrentlyVisible] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    CMMachine *machine = [[self machinesCurrentlyVisible] objectAtIndex:rowIndex];
    NSString *columnIdentifer = [aTableColumn identifier];
    
    if ([columnIdentifer isEqualToString:@"isSelected"])
        return [NSNumber numberWithBool:[machine isEqual:CMGetObjPref(@"machineConfiguration")]];
    else if ([columnIdentifer isEqualToString:@"spinner"])
        return [NSNumber numberWithBool:YES];
    else if ([columnIdentifer isEqualToString:@"name"])
        return machine;
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *columnIdentifer = [tableColumn identifier];
    if ([columnIdentifer isEqualToString:@"isSelected"])
    {
        CMMachine *machine = [[self machinesCurrentlyVisible] objectAtIndex:row];
        
        CMSetObjPref(@"machineConfiguration", [machine path]);
        [self updateCurrentConfigurationInformation];
        
        // This is so that the radio buttons can be deselected
        [tableView reloadData];
    }
}

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"isSelected"])
    {
        NSButtonCell *buttonCell = aCell;
        CMMachine *machine = [[self machinesCurrentlyVisible] objectAtIndex:rowIndex];
        
        [buttonCell setEnabled:[machine installed]];
        [buttonCell setImagePosition:[machine installed] ? NSImageOnly : NSNoImage];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self toggleSystemSpecificButtons];
}

#pragma mark MGScopeBarDelegate

- (int)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar
{
    if (theScopeBar == keyboardScopeBar)
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
                    @CMKeyShiftStateNormal,
                    @CMKeyShiftStateShifted, nil];
        }
        else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
        {
            return [NSArray arrayWithObjects:
                    @CMKeyLayoutArabic,
                    @CMKeyLayoutBrazilian,
                    @CMKeyLayoutEstonian,
                    @CMKeyLayoutEuropean,
                    @CMKeyLayoutFrench,
                    @CMKeyLayoutGerman,
                    @CMKeyLayoutJapanese,
                    @CMKeyLayoutKorean,
                    @CMKeyLayoutRussian,
                    @CMKeyLayoutSpanish,
                    @CMKeyLayoutSwedish, nil];
        }
    }
    else if (theScopeBar == machineScopeBar)
    {
        return [NSArray arrayWithObjects:
                @CMShowAllMachines,
                @CMShowInstalledMachines,
                @CMShowAvailableMachines, nil];
    }
    
    return nil;
}

- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(int)groupNumber // return nil or an empty string for no label.
{
    if (theScopeBar == keyboardScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_REGIONS)
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
    if (theScopeBar == keyboardScopeBar)
    {
        if (groupNumber == SCOPEBAR_GROUP_SHIFTED)
        {
            NSInteger shiftState = [identifier integerValue];
            
            if (shiftState == CMKeyShiftStateNormal)
                return CMLoc(@"KeyStateNormal");
            if (shiftState == CMKeyShiftStateShifted)
                return CMLoc(@"KeyStateShifted");
        }
        else if (groupNumber == SCOPEBAR_GROUP_REGIONS)
        {
            NSInteger layoutId = [identifier integerValue];
            
            if (layoutId == CMKeyLayoutArabic)
                return CMLoc(@"MsxKeyLayoutArabic");
            if (layoutId == CMKeyLayoutBrazilian)
                return CMLoc(@"MsxKeyLayoutBrazilian");
            if (layoutId == CMKeyLayoutEstonian)
                return CMLoc(@"MsxKeyLayoutEstonian");
            if (layoutId == CMKeyLayoutEuropean)
                return CMLoc(@"MsxKeyLayoutEuropean");
            if (layoutId == CMKeyLayoutFrench)
                return CMLoc(@"MsxKeyLayoutFrench");
            if (layoutId == CMKeyLayoutGerman)
                return CMLoc(@"MsxKeyLayoutGerman");
            if (layoutId == CMKeyLayoutJapanese)
                return CMLoc(@"MsxKeyLayoutJapanese");
            if (layoutId == CMKeyLayoutKorean)
                return CMLoc(@"MsxKeyLayoutKorean");
            if (layoutId == CMKeyLayoutRussian)
                return CMLoc(@"MsxKeyLayoutRussian");
            if (layoutId == CMKeyLayoutSpanish)
                return CMLoc(@"MsxKeyLayoutSpanish");
            if (layoutId == CMKeyLayoutSwedish)
                return CMLoc(@"MsxKeyLayoutSwedish");
        }
    }
    else if (theScopeBar == machineScopeBar)
    {
        NSInteger displayMode = [identifier integerValue];
        
        if (displayMode == CMShowInstalledMachines)
            return CMLoc(@"Installed");
        else if (displayMode == CMShowAvailableMachines)
            return CMLoc(@"NotInstalled");
        else if (displayMode == CMShowAllMachines)
            return CMLoc(@"All");
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
            NSNumber *layoutId = identifier;
            selectedKeyboardRegion = [layoutId integerValue];
            
            [keyboardLayoutEditor reloadData];
        }
    }
    else if (theScopeBar == machineScopeBar)
    {
        CMSetIntPref(@"machineDisplayMode", [identifier integerValue]);
    }
}

@end