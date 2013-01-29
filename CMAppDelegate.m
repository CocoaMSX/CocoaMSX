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
#import "CMAppDelegate.h"

#import "CMPreferences.h"

@interface CMAppDelegate ()

- (void)initializeResources;

@end

@implementation CMAppDelegate

@synthesize emulator = _emulator;

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

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
    applicationDidLoad = NO;
}

- (void)dealloc
{
    [_persistentStoreCoordinator release];
    [_managedObjectModel release];
    [_managedObjectContext release];
    
    self.emulator = nil;
    
    [super dealloc];
}

#pragma mark - NSManagedObjectContext

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CocoaMSX" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator)
        return _persistentStoreCoordinator;
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom)
    {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [[CMPreferences preferences] appSupportUrl];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties)
    {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError)
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (!ok)
        {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else
    {
        if (![properties[NSURLIsDirectoryKey] boolValue])
        {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).",
                                            [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"CocoaMSX.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] autorelease];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    
    _persistentStoreCoordinator = [coordinator retain];
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already
// bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
        return _managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        
        NSError *error = [NSError errorWithDomain:@"COCOAMSX_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        
        return nil;
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

#pragma mark - Private Methods

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
    if (!self.emulator || ![[NSFileManager defaultManager] fileExistsAtPath:filename])
        return NO;
    
    if (!applicationDidLoad)
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
    
    applicationDidLoad = YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext)
        return NSTerminateNow;
    
    if (![[self managedObjectContext] commitEditing])
    {
        NSLog(@"%@:%@ unable to commit editing to terminate",
              [self class], NSStringFromSelector(_cmd));
        
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges])
        return NSTerminateNow;
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error])
    {
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result)
            return NSTerminateCancel;
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", nil);
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", nil);
        NSString *quitButton = NSLocalizedString(@"Quit anyway", nil);
        NSString *cancelButton = NSLocalizedString(@"Cancel", nil);
        
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn)
            return NSTerminateCancel;
    }
    
    return NSTerminateNow;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
