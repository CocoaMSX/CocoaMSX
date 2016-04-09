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
#import "CMKeyCaptureView.h"

static NSArray<NSString *> *_labels;

@implementation CMConfigureJoystickController
{
	NSInteger _gamepadId;
	
	CMGamepadConfiguration *_configuration;
	CMJoyCaptureView *_joyCaptureView;
	CMKeyCaptureView *_keyCaptureView;
}

+ (void) initialize
{
	_labels = @[ NSLocalizedString(@"Up", @"MSX Joystick direction"),
				 NSLocalizedString(@"Down", @"MSX Joystick direction"),
				 NSLocalizedString(@"Left", @"MSX Joystick direction"),
				 NSLocalizedString(@"Right", @"MSX Joystick direction"),
				 NSLocalizedString(@"Button 1", @"MSX Joystick button"),
				 NSLocalizedString(@"Button 2", @"MSX Joystick button") ];
}

- (instancetype) init
{
    if ((self = [super initWithWindowNibName:@"ConfigureJoystick"])) {
    }
    
    return self;
}

#pragma mark - NSWindowDelegate

- (void) windowDidLoad
{
}

- (void) windowDidBecomeKey:(NSNotification *) notification
{
    [[CMGamepadManager sharedInstance] addObserver:self];
	[[CMKeyboardManager sharedInstance] addObserver:self];
}

- (void) windowDidResignKey:(NSNotification *) notification
{
    [[CMGamepadManager sharedInstance] removeObserver:self];
	[[CMKeyboardManager sharedInstance] removeObserver:self];
}

- (id) windowWillReturnFieldEditor:(NSWindow *) sender
						  toObject:(id) anObject
{
	if (_gamepadId == 0 || _gamepadId == 1) {
		if (!_keyCaptureView) {
			_keyCaptureView = [[CMKeyCaptureView alloc] init];
		}
		return _keyCaptureView;
	} else {
		if (!_joyCaptureView) {
			_joyCaptureView = [[CMJoyCaptureView alloc] init];
		}
		return _joyCaptureView;
	}
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
		if (_gamepadId == 0 || _gamepadId == 1) {
			switch (row) {
				case 0:
					return [CMKeyCaptureView descriptionForKeyCode:CMKeyCode([_configuration up])];
				case 1:
					return [CMKeyCaptureView descriptionForKeyCode:CMKeyCode([_configuration down])];
				case 2:
					return [CMKeyCaptureView descriptionForKeyCode:CMKeyCode([_configuration left])];
				case 3:
					return [CMKeyCaptureView descriptionForKeyCode:CMKeyCode([_configuration right])];
				case 4:
					return [CMKeyCaptureView descriptionForKeyCode:CMKeyCode([_configuration buttonA])];
				case 5:
					return [CMKeyCaptureView descriptionForKeyCode:CMKeyCode([_configuration buttonB])];
			}
		} else {
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
	}
	
	return nil;
}

