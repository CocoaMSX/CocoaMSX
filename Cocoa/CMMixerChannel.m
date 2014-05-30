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
#import "CMMixerChannel.h"

@implementation CMMixerChannel

@synthesize name = _name;
@synthesize enabled = _enabled;
@synthesize volume = _volume;
@synthesize balance = _balance;

+ (CMMixerChannel *)mixerChannelNamed:(NSString *)name
                  enabledPropertyName:(NSString *)enabledPropertyName
                   volumePropertyName:(NSString *)volumePropertyName
                  balancePropertyName:(NSString *)balancePropertyName;
{
    CMMixerChannel *mc = [[CMMixerChannel alloc] initWithChannelName:name
                                                 enabledPropertyName:enabledPropertyName
                                                  volumePropertyName:volumePropertyName
                                                 balancePropertyName:balancePropertyName];
    
    return [mc autorelease];
}

- (id)initWithChannelName:(NSString *)name
      enabledPropertyName:(NSString *)enabledPropertyName
       volumePropertyName:(NSString *)volumePropertyName
      balancePropertyName:(NSString *)balancePropertyName
{
    if (self = [self init])
    {
        _name = [name copy];
        _enabledPropertyName = [enabledPropertyName copy];
        _volumePropertyName = [volumePropertyName copy];
        _balancePropertyName = [balancePropertyName copy];

        _enabled = CMGetBoolPref(enabledPropertyName);
        _volume = CMGetIntPref(volumePropertyName);
        _balance = CMGetIntPref(balancePropertyName);

        // Start observing the properties
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:_enabledPropertyName
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:_volumePropertyName
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:_balancePropertyName
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    // Stop observing
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:_enabledPropertyName];
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:_volumePropertyName];
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:_balancePropertyName];
    
    [_name release];
    [_enabledPropertyName release];
    [_volumePropertyName release];
    [_balancePropertyName release];
    
    [super dealloc];
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    if (enabled != CMGetBoolPref(_enabledPropertyName))
        CMSetBoolPref(_enabledPropertyName, enabled);
}

- (void)setVolume:(NSInteger)volume
{
    _volume = volume;
    if (volume != CMGetIntPref(_volumePropertyName))
        CMSetIntPref(_volumePropertyName, volume);
}

- (void)setBalance:(NSInteger)balance
{
    _balance = balance;
    if (balance != CMGetIntPref(_balancePropertyName))
        CMSetIntPref(_balancePropertyName, balance);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:_enabledPropertyName])
    {
        NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (_enabled != newValue)
            [self setEnabled:newValue];
    }
    else if ([keyPath isEqualToString:_volumePropertyName])
    {
        NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (_volume != newValue)
            [self setVolume:newValue];
    }
    else if ([keyPath isEqualToString:_balancePropertyName])
    {
        NSInteger newValue = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (_balance != newValue)
            [self setBalance:newValue];
    }
}

@end
