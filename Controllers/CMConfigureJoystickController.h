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
#import <Cocoa/Cocoa.h>

#import "CMGamepadManager.h"

@interface CMGamepadConfiguration : NSObject
{
    NSInteger _minX;
    NSInteger _centerX;
    NSInteger _maxX;
    
    NSInteger _minY;
    NSInteger _centerY;
    NSInteger _maxY;
    
    NSInteger _buttonAIndex;
    NSInteger _buttonBIndex;
}

@property (nonatomic, assign) NSInteger minX;
@property (nonatomic, assign) NSInteger centerX;
@property (nonatomic, assign) NSInteger maxX;

@property (nonatomic, assign) NSInteger minY;
@property (nonatomic, assign) NSInteger centerY;
@property (nonatomic, assign) NSInteger maxY;

@property (nonatomic, assign) NSInteger buttonAIndex;
@property (nonatomic, assign) NSInteger buttonBIndex;


@end

@interface CMConfigureJoystickController : NSWindowController<NSWindowDelegate, CMGamepadDelegate>
{
    NSInteger currentState;
    CMGamepadConfiguration *configuration;
    
    IBOutlet NSTextField *directionField;
}

- (void)restartConfiguration;

@end
