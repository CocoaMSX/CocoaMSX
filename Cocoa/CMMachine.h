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
#import <Foundation/Foundation.h>

extern NSString * const CMMsxMachine;
extern NSString * const CMMsx2Machine;
extern NSString * const CMMsx2PMachine;
extern NSString * const CMMsxTurboRMachine;

#define CMUnknown   0
#define CMMsx       1
#define CMMsx2      2
#define CMMsx2Plus  3
#define CMMsxTurboR 4

#define CMMachineDownloadable 1
#define CMMachineDownloading  2
#define CMMachineInstalled    3

@interface CMMachine : NSObject<NSCopying, NSCoding>
{
    NSString *_machineId;
    NSString *_name;
    NSString *_path;
    NSString *_checksum;
    NSInteger _system;
    NSURL *_machineUrl;
    NSInteger _status;
    BOOL _active;
}

@property (nonatomic, copy) NSString *machineId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *checksum;
@property (nonatomic, retain) NSURL *machineUrl;
@property (nonatomic, assign) NSInteger system;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) BOOL active;

+ (CMMachine *)machineWithPath:(NSString *)path;

- (id)initWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path
         machineId:(NSString *)machineId
              name:(NSString *)name
        systemName:(NSString *)systemName;

- (NSString *)systemName;
- (NSString *)downloadPath;

@end
