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
#import <Foundation/Foundation.h>

@class CMInputDeviceLayout;

@interface CMPreferences : NSObject

#define CMSnapshotIconStyleNone      0
#define CMSnapshotIconStyleScreen    1
#define CMSnapshotIconStyleFilmstrip 2

+ (CMPreferences *)preferences;

- (NSInteger)screenWidth;
- (void)setScreenWidth:(NSInteger)width;
- (NSInteger)screenHeight;
- (void)setScreenHeight:(NSInteger)height;

- (CMInputDeviceLayout *)keyboardLayout;
- (void)setKeyboardLayout:(CMInputDeviceLayout *)keyboardLayout;
- (CMInputDeviceLayout *)joystickOneLayout;
- (void)setJoystickOneLayout:(CMInputDeviceLayout *)joystickOneLayout;
- (CMInputDeviceLayout *)joystickTwoLayout;
- (void)setJoystickTwoLayout:(CMInputDeviceLayout *)joystickTwoLayout;

- (CMInputDeviceLayout *)defaultKeyboardLayout;
- (CMInputDeviceLayout *)defaultJoystickOneLayout;
- (CMInputDeviceLayout *)defaultJoystickTwoLayout;

- (NSString *)appSupportDirectory;
- (NSString *)audioCaptureDirectory;
- (void)setAudioCaptureDirectory:(NSString *)directory;
- (NSString *)videoCaptureDirectory;
- (void)setVideoCaptureDirectory:(NSString *)directory;
- (NSString *)quickSaveDirectory;
- (void)setQuickSaveDirectory:(NSString *)directory;
- (NSString *)sramDirectory;
- (void)setSramDirectory:(NSString *)directory;
- (NSString *)cassetteDataDirectory;
- (void)setCassetteDataDirectory:(NSString *)directory;
- (NSString *)databaseDirectory;
- (void)setDatabaseDirectory:(NSString *)directory;
- (NSString *)machineDirectory;
- (void)setMachineDirectory:(NSString *)directory;
- (NSString *)snapshotDirectory;
- (void)setSnapshotDirectory:(NSString *)directory;
- (NSString *)machineConfiguration;
- (void)setMachineConfiguration:(NSString *)configuration;

- (NSString *)machineConfiguration;
- (void)setMachineConfiguration:(NSString *)configuration;
- (NSInteger)vdpSyncMode;
- (void)setVdpSyncMode:(NSInteger)syncMode;
- (NSInteger)emulationSpeedPercentage;
- (void)setEmulationSpeedPercentage:(NSInteger)percentage;
- (NSInteger)scanlineAmount;
- (void)setScanlineAmount:(NSInteger)amount;

- (BOOL)createAudioCaptureDirectory;
- (BOOL)createVideoCaptureDirectory;
- (BOOL)createQuickSaveDirectory;
- (BOOL)createSramDirectory;
- (BOOL)createCassetteDataDirectory;
- (BOOL)createDatabaseDirectory;
- (BOOL)createMachineDirectory;
- (BOOL)createSnapshotDirectory;

- (void)setCassetteDirectory:(NSString *)directory;
- (NSString *)cassetteDirectory;
- (void)setCartridgeDirectory:(NSString *)directory;
- (NSString *)cartridgeDirectory;
- (void)setDiskDirectory:(NSString *)directory;
- (NSString *)diskDirectory;

- (void)setSnapshotIconStyle:(NSInteger)iconStyle;
- (NSInteger)snapshotIconStyle;

@end
