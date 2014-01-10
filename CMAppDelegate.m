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
#import "CMAppDelegate.h"

#import "CMPreferences.h"

#import <IOKit/pwr_mgt/IOPMLib.h>

@interface CMAppDelegate ()

- (void)initializeResources;
- (void)disableScreenSaver;
- (void)enableScreenSaver;

@end

@implementation CMAppDelegate

@synthesize emulator = _emulator;

#pragma mark - Initialization & Deallocation

+ (void)initialize
{
    // Register the NSUserDefaults
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundleResourcePath];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)awakeFromNib
{
    didApplicationLoad = NO;
    self->preventSleepAssertionID = kIOPMNullAssertionID;
}

- (void)dealloc
{
    self.emulator = nil;
    
    [super dealloc];
}

#pragma mark - NSManagedObjectContext

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"preventSleep"])
    {
        BOOL preventSleep = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (preventSleep)
            [self disableScreenSaver];
        else
            [self enableScreenSaver];
    }
}

#pragma mark - Private Methods

- (void)disableScreenSaver
{
    CFStringRef reasonForActivity = (__bridge CFStringRef)CMLoc(@"CocoaMSX is running", @"");
    if (self->preventSleepAssertionID != kIOPMNullAssertionID)
        return;

    // In case the new assertion fails
    self->preventSleepAssertionID = kIOPMNullAssertionID;
    
    IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
                                kIOPMAssertionLevelOn,
                                reasonForActivity,
                                &self->preventSleepAssertionID);
    
#if DEBUG
    NSLog(@"Screensaver disabled");
#endif
}

- (void)enableScreenSaver
{
    if (self->preventSleepAssertionID == kIOPMNullAssertionID)
        return;
    
    IOPMAssertionRelease(self->preventSleepAssertionID);
    self->preventSleepAssertionID = kIOPMNullAssertionID;
    
#if DEBUG
    NSLog(@"Screensaver enabled");
#endif
}

