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
#import "CMPreferences.h"

#import "CMNSString+FileManagement.h"

NSString * const CMScreenWidthPrefKey = @"screenWidth";
NSString * const CMScreenHeightPrefKey = @"screenHeight";

NSString * const CMKeyboardLayoutPrefKey = @"keyboardLayout";

NSString * const CMAudioCaptureDirectoryKey = @"audioCaptureDirectory";
NSString * const CMVideoCaptureDirectoryKey = @"videoCaptureDirectory";
NSString * const CMQuickSaveDirectoryKey = @"quickSaveDirectory";
NSString * const CMSramDirectoryKey = @"sramDirectory";
NSString * const CMCassetteDataDirectoryKey = @"cassetteDataDirectory";
NSString * const CMDatabaseDirectoryKey = @"databaseDirectory";
NSString * const CMMachineDirectoryKey = @"machineDirectory";
NSString * const CMSnapshotDirectoryKey = @"snapshotDirectory";
NSString * const CMMachineConfigurationKey = @"machineConfiguration";
NSString * const CMVdpSyncModeKey = @"vdpSyncMode";
NSString * const CMEmulationSpeedPercentageKey = @"emulationSpeedPercentage";

NSString * const CMCassetteDirectoryKey = @"cassetteDirectory";
NSString * const CMCartridgeDirectoryKey = @"cartridgeDirectory";
NSString * const CMDiskDirectoryKey = @"diskDirectory";

@interface CMPreferences ()

- (NSString *)appSupportSubdirectoryForKey:(NSString *)preferenceKey
                             defaultSuffix:(NSString *)defaultSuffix;
- (void)setAppSupportSubdirectoryForKey:(NSString *)preferenceKey
                      withDefaultSuffix:(NSString *)defaultSuffix
                            toDirectory:(NSString *)directory;

@end

@implementation CMPreferences

static CMPreferences *preferences = nil;

+ (CMPreferences *)preferences
{
    if (!preferences)
        preferences = [[CMPreferences alloc] init];
    
    return preferences;
}

#pragma mark - Private Methods

- (NSString *)appSupportDirectory
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* possibleURLs = [fm URLsForDirectory:NSApplicationSupportDirectory
                                       inDomains:NSUserDomainMask];
    
    if (possibleURLs.count < 1)
        return nil;
    
    NSURL *appSupportDir = [possibleURLs objectAtIndex:0];
    NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL *appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
    
    return appDirectory.path;
}

- (NSString *)appSupportSubdirectoryForKey:(NSString *)preferenceKey
                             defaultSuffix:(NSString *)defaultSuffix
{
    NSString *directory = [[NSUserDefaults standardUserDefaults] stringForKey:preferenceKey];
    if (!directory)
        directory = [[self appSupportDirectory] stringByAppendingPathComponent:defaultSuffix];
    
    return directory;
}

- (void)setAppSupportSubdirectoryForKey:(NSString *)preferenceKey
                      withDefaultSuffix:(NSString *)defaultSuffix
                            toDirectory:(NSString *)directory
{
    NSString *defaultDirectory = [[self appSupportDirectory] stringByAppendingPathComponent:defaultSuffix];
    if (![directory cm_isEqualToPath:defaultDirectory])
        [[NSUserDefaults standardUserDefaults] setObject:directory
                                                  forKey:CMAudioCaptureDirectoryKey];
}

#pragma mark - Video

- (NSInteger)screenWidth
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:CMScreenWidthPrefKey];
}

- (void)setScreenWidth:(NSInteger)width
{
    [[NSUserDefaults standardUserDefaults] setInteger:width forKey:CMScreenWidthPrefKey];
}

- (NSInteger)screenHeight
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:CMScreenHeightPrefKey];
}

- (void)setScreenHeight:(NSInteger)height
{
    [[NSUserDefaults standardUserDefaults] setInteger:height forKey:CMScreenHeightPrefKey];
}

#pragma mark - Keyboard

- (CMKeyLayout *)keyboardLayout
{
    NSData *layoutData = [[NSUserDefaults standardUserDefaults] objectForKey:CMKeyboardLayoutPrefKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];
}

- (void)setKeyboardLayout:(CMKeyLayout *)layout
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:layout];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:CMKeyboardLayoutPrefKey];
}

- (CMKeyLayout *)defaultLayout
{
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundleResourcePath];
    
    NSData *layoutData = [defaults objectForKey:CMKeyboardLayoutPrefKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];
}

#pragma mark - File Management

- (BOOL)createAudioCaptureDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMAudioCaptureDirectoryKey] == nil;
}

- (NSString *)audioCaptureDirectory
{
    return [self appSupportSubdirectoryForKey:CMAudioCaptureDirectoryKey
                                defaultSuffix:@"Audio Capture"];
}

- (void)setAudioCaptureDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMAudioCaptureDirectoryKey
                        withDefaultSuffix:@"Audio Capture"
                              toDirectory:directory];
}