- (void) tableView:(NSTableView *) tableView
	setObjectValue:(id) object
	forTableColumn:(NSTableColumn *) tableColumn
			   row:(NSInteger) row
{
	if ([[tableColumn identifier] isEqualToString:@"physical"]) {
		if (_gamepadId == 0 || _gamepadId == 1) {
			NSInteger keyCode = [CMKeyCaptureView keyCodeForDescription:(NSString *) object];
			switch (row) {
				case 0:
					[_configuration setUp:CMMakeKey(keyCode)];
					break;
				case 1:
					[_configuration setDown:CMMakeKey(keyCode)];
					break;
				case 2:
					[_configuration setLeft:CMMakeKey(keyCode)];
					break;
				case 3:
					[_configuration setRight:CMMakeKey(keyCode)];
					break;
				case 4:
					[_configuration setButtonA:CMMakeKey(keyCode)];
					break;
				case 5:
					[_configuration setButtonB:CMMakeKey(keyCode)];
					break;
			}
		} else {
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
}

#pragma mark - CMGamepadDelegate

- (void) gamepadDidDisconnect:(CMGamepad *) gamepad
{
    if ([gamepad gamepadId] == _gamepadId) {
		[[self window] close];
    }
}

- (void) gamepad:(CMGamepad *) gamepad
		xChanged:(NSInteger) newValue
		  center:(NSInteger) center
	   eventData:(CMGamepadEventData *) eventData
{
	if ([gamepad gamepadId] == _gamepadId) {
		if ([[self window] firstResponder] == _joyCaptureView) {
			if (newValue < center) {
				[_joyCaptureView captureCode:CMMakeAnalog(CM_DIR_LEFT)];
			} else if (newValue > center) {
				[_joyCaptureView captureCode:CMMakeAnalog(CM_DIR_RIGHT)];
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
		if ([[self window] firstResponder] == _joyCaptureView) {
			if (newValue < center) {
				[_joyCaptureView captureCode:CMMakeAnalog(CM_DIR_UP)];
			} else if (newValue > center) {
				[_joyCaptureView captureCode:CMMakeAnalog(CM_DIR_DOWN)];
			}
		}
	}
}

- (void) gamepad:(CMGamepad *) gamepad
	  buttonDown:(NSInteger) index
	   eventData:(CMGamepadEventData *) eventData
{
    if ([gamepad gamepadId] == _gamepadId) {
		if ([[self window] firstResponder] == _joyCaptureView) {
			[_joyCaptureView captureCode:CMMakeButton(index)];
		}
    }
}

#pragma mark - CMKeyboardEventDelegate

- (void) keyStateChanged:(CMKeyEventData *) event
				  isDown:(BOOL) isDown
{
	if ((_gamepadId == 0 || _gamepadId == 1) && [event hasKeyCodeEquivalent]) {
		// Key with a valid keyCode
		if ([[self window] firstResponder] == _keyCaptureView) {
			// keyCaptureView is in focus
			BOOL isReturn = [event keyCode] == 0x24 || [event keyCode] == 0x4c;
			if (isReturn || !isDown) {
				// A key was released while the keyCaptureView has focus
				[_keyCaptureView captureKeyCode:[event keyCode]];
			}
		}
	}
}

#pragma mark - Public

- (void) configureGamepadId:(NSInteger) gamepadId
	  existingConfiguration:(CMGamepadConfiguration *) existing
{
	_gamepadId = gamepadId;
	CMGamepad *gamepad = nil;
	if (_gamepadId != 0 && gamepadId != 1) {
		gamepad = [[CMGamepadManager sharedInstance] gamepadWithId:_gamepadId];
	}
	
	if (existing) {
		_configuration = [existing copy];
	} else {
		_configuration = [[CMGamepadConfiguration alloc] init];
		if (_gamepadId == 0) {
			[_configuration setVendorProductId:CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_1];
			[_configuration reset];
		} else if (_gamepadId == 1) {
			[_configuration setVendorProductId:CM_VENDOR_PRODUCT_KEYBOARD_PLAYER_2];
			[_configuration reset];
		} else {
			[_configuration setVendorProductId:[gamepad vendorProductId]];
			[_configuration reset];
		}
	}
	
	NSString *title = nil;
	NSString *info = nil;
	
	if (_gamepadId == 0) {
		title = NSLocalizedString(@"Keyboard Player 1", @"Configuration window title");
		info = NSLocalizedString(@"Currently editing input for Player 1 via Keyboard", @"Joystick config directions");
	} else if (_gamepadId == 1) {
		title = NSLocalizedString(@"Keyboard Player 2", @"Configuration window title");
		info = NSLocalizedString(@"Currently editing input for Player 2 via Keyboard", @"Joystick config directions");
	} else {
		if (!(title = [gamepad name])) {
			title = NSLocalizedString(@"Generic Controller", @"Configuration window title");
		}
		info = [NSString stringWithFormat:NSLocalizedString(@"Currently editing input via %@", @"Joystick config directions"), title];
	}
	
	[[self window] setTitle:title];
	[infoLabel setStringValue:info];
	
	[tableView reloadData];
}

#pragma mark - Actions

- (void) cancelChanges:(id) sender
{
    [[self window] close];
}

- (void) saveChanges:(id) sender
{
	[_delegate gamepadConfigurationDidComplete:_configuration];
	
    [[self window] close];
}

- (void) resetToDefault:(id) sender
{
	[_configuration reset];
	[tableView reloadData];
}

@end
