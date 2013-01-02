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
#import "CMAppDelegate.h"

#import "CMPreferences.h"
#import "CMEmulatorController.h"

@interface CMAppDelegate ()

- (void)initializeResources;

@end

@implementation CMAppDelegate

@synthesize emulator;
@synthesize applicationHasLoaded;

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
    self.applicationHasLoaded = NO;
}

- (void)dealloc
{
    self.emulator = nil;
    
    [super dealloc];
}

#pragma mark - Private Methods

- (void)initializeResources
{
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
            NSLog(@"Error creating directory '%@': %@", directory,
                  createDirectoryError.localizedDescription);
#endif
            return;
        }
        
#ifdef DEBUG
        NSLog(@"Created directory '%@'", directory);
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
             NSLog(@"Created directory '%@'", destPath);
#endif
             
             dirsCreated++;
         }
         
         NSError *enumerateFilesError = NULL;
         NSArray *sourceFiles = [fm contentsOfDirectoryAtPath:sourcePath error:&enumerateFilesError];
         
         if (enumerateFilesError)
         {
             // TODO: log this
#ifdef DEBUG
             NSLog(@"Error enumerating files in '%@': %@", sourcePath,
                   enumerateFilesError.localizedDescription);
#endif
             return;
         }
         
         [sourceFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
          {
              NSString *sourceFile = [sourcePath stringByAppendingPathComponent:obj];
              NSString *destFile = [destPath stringByAppendingPathComponent:obj];
              
              if ([fm fileExistsAtPath:destFile])
                  return;
              
              NSError *copyFilesError = NULL;
              [fm copyItemAtPath:sourceFile toPath:destFile error:&copyFilesError];
              
              if (copyFilesError)
              {
                  // TODO: log this
#ifdef DEBUG
                  NSLog(@"Error copying resource '%@': %@", obj,
                        copyFilesError.localizedDescription);
#endif
                  return;
              }
              
#ifdef DEBUG
              NSLog(@"Copied '%@' to '%@'", [sourceFile lastPathComponent], destFile);
#endif
              
              filesCopied++;
          }];
     }];
    
#ifdef DEBUG
    NSLog(@"Resources: initialized (created %ld dirs; copied %ld files)",
          dirsCreated, filesCopied);
#endif
}

#pragma mark - NSApplicationDelegate

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    if (!self.emulator || ![[NSFileManager defaultManager] fileExistsAtPath:filename])
        return NO;
    
    if (!self.applicationHasLoaded)
    {
        // Ask the emulator to load the file when initialization completes
        self.emulator.fileToLoadAtStartup = filename;
        return YES;
    }
    
    // Load it now
    return [self.emulator insertUnknownMedia:filename];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [self initializeResources];
    
    self.emulator = [[[CMEmulatorController alloc] init] autorelease];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self.emulator showWindow:self];
    self.applicationHasLoaded = YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
