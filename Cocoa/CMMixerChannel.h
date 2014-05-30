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

@interface CMMixerChannel : NSObject
{
    NSString *_name;
    BOOL _enabled;
    NSInteger _volume;
    NSInteger _balance;
    NSString *_enabledPropertyName;
    NSString *_volumePropertyName;
    NSString *_balancePropertyName;
}

+ (CMMixerChannel *)mixerChannelNamed:(NSString *)name
                  enabledPropertyName:(NSString *)enabledPropertyName
                   volumePropertyName:(NSString *)volumePropertyName
                  balancePropertyName:(NSString *)balancePropertyName;

- (id)initWithChannelName:(NSString *)name
      enabledPropertyName:(NSString *)enabledPropertyName
       volumePropertyName:(NSString *)volumePropertyName
      balancePropertyName:(NSString *)balancePropertyName;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger volume;
@property (nonatomic, assign) NSInteger balance;
@property (nonatomic, assign) BOOL enabled;

@end
