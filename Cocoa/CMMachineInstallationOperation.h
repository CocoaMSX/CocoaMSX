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

typedef NS_ENUM(NSInteger, CMMachineInstallationError)
{
    CMErrorDownloading    = 100,
    CMErrorWriting        = 101,
    CMErrorExecutingUnzip = 102,
    CMErrorUnzipping      = 103,
    CMErrorDeleting       = 104,
    CMErrorVerifyingHash  = 105,
    CMErrorParsingJson    = 106,
    CMErrorCritical       = 107,
};

extern NSString * const CMInstallStartedNotification;
extern NSString * const CMInstallCompletedNotification;
extern NSString * const CMInstallErrorNotification;

@class CMMachine;

@interface CMMachineInstallationOperation : NSOperation
{
    CMMachine *_machine;
}

+ (CMMachineInstallationOperation *)installationOperationWithMachine:(CMMachine *)machine;

- (id)initWithMachine:(CMMachine *)machine;

@property (nonatomic, retain) CMMachine *machine;

@end
