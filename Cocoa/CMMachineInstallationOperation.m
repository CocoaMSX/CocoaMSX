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
                                userInfo:[NSMutableDictionary dictionaryWithObject:@"Could not complete download - an unexpected error occurred."
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
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"error", [self machine], @"machine", nil]];
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
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"An error occurred during download."
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
//#ifdef DEBUG
//    NSLog(@"Sleeping");
//    [NSThread sleepForTimeInterval:10];
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
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"An error occurred during download."
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
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"Could not verify download."
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
                                     userInfo:[NSMutableDictionary dictionaryWithObject:@"An error occurred while writing the downloaded machine."
                                                                                 forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
    
#ifdef DEBUG
    NSLog(@"All done");
#endif
    
    return YES;
}

@end
