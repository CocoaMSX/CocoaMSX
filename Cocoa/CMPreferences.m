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
#import "CMPreferences.h"

#import "CMInputDeviceLayout.h"

#import "NSString+CMExtensions.h"

static NSString * const CMKeyboardLayoutPrefKey = @"msxKeyboardLayout";
static NSString * const CMJoystickOneLayoutPrefKey = @"msxJoystickOneLayout";
static NSString * const CMJoystickTwoLayoutPrefKey = @"msxJoystickTwoLayout";

static NSString * const CMAudioCaptureDirectoryKey = @"audioCaptureDirectory";
static NSString * const CMVideoCaptureDirectoryKey = @"videoCaptureDirectory";
static NSString * const CMSramDirectoryKey = @"sramDirectory";
static NSString * const CMCassetteDataDirectoryKey = @"cassetteDataDirectory";
static NSString * const CMDatabaseDirectoryKey = @"databaseDirectory";
static NSString * const CMMachineDirectoryKey = @"machineDirectory";
static NSString * const CMSnapshotDirectoryKey = @"snapshotDirectory";

static NSString * const CMCassetteDirectoryKey = @"cassetteDirectory";
static NSString * const CMCartridgeDirectoryKey = @"cartridgeDirectory";
static NSString * const CMDiskDirectoryKey = @"diskDirectory";

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
    return [[self appSupportUrl] path];
}

- (NSURL *)appSupportUrl
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSURL *appSupportUrl = [[fm URLsForDirectory:NSApplicationSupportDirectory
                                       inDomains:NSUserDomainMask] lastObject];
    
    if (!appSupportUrl)
        return nil;
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *appName = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
    
    return [appSupportUrl URLByAppendingPathComponent:appName];
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
    if (![directory isEqualToPath:defaultDirectory])
        [[NSUserDefaults standardUserDefaults] setObject:directory
                                                  forKey:CMAudioCaptureDirectoryKey];
}

#pragma mark - Input Devices

- (CMInputDeviceLayout *)keyboardLayout;
{
    NSData *layoutData = [[NSUserDefaults standardUserDefaults] objectForKey:CMKeyboardLayoutPrefKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];
}

- (void)setKeyboardLayout:(CMInputDeviceLayout *)keyboardLayout;
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keyboardLayout];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:CMKeyboardLayoutPrefKey];
}

- (CMInputDeviceLayout *)joystickOneLayout;
{
    NSData *layoutData = [[NSUserDefaults standardUserDefaults] objectForKey:CMJoystickOneLayoutPrefKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];
}

- (void)setJoystickOneLayout:(CMInputDeviceLayout *)joystickOneLayout;
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:joystickOneLayout];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:CMJoystickOneLayoutPrefKey];
}

- (CMInputDeviceLayout *)joystickTwoLayout;
{
    NSData *layoutData = [[NSUserDefaults standardUserDefaults] objectForKey:CMJoystickTwoLayoutPrefKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];
}

- (void)setJoystickTwoLayout:(CMInputDeviceLayout *)joystickTwoLayout;
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:joystickTwoLayout];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:CMJoystickTwoLayoutPrefKey];
}

- (CMInputDeviceLayout *)defaultKeyboardLayout;
{
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundleResourcePath];
    
    NSData *layoutData = [defaults objectForKey:CMKeyboardLayoutPrefKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];
}

- (CMInputDeviceLayout *)defaultJoystickOneLayout;
{
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundleResourcePath];
    
    NSData *layoutData = [defaults objectForKey:CMJoystickOneLayoutPrefKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];
}

- (CMInputDeviceLayout *)defaultJoystickTwoLayout;
{
    NSString *bundleResourcePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundleResourcePath];
    
    NSData *layoutData = [defaults objectForKey:CMJoystickTwoLayoutPrefKey];
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
