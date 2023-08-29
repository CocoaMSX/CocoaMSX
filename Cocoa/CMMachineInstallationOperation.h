/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2016 Akop Karapetyan
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

extern NSErrorDomain const CMInstallErrorDomain;
typedef NS_ERROR_ENUM(CMInstallErrorDomain, CMMachineInstallationError)
{
    CMErrorDownloading NS_SWIFT_NAME(downloading)       = 100,
    CMErrorWriting NS_SWIFT_NAME(writing)               = 101,
    CMErrorExecutingUnzip NS_SWIFT_NAME(executingUnzip) = 102,
    CMErrorUnzipping NS_SWIFT_NAME(unzipping)           = 103,
    CMErrorDeleting NS_SWIFT_NAME(deleting)             = 104,
    CMErrorVerifyingHash NS_SWIFT_NAME(verifyingHash)   = 105,
    CMErrorParsingJson NS_SWIFT_NAME(parsingJson)       = 106,
    CMErrorCritical NS_SWIFT_NAME(critical)             = 107,
};

extern NSNotificationName const CMInstallStartedNotification;
extern NSNotificationName const CMInstallCompletedNotification;
extern NSNotificationName const CMInstallErrorNotification;

@class CMMachine;

@interface CMMachineInstallationOperation : NSOperation

+ (instancetype)installationOperationWithMachine:(CMMachine *)machine;

- (instancetype)initWithMachine:(CMMachine *)machine;

@property (nonatomic, strong) CMMachine *machine;

@end
