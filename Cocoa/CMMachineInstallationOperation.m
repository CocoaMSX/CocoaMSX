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
#import "CMMachineInstallationOperation.h"

#import "CMMachine.h"

#import "NSString+CMExtensions.h"
#import "NSData+MD5.h"

#define DOWNLOAD_TIMEOUT_SECONDS 10

NSString *const CMInstallStartedNotification   = @"com.akop.CocoaMSX.InstallStarted";
NSString *const CMInstallCompletedNotification = @"com.akop.CocoaMSX.InstallCompleted";
NSString *const CMInstallErrorNotification     = @"com.akop.CocoaMSX.InstallError";

@interface CMMachineInstallationOperation ()

- (BOOL)downloadAndInstallMachine:(NSError **)error;

@end

@implementation CMMachineInstallationOperation

@synthesize machine = _machine;

+ (CMMachineInstallationOperation *)installationOperationWithMachine:(CMMachine *)machine
{
    return [[[CMMachineInstallationOperation alloc] initWithMachine:machine] autorelease];
}

#pragma mark - NSObject

- (id)initWithMachine:(CMMachine *)machine
{
    if ((self = [super init]))
    {
        _machine = [machine retain];
    }
    
    return self;
}

- (void)dealloc
{
    [self setMachine:nil];
    
    [super dealloc];
}

#pragma mark - NSOperation

- (void)main
{
    NSError *error = nil;
    BOOL success = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CMInstallStartedNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:[self machine]
                                                                                           forKey:@"machine"]];
    
    @try
    {
        success = [self downloadAndInstallMachine:&error];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:CMInstallCompletedNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:[self machine]
                                                                                               forKey:@"machine"]];
    }
    
    if (!success && error)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CMInstallErrorNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:error
                                                                                               forKey:@"error"]];
    }
}

#pragma mark - Private methods

- (BOOL)downloadAndInstallMachine:(NSError **)error
{
    CMMachine *machine = [self machine];
    
    if (![machine machineUrl])
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
    
//#ifdef DEBUG
//    NSLog(@"Sleeping");
//    [NSThread sleepForTimeInterval:5];
//#endif
    
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
    
#ifdef DEBUG
    NSLog(@"done. Verifying hash...");
#endif
    
    if (![[data md5] isCaseInsensitiveEqualToString:[machine checksum]])
    {
        if (error)
        {
#ifdef DEBUG
            NSLog(@"Hash verification error: computed: %@; received: %@",
                  [data md5], [machine checksum]);
#endif
            *error = [NSError errorWithDomain:@"org.akop.CocoaMSX"
                                         code:CMErrorVerifyingHash
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"ErrorVerifyingHash"
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

@end