- (void)initializeResources
{
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    
    NSInteger currentVersion = [[infoDict objectForKey:@"CFBundleVersion"] integerValue];
    NSInteger previousVersion = CMGetIntPref(@"previousVersion");
    
    BOOL versionChanged = (currentVersion != previousVersion);
    
#ifdef DEBUG
    NSLog(@"initializeResources: version: %d lastVersion: %d",
          (int)currentVersion, (int)previousVersion);
#endif
    
    __block BOOL hasErrored = NO;
    __block NSInteger dirsCreated = 0;
    __block NSInteger filesCopied = 0;
    
    CMPreferences *prefs = [CMPreferences preferences];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSMutableArray *directoriesToCreate = [NSMutableArray array];
    if ([prefs createAudioCaptureDirectory])
        [directoriesToCreate addObject:prefs.audioCaptureDirectory];
    if ([prefs createVideoCaptureDirectory])
        [directoriesToCreate addObject:prefs.videoCaptureDirectory];
    if ([prefs createSramDirectory])
        [directoriesToCreate addObject:prefs.sramDirectory];
    if ([prefs createCassetteDataDirectory])
        [directoriesToCreate addObject:prefs.cassetteDataDirectory];
    if ([prefs createDatabaseDirectory])
        [directoriesToCreate addObject:prefs.databaseDirectory];
    if ([prefs createMachineDirectory])
        [directoriesToCreate addObject:prefs.machineDirectory];
    if ([prefs createSnapshotDirectory])
        [directoriesToCreate addObject:prefs.snapshotDirectory];
    
    [directoriesToCreate enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *directory = obj;
        if ([fm fileExistsAtPath:directory])
            return; // Don't try if it already exists
        
        NSError *createDirectoryError = NULL;
        
        [fm createDirectoryAtPath:directory
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&createDirectoryError];
        
        if (createDirectoryError)
        {
            // TODO: log this
#ifdef DEBUG
            NSLog(@"initializeResources: Error creating directory '%@': %@",
                  directory, createDirectoryError.localizedDescription);
#endif
            hasErrored = YES;
            return;
        }
        
#ifdef DEBUG
        NSLog(@"initializeResources: Created directory '%@'", directory);
#endif
        
        dirsCreated++;
    }];
    
    // Copy the resources from our bundle
    NSMutableArray *resourcesToCopy = [NSMutableArray array];
    
    if (prefs.createMachineDirectory) // Copy stock machines
        [resourcesToCopy addObjectsFromArray:[NSArray arrayWithObjects:
                                              @"Machines/MSX - C-BIOS",
                                              @"Machines/MSX2 - C-BIOS",
                                              @"Machines/MSX2+ - C-BIOS", nil]];
    
    if (prefs.createDatabaseDirectory) // Copy stock databases
        [resourcesToCopy addObject:@"Databases"];
    
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    
    [resourcesToCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         NSString *sourcePath = [resourcePath stringByAppendingPathComponent:obj];
         NSString *destPath = [prefs.appSupportDirectory stringByAppendingPathComponent:obj];
         
         if (![fm fileExistsAtPath:destPath])
         {
             [fm createDirectoryAtPath:destPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];
             
#ifdef DEBUG
             NSLog(@"initializeResources: Created directory '%@'", destPath);
#endif
             
             dirsCreated++;
         }
         
         NSError *enumerateFilesError = nil;
         NSArray *sourceFiles = [fm contentsOfDirectoryAtPath:sourcePath error:&enumerateFilesError];
         
         if (enumerateFilesError)
         {
             // TODO: log this
#ifdef DEBUG
             NSLog(@"initializeResources: Error enumerating files in '%@': %@",
                   sourcePath, enumerateFilesError.localizedDescription);
#endif
             hasErrored = YES;
             return;
         }
         
         [sourceFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
          {
              NSString *sourceFile = [sourcePath stringByAppendingPathComponent:obj];
              NSString *destFile = [destPath stringByAppendingPathComponent:obj];
              
              if ([fm fileExistsAtPath:destFile])
              {
                  // File already exists
                  if (versionChanged)
                  {
                      NSError *removeFilesError = NULL;
                      [fm removeItemAtPath:destFile error:&removeFilesError];
                      
                      if (removeFilesError)
                      {
                          // Couldn't remove file - don't attempt copy
#ifdef DEBUG
                          NSLog(@"initializeResources: Error deleting existing resource '%@'",
                                destFile);
#endif
                          return;
                      }
                  }
                  else
                  {
                      // Version hasn't changed, don't copy an existing file
                      return;
                  }
              }
              
              NSError *copyFilesError = NULL;
              [fm copyItemAtPath:sourceFile toPath:destFile error:&copyFilesError];
              
              if (copyFilesError)
              {
                  // TODO: log this
#ifdef DEBUG
                  NSLog(@"initializeResources: Error copying resource '%@': %@",
                        obj, copyFilesError.localizedDescription);
#endif
                  hasErrored = YES;
                  return;
              }
              
#ifdef DEBUG
              NSLog(@"Copied '%@' to '%@'",
                    [sourceFile lastPathComponent], destFile);
#endif
              
              filesCopied++;
          }];
     }];
    
#ifdef DEBUG
    NSLog(@"initializeResources: initialized (created %d dirs; copied %d files)",
          (int)dirsCreated, (int)filesCopied);
    
    if (hasErrored)
        NSLog(@"initializeResources: Errors during initialization");
#endif
    
    if (!hasErrored)
        CMSetIntPref(@"previousVersion", currentVersion);
}

#pragma mark - NSApplicationDelegate

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    if (![self emulator] || ![[NSFileManager defaultManager] fileExistsAtPath:filename])
        return NO;
    
    if (!didApplicationLoad)
    {
        // Ask the emulator to load the file when initialization completes
        [[self emulator] setFileToLoadAtStartup:filename];
        return YES;
    }
    
    // Load it now
    return [[self emulator] insertUnknownMedia:filename];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [self initializeResources];
    
    [self setEmulator:[[[CMEmulatorController alloc] init] autorelease]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[self emulator] showWindow:self];
    
    didApplicationLoad = YES;
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"preventSleep"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:@"preventSleep"];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (CMGetBoolPref(@"preventSleep"))
        [self disableScreenSaver];
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
    [self enableScreenSaver];
}

@end
