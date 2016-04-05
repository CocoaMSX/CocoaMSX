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
#import "CMConfigureJoystickController.h"

#import "CMGamepadConfiguration.h"
#import "CMJoyCaptureView.h"

static NSArray<NSString *> *_labels;

@implementation CMConfigureJoystickController
{
	NSInteger _gamepadId;
	
	CMGamepadConfiguration *_configuration;
	CMJoyCaptureView *_captureView;
}

+ (void) initialize
{
	_labels = @[ NSLocalizedString(@"Up", @"Joystick direction"),
				 NSLocalizedString(@"Down", @"Joystick direction"),
				 NSLocalizedString(@"Left", @"Joystick direction"),
				 NSLocalizedString(@"Right", @"Joystick direction"),
				 NSLocalizedString(@"Button 1", @"Joystick button"),
				 NSLocalizedString(@"Button 2", @"Joystick button") ];
}

- (instancetype) init
{
    if ((self = [super initWithWindowNibName:@"ConfigureJoystick"]))
    {
    }
    
    return self;
}

#pragma mark - NSWindowDelegate

- (void) windowDidLoad
{
}

- (void) windowDidBecomeKey:(NSNotification *) notification
{
    NSLog(@"CMConfigureJoystick: Starting gamepad observation ...");
    [[CMGamepadManager sharedInstance] addObserver:self];
}

- (void) windowDidResignKey:(NSNotification *) notification
{
    NSLog(@"CMConfigureJoystick: Stopping gamepad observation ...");
    [[CMGamepadManager sharedInstance] removeObserver:self];
}

- (id) windowWillReturnFieldEditor:(NSWindow *) sender
						  toObject:(id) anObject
{
	if (!_captureView) {
		_captureView = [[CMJoyCaptureView alloc] init];
	}
	
	return _captureView;
}

#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *) tableView
{
	return [_labels count];
}

- (id) tableView:(NSTableView *) tableView
objectValueForTableColumn:(NSTableColumn *) tableColumn
			 row:(NSInteger) row
{
	if ([[tableColumn identifier] isEqualToString:@"virtual"]) {
		return [_labels objectAtIndex:row];
	} else if ([[tableColumn identifier] isEqualToString:@"physical"]) {
		switch (row) {
			case 0:
				return [CMJoyCaptureView descriptionForCode:[_configuration up]];
			case 1:
				return [CMJoyCaptureView descriptionForCode:[_configuration down]];
			case 2:
				return [CMJoyCaptureView descriptionForCode:[_configuration left]];
			case 3:
				return [CMJoyCaptureView descriptionForCode:[_configuration right]];
			case 4:
				return [CMJoyCaptureView descriptionForCode:[_configuration buttonA]];
			case 5:
				return [CMJoyCaptureView descriptionForCode:[_configuration buttonB]];
		}
	}
	
	return nil;
}

- (void) tableView:(NSTableView *) tableView
	setObjectValue:(id) object
	forTableColumn:(NSTableColumn *) tableColumn
			   row:(NSInteger) row
{
	if ([[tableColumn identifier] isEqualToString:@"physical"]) {
		NSNumber *code = [CMJoyCaptureView codeForDescription:(NSString *) object];
		switch (row) {
			case 0:
				[_configuration setUp:[code integerValue]];
				break;
			case 1:
				[_configuration setDown:[code integerValue]];
				break;
			case 2:
				[_configuration setLeft:[code integerValue]];
				break;
			case 3:
				[_configuration setRight:[code integerValue]];
				break;
			case 4:
				[_configuration setButtonA:[code integerValue]];
				break;
			case 5:
				[_configuration setButtonB:[code integerValue]];
				break;
		}
	}
}

#pragma mark - CMGamepadDelegate

- (void)gamepadDidDisconnect:(CMGamepad *) gamepad
{
    if ([gamepad gamepadId] == _gamepadId)
    {
    }
}

- (void) gamepad:(CMGamepad *) gamepad
		xChanged:(NSInteger) newValue
		  center:(NSInteger) center
	   eventData:(CMGamepadEventData *) eventData
{
	if ([gamepad gamepadId] == _gamepadId) {
		if ([[self window] firstResponder] == _captureView) {
			if (newValue < center) {
				[_captureView captureCode:CMMakeAnalog(CM_DIR_LEFT)];
			} else if (newValue > center) {
				[_captureView captureCode:CMMakeAnalog(CM_DIR_RIGHT)];
			}
		}
	}
}

- (void) gamepad:(CMGamepad *) gamepad
		yChanged:(NSInteger) newValue
		  center:(NSInteger) center
	   eventData:(CMGamepadEventData *) eventData
{
	if ([gamepad gamepadId] == _gamepadId) {
		if ([[self window] firstResponder] == _captureView) {
			if (newValue < center) {
				[_captureView captureCode:CMMakeAnalog(CM_DIR_UP)];
			} else if (newValue > center) {
				[_captureView captureCode:CMMakeAnalog(CM_DIR_DOWN)];
			}
		}
	}
}

- (void)gamepad:(CMGamepad *) gamepad
     buttonDown:(NSInteger) index
      eventData:(CMGamepadEventData *) eventData
{
    if ([gamepad gamepadId] == _gamepadId)
    {
		if ([[self window] firstResponder] == _captureView) {
			[_captureView captureCode:CMMakeButton(index)];
		}
    }
}

#pragma mark - Public

- (void) configureGamepadId:(NSInteger) gamepadId
	  existingConfiguration:(CMGamepadConfiguration *) existing
{
	_gamepadId = gamepadId;
	
	if (existing) {
		_configuration = [existing copy];
	} else {
		_configuration = [[CMGamepadConfiguration alloc] init];
	}
	
	CMGamepad *gamepad = [[CMGamepadManager sharedInstance] gamepadWithId:_gamepadId];
	[_configuration setVendorProductId:[gamepad vendorProductId]];
	
	NSString *title = [gamepad name];
	if (!title) {
		title = NSLocalizedString(@"Generic Controller", @"Default joystick name");
	}
	
	[[self window] setTitle:title];
	[tableView reloadData];
}

#pragma mark - Actions

- (void) cancelChanges:(id) sender
{
    [[self window] close];
}

- (void) saveChanges:(id) sender
{
	CMGamepad *gamepad = [[CMGamepadManager sharedInstance] gamepadWithId:_gamepadId];
	if (gamepad) {
		[_delegate gamepadDidConfigure:gamepad
						 configuration:_configuration];
	}
	
    [[self window] close];
}

- (void) resetToDefault:(id) sender
{
	[_configuration clear];
	[tableView reloadData];
}

@end