- (BOOL)createVideoCaptureDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMVideoCaptureDirectoryKey] == nil;
}

- (NSString *)videoCaptureDirectory
{
    return [self appSupportSubdirectoryForKey:CMVideoCaptureDirectoryKey
                                defaultSuffix:@"Video Capture"];
}

- (void)setVideoCaptureDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMVideoCaptureDirectoryKey
                        withDefaultSuffix:@"Video Capture"
                              toDirectory:directory];
}

- (BOOL)createQuickSaveDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMQuickSaveDirectoryKey] == nil;
}

- (NSString *)quickSaveDirectory
{
    return [self appSupportSubdirectoryForKey:CMQuickSaveDirectoryKey
                                defaultSuffix:@"QuickSave"];
}

- (void)setQuickSaveDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMQuickSaveDirectoryKey
                        withDefaultSuffix:@"QuickSave"
                              toDirectory:directory];
}

- (BOOL)createSramDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMSramDirectoryKey] == nil;
}

- (NSString *)sramDirectory
{
    return [self appSupportSubdirectoryForKey:CMSramDirectoryKey
                                defaultSuffix:@"SRAM"];
}

- (void)setSramDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMSramDirectoryKey
                        withDefaultSuffix:@"SRAM"
                              toDirectory:directory];
}

- (BOOL)createCassetteDataDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMCassetteDataDirectoryKey] == nil;
}

- (NSString *)cassetteDataDirectory
{
    return [self appSupportSubdirectoryForKey:CMCassetteDataDirectoryKey
                                defaultSuffix:@"Cassettes"];
}

- (void)setCassetteDataDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMCassetteDataDirectoryKey
                        withDefaultSuffix:@"Cassettes"
                              toDirectory:directory];
}

- (BOOL)createDatabaseDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMDatabaseDirectoryKey] == nil;
}

- (NSString *)databaseDirectory
{
    return [self appSupportSubdirectoryForKey:CMDatabaseDirectoryKey
                                defaultSuffix:@"Databases"];
}

- (void)setDatabaseDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMDatabaseDirectoryKey
                        withDefaultSuffix:@"Databases"
                              toDirectory:directory];
}

- (BOOL)createMachineDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMMachineDirectoryKey] == nil;
}

- (NSString *)machineDirectory
{
    return [self appSupportSubdirectoryForKey:CMMachineDirectoryKey
                                defaultSuffix:@"Machines"];
}

- (void)setMachineDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMMachineDirectoryKey
                        withDefaultSuffix:@"Machines"
                              toDirectory:directory];
}

- (BOOL)createSnapshotDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMSnapshotDirectoryKey] == nil;
}

- (NSString *)snapshotDirectory
{
    return [self appSupportSubdirectoryForKey:CMSnapshotDirectoryKey
                                defaultSuffix:@"Snapshots"];
}

- (void)setSnapshotDirectory:(NSString *)directory
{
    [self setAppSupportSubdirectoryForKey:CMSnapshotDirectoryKey
                        withDefaultSuffix:@"Snapshots"
                              toDirectory:directory];
}

#pragma mark Emulation

- (NSString *)machineConfiguration
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMMachineConfigurationKey];
}

- (void)setMachineConfiguration:(NSString *)configuration
{
    [[NSUserDefaults standardUserDefaults] setObject:configuration
                                              forKey:CMMachineConfigurationKey];
}

- (NSInteger)vdpSyncMode
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:CMVdpSyncModeKey];
}

- (void)setVdpSyncMode:(NSInteger)syncMode
{
    [[NSUserDefaults standardUserDefaults] setInteger:syncMode
                                               forKey:CMVdpSyncModeKey];
}

- (NSInteger)emulationSpeedPercentage
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:CMEmulationSpeedPercentageKey];
}

- (void)setEmulationSpeedPercentage:(NSInteger)percentage
{
    [[NSUserDefaults standardUserDefaults] setInteger:percentage
                                               forKey:CMEmulationSpeedPercentageKey];
}

- (void)setCassetteDirectory:(NSString *)directory
{
    [[NSUserDefaults standardUserDefaults] setObject:directory
                                              forKey:CMCassetteDirectoryKey];
}

- (NSString *)cassetteDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMCassetteDirectoryKey];
}

- (void)setCartridgeDirectory:(NSString *)directory
{
    [[NSUserDefaults standardUserDefaults] setObject:directory
                                              forKey:CMCartridgeDirectoryKey];
}

- (NSString *)cartridgeDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMCartridgeDirectoryKey];
}

- (void)setDiskDirectory:(NSString *)directory
{
    [[NSUserDefaults standardUserDefaults] setObject:directory
                                              forKey:CMDiskDirectoryKey];
}

- (NSString *)diskDirectory
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CMDiskDirectoryKey];
}

@end
