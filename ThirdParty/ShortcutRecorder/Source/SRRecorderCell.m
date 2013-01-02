//
//  SRRecorderCell.m
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import "SRRecorderCell.h"
#import "SRRecorderControl.h"
#import "SRKeyCodeTransformer.h"
#import "SRValidator.h"

@interface SRRecorderCell (Private)
- (void)_privateInit;
- (void)_createGradient;
- (void)_setJustChanged;
- (void)_startRecordingTransition;
- (void)_endRecordingTransition;
- (void)_transitionTick;
- (void)_startRecording;
- (void)_endRecording;

- (BOOL)_effectiveIsAnimating;

- (NSRect)_removeButtonRectForFrame:(NSRect)cellFrame;

- (NSUInteger)_filteredCocoaFlags:(NSUInteger)flags;
- (NSUInteger)_filteredCocoaToCarbonFlags:(NSUInteger)cocoaFlags;
- (BOOL)_validModifierFlags:(NSUInteger)flags;

- (BOOL)_isEmpty;
@end

#pragma mark -

@implementation SRRecorderCell

- (id)init
{
    self = [super init];
	
	[self _privateInit];
	
    return self;
}

- (void)dealloc
{
    [validator release];
	
	[keyCharsIgnoringModifiers release];
	[keyChars release];
    
	[recordingGradient release];
	
	[cancelCharacterSet release];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[super dealloc];
}

#pragma mark *** Coding Support ***

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	
	[self _privateInit];

    keyCombo.code = [[aDecoder decodeObjectForKey: @"keyComboCode"] shortValue];
    keyCombo.flags = [[aDecoder decodeObjectForKey: @"keyComboFlags"] unsignedIntegerValue];
    
    if ([aDecoder containsValueForKey:@"keyChars"]) {
        hasKeyChars = YES;
        keyChars = (NSString *)[aDecoder decodeObjectForKey: @"keyChars"];
        keyCharsIgnoringModifiers = (NSString *)[aDecoder decodeObjectForKey: @"keyCharsIgnoringModifiers"];
    }

    allowedFlags = [[aDecoder decodeObjectForKey: @"allowedFlags"] unsignedIntegerValue];
    requiredFlags = [[aDecoder decodeObjectForKey: @"requiredFlags"] unsignedIntegerValue];
    
    allowsKeyOnly = [[aDecoder decodeObjectForKey:@"allowsKeyOnly"] boolValue];
    escapeKeysRecord = [[aDecoder decodeObjectForKey:@"escapeKeysRecord"] boolValue];
    isAnimating = [[aDecoder decodeObjectForKey:@"isAnimating"] boolValue];
    
    useSingleKeyMode = [[aDecoder decodeObjectForKey:@"useSingleKeyMode"] boolValue];
    tableCellMode = [[aDecoder decodeObjectForKey:@"tableCellMode"] boolValue];
    isRowSelected = [[aDecoder decodeObjectForKey:@"isRowSelected"] boolValue];
	
	allowedFlags |= NSFunctionKeyMask;

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder: aCoder];
	
    [aCoder encodeObject:[NSNumber numberWithShort: keyCombo.code] forKey:@"keyComboCode"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:keyCombo.flags] forKey:@"keyComboFlags"];

    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:allowedFlags] forKey:@"allowedFlags"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:requiredFlags] forKey:@"requiredFlags"];
    
    if (hasKeyChars) {
        [aCoder encodeObject:keyChars forKey:@"keyChars"];
        [aCoder encodeObject:keyCharsIgnoringModifiers forKey:@"keyCharsIgnoringModifiers"];
    }
    
    [aCoder encodeObject:[NSNumber numberWithBool: allowsKeyOnly] forKey:@"allowsKeyOnly"];
    [aCoder encodeObject:[NSNumber numberWithBool: escapeKeysRecord] forKey:@"escapeKeysRecord"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:isAnimating] forKey:@"isAnimating"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:useSingleKeyMode] forKey:@"useSingleKeyMode"];
    [aCoder encodeObject:[NSNumber numberWithBool:tableCellMode] forKey:@"tableCellMode"];
    [aCoder encodeObject:[NSNumber numberWithBool:isRowSelected] forKey:@"isRowSelected"];
}

- (id)copyWithZone:(NSZone *)zone
{
    SRRecorderCell *cell;
    cell = (SRRecorderCell *)[super copyWithZone: zone];
	
	cell->recordingGradient = [recordingGradient retain];
    
	cell->isRecording = isRecording;
	cell->mouseInsideRemoveTrackingArea = mouseInsideRemoveTrackingArea;
	cell->mouseDown = mouseDown;

	cell->removeTrackingRectTag = removeTrackingRectTag;

	cell->keyCombo = keyCombo;

	cell->allowedFlags = allowedFlags;
	cell->requiredFlags = requiredFlags;
	cell->recordingFlags = recordingFlags;
	
	cell->allowsKeyOnly = allowsKeyOnly;
	cell->escapeKeysRecord = escapeKeysRecord;
	
	cell->isAnimating = isAnimating;
	
	cell->cancelCharacterSet = [cancelCharacterSet retain];
    
	cell->delegate = delegate;
	
	cell->useSingleKeyMode = useSingleKeyMode;
	cell->tableCellMode = tableCellMode;
	cell->isRowSelected = isRowSelected;
    
    return cell;
}

#pragma mark *** Drawing ***

- (BOOL)animates {
	return isAnimating;
}

- (void)setAnimates:(BOOL)an {
	isAnimating = an;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	CGFloat radius = 0;

    cellFrame = NSInsetRect(cellFrame,0.5f,0.5f);
    
    NSRect whiteRect = cellFrame;
    NSBezierPath *roundedRect;
    
    BOOL isVaguelyRecording = isRecording;
    CGFloat xanim = 0.0f;
    
    if (isAnimatingNow) {
//		NSLog(@"tp: %f; xanim: %f", transitionProgress, xanim);
        xanim = (SRAnimationEaseInOut(transitionProgress));
//		NSLog(@"tp: %f; xanim: %f", transitionProgress, xanim);
    }
    
    CGFloat alphaRecording = 1.0f; CGFloat alphaView = 1.0f;
    if (isAnimatingNow && !isAnimatingTowardsRecording) { alphaRecording = 1.0f - xanim; alphaView = xanim; }
    if (isAnimatingNow && isAnimatingTowardsRecording) { alphaView = 1.0f - xanim; alphaRecording = xanim; }
    
    if (isAnimatingNow) {
        //NSLog(@"animation step: %f, effective: %f, alpha recording: %f, view: %f", transitionProgress, xanim, alphaRecording, alphaView);
    }
    
    if (isAnimatingNow && isAnimatingTowardsRecording) {
        isVaguelyRecording = YES;
    }
    
//	NSAffineTransform *transitionMovement = [NSAffineTransform transform];
    NSAffineTransform *viewportMovement = [NSAffineTransform transform];
// Draw gradient when in recording mode
    if (isVaguelyRecording)
    {
        if (isAnimatingNow) {
//			[transitionMovement translateXBy:(isAnimatingTowardsRecording ? -(NSWidth(cellFrame)*(1.0-xanim)) : +(NSWidth(cellFrame)*xanim)) yBy:0.0];
            if (SRAnimationAxisIsY) {
//				[viewportMovement translateXBy:0.0 yBy:(isAnimatingTowardsRecording ? -(NSHeight(cellFrame)*(xanim)) : -(NSHeight(cellFrame)*(1.0-xanim)))];
                [viewportMovement translateXBy:0.0f yBy:(isAnimatingTowardsRecording ? NSHeight(cellFrame)*(xanim) : NSHeight(cellFrame)*(1.0f-xanim))];
            } else {
                [viewportMovement translateXBy:(isAnimatingTowardsRecording ? -(NSWidth(cellFrame)*(xanim)) : -(NSWidth(cellFrame)*(1.0f-xanim))) yBy:0.0f];
            }
        } else {
            if (SRAnimationAxisIsY) {
                [viewportMovement translateXBy:0.0f yBy:NSHeight(cellFrame)];				
            } else {
                [viewportMovement translateXBy:-(NSWidth(cellFrame)) yBy:0.0f];
            }
        }
    }
    
    
// Draw white rounded box
    radius = NSHeight(whiteRect) / 2.0f;
    if (tableCellMode)
        roundedRect = [NSBezierPath bezierPathWithRect:whiteRect];
    else
        roundedRect = [NSBezierPath bezierPathWithRoundedRect:whiteRect xRadius:radius yRadius:radius];
    
    [[NSColor whiteColor] set];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    if (!tableCellMode || isRecording)
        [roundedRect fill];
    
    [[NSColor windowFrameColor] set];
    
    if (!tableCellMode)
        [roundedRect stroke];
    
    [roundedRect addClip];
    
    // Draw border and remove badge if needed
    /*	if (!isVaguelyRecording)
    {
        */	
    // If key combination is set and valid, draw remove image
    if (isVaguelyRecording && ![self _isEmpty] && [self isEnabled])
    {
        NSRect removeRect = SRAnimationOffsetRect([self _removeButtonRectForFrame:cellFrame], cellFrame);
        NSPoint correctedRemoveOrigin = [viewportMovement transformPoint:removeRect.origin];
        
        NSRect correctedRemoveRect = removeRect;
        correctedRemoveRect.size.height = NSHeight(whiteRect);
        correctedRemoveRect.size.width *= 1.3f;
        correctedRemoveRect.origin.y -= 5.0f;
        correctedRemoveRect.origin.x -= 1.5f;
        
        correctedRemoveOrigin.x -= 0.5f;
        
        correctedRemoveRect.origin = [viewportMovement transformPoint:removeRect.origin];
        
        NSString *removeImageName = [NSString stringWithFormat: @"SRRemoveShortcut%@", (mouseInsideRemoveTrackingArea ? (mouseDown ? @"Pressed" : @"Rollover") : (mouseDown ? @"Rollover" : @""))];
        
        NSImage *removeImage = [NSImage imageNamed:removeImageName];
        [removeImage drawAtPoint:correctedRemoveRect.origin
                        fromRect:NSZeroRect
                       operation:NSCompositeSourceOver
                        fraction:1.0f * alphaRecording];

//NSLog(@"drew removeImage with alpha %f", alphaView);
    }
//	}
    
    
    
// Draw text
    NSMutableParagraphStyle *mpstyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [mpstyle setLineBreakMode: NSLineBreakByTruncatingTail];
    [mpstyle setAlignment: NSCenterTextAlignment];
    
    CGFloat alphaCombo = alphaView;
    CGFloat alphaRecordingText = alphaRecording;
    if (comboJustChanged) {
        alphaCombo = 1.0f;
        alphaRecordingText = 0.0f;//(alphaRecordingText/2.0);
    }
    
    
    NSString *displayString;
    
    {
// Only the KeyCombo should be black and in a bigger font size
        BOOL recordingOrEmpty = (isVaguelyRecording || [self _isEmpty]);
        
        NSColor *textColor;
        if (!recordingOrEmpty)
            textColor = [NSColor textColor];
        else
            textColor = [NSColor disabledControlTextColor];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: mpstyle, NSParagraphStyleAttributeName,
            [NSFont systemFontOfSize:11.0], NSFontAttributeName,
            [textColor colorWithAlphaComponent:alphaRecordingText], NSForegroundColorAttributeName,
            nil];
    // Recording, but no modifier keys down
        if (![self _validModifierFlags: recordingFlags])
        {
            // Mouse elsewhere
            displayString = SRLoc(@"...");
        }
        else
        {
            if (useSingleKeyMode && self.keyComboString)
                displayString = self.keyComboString;
            else

        // Display currently pressed modifier keys
            displayString = SRStringForCocoaModifierFlags( recordingFlags );
        
        // Fall back on 'Type shortcut' if we don't have modifier flags to display; this will happen for the fn key depressed
            if (![displayString length])
            {
                displayString = SRLoc(@"...");
            }
        }
// Calculate rect in which to draw the text in...
        NSRect textRect = SRAnimationOffsetRect(cellFrame,cellFrame);
        //NSLog(@"draw record text in rect (preadjusted): %@", NSStringFromRect(textRect));
        textRect.origin = [viewportMovement transformPoint:textRect.origin];
        //NSLog(@"draw record text in rect: %@", NSStringFromRect(textRect));
        
        
        
// Finally draw it
        [displayString drawInRect:textRect withAttributes:attributes];
    }
    
    
    {
// Only the KeyCombo should be black and in a bigger font size
        NSFont *font = [NSFont systemFontOfSize:11.0];
        
        NSColor *color;
        if (tableCellMode && isRowSelected)
            color = [NSColor controlHighlightColor];
        else if ([self _isEmpty])
            color = [NSColor disabledControlTextColor];
        else
            color = [NSColor textColor];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    mpstyle, NSParagraphStyleAttributeName,
                                    font, NSFontAttributeName,
                                    [color colorWithAlphaComponent:alphaCombo], NSForegroundColorAttributeName,
                                    nil];
    // Not recording...
        if ([self _isEmpty])
        {
            if (!tableCellMode)
                displayString = SRLoc(@"Click to record shortcut");
            else
                displayString = @"";
        }
        else
        {
        // Display current key combination
            displayString = [self keyComboString];
        }
// Calculate rect in which to draw the text in...
        NSRect textRect = cellFrame;
        /*		textRect.size.width -= 6;
        textRect.size.width -= (([self _removeButtonRectForFrame: cellFrame].size.width) + 6);
//		textRect.origin.x += 6;*/
//NSFont *f = [attributes objectForKey:NSFontAttributeName];
//double lineHeight = [[[NSLayoutManager alloc] init] defaultLineHeightForFont:f];
//		textRect.size.height = lineHeight;
        if (!comboJustChanged) {
            //NSLog(@"draw view text in rect (pre-adjusted): %@", NSStringFromRect(textRect));
            textRect.origin = [viewportMovement transformPoint:textRect.origin];
        }
        textRect.origin.y = NSMinY(textRect);// - ((lineHeight/2.0)+([f descender]/2.0));
            
            //NSLog(@"draw view text in rect: %@", NSStringFromRect(textRect));
            
// Finally draw it
            [displayString drawInRect:textRect withAttributes:attributes];
    }
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
// draw a focus ring...?
    
    if ([self showsFirstResponder] && (!tableCellMode || isRecording))
    {
        if (tableCellMode)
        {
            [NSGraphicsContext saveGraphicsState];
            NSSetFocusRingStyle(NSFocusRingOnly);
            [[NSBezierPath bezierPathWithRect:cellFrame] fill];
            [NSGraphicsContext restoreGraphicsState];
        }
        else
        {
            [NSGraphicsContext saveGraphicsState];
            NSSetFocusRingStyle(NSFocusRingOnly);
            radius = NSHeight(cellFrame) / 2.0f;
            [[NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:radius yRadius:radius] fill];
            [NSGraphicsContext restoreGraphicsState];
        }
    }
}

#pragma mark *** Mouse Tracking ***

- (void)resetTrackingRects
{	
	SRRecorderControl *controlView = (SRRecorderControl *)[self controlView];
	NSRect cellFrame = [controlView bounds];
	NSPoint mouseLocation = [controlView convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];

	// We're not to be tracked if we're not enabled
	if (![self isEnabled])
	{
		if (removeTrackingRectTag != 0)
            [controlView removeTrackingRect: removeTrackingRectTag];
		
		return;
	}
	
	// We're either in recording or normal display mode
	if (!isRecording)
	{
		// Create and register tracking rect for the remove badge if shortcut is not empty
		NSRect removeButtonRect = [self _removeButtonRectForFrame: cellFrame];
		BOOL mouseInsideRemove = [controlView mouse:mouseLocation
                                             inRect:removeButtonRect];
		
		if (removeTrackingRectTag != 0)
            [controlView removeTrackingRect: removeTrackingRectTag];
        
		removeTrackingRectTag = [controlView addTrackingRect:removeButtonRect
                                                       owner:self
                                                    userData:nil
                                                assumeInside:mouseInsideRemove];
		
		if (mouseInsideRemoveTrackingArea != mouseInsideRemove)
            mouseInsideRemoveTrackingArea = mouseInsideRemove;
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSView *view = [self controlView];

	if ([[view window] isKeyWindow] || [view acceptsFirstMouse: theEvent])
	{
		mouseInsideRemoveTrackingArea = YES;
		[view display];
	}
}

- (void)mouseExited:(NSEvent*)theEvent
{
	NSView *view = [self controlView];
	
	if ([[view window] isKeyWindow] || [view acceptsFirstMouse: theEvent])
	{
		mouseInsideRemoveTrackingArea = NO;
		[view display];
	}
}

- (BOOL)trackMouse:(NSEvent *)theEvent
            inRect:(NSRect)cellFrame
            ofView:(SRRecorderControl *)controlView
      untilMouseUp:(BOOL)flag
{
	NSEvent *currentEvent = theEvent;
	NSPoint mouseLocation;
	
	NSRect removeTrackingRect = [self _removeButtonRectForFrame:cellFrame];
    
//	NSRect trackingRect = (isRecording ? [self _snapbackRectForFrame: cellFrame] : [self _removeButtonRectForFrame: cellFrame]);
	NSRect leftRect = cellFrame;
    
	// Determine the area without any badge
	if (isRecording && !NSEqualRects(removeTrackingRect, NSZeroRect))
        leftRect.size.width -= NSWidth(removeTrackingRect) + 4;
    
	do {
        mouseLocation = [controlView convertPoint: [currentEvent locationInWindow] fromView:nil];
		
		switch ([currentEvent type])
		{
			case NSLeftMouseDown:
			{
				// Check if mouse is over remove/snapback image
				if ([controlView mouse:mouseLocation inRect:removeTrackingRect])
				{
					mouseDown = YES;
					[controlView setNeedsDisplayInRect:cellFrame];
				}
				
				break;
			}
			case NSLeftMouseDragged:
			{
				// Recheck if mouse is still over the image while dragging
				mouseInsideRemoveTrackingArea = [controlView mouse:mouseLocation
                                                            inRect:removeTrackingRect];
				[controlView setNeedsDisplayInRect: cellFrame];
				
				break;
			}
			default: // NSLeftMouseUp
			{
				mouseDown = NO;
				mouseInsideRemoveTrackingArea = [controlView mouse:mouseLocation
                                                            inRect:removeTrackingRect];
                
				if (mouseInsideRemoveTrackingArea && isRecording)
				{
                    // Mouse was over the remove image, reset all
                    [self setKeyCombo:SRMakeKeyCombo(ShortcutRecorderEmptyCode, ShortcutRecorderEmptyFlags)];
                    
                    [self _endRecordingTransition];
				}
				else if ([controlView mouse:mouseLocation inRect:leftRect] && !isRecording)
				{
					if (self.isEnabled)
					{
                        if (!tableCellMode || theEvent.clickCount > 1)
                        {
                            [self _startRecordingTransition];
                        }
                        else if (tableCellMode)
                        {
                            // Looks like the first click - select the appropriate
                            // row in the NSTableView
                            
                            id tableView = [[[self.controlView superview] superview] superview];
                            if ([tableView isKindOfClass:NSTableView.class])
                            {
                                NSPoint mouseRelativeToTableView = [tableView convertPoint:[theEvent locationInWindow] fromView:nil];
                                
                                NSInteger row = [tableView rowAtPoint:mouseRelativeToTableView];
                                
                                [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                       byExtendingSelection:NO];
                            }
                        }
					}
                    
					/* maybe beep if not editable?
					 else
					{
						NSBeep();
					}
					 */
				}
				
				// Any click inside will make us firstResponder
				if ([self isEnabled])
                    [[controlView window] makeFirstResponder: controlView];

				// Reset tracking rects and redisplay
				[self resetTrackingRects];
				[controlView setNeedsDisplayInRect: cellFrame];
				
				return YES;
			}
		}
		
    } while ((currentEvent = [[controlView window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)
                                                               untilDate:[NSDate distantFuture]
                                                                  inMode:NSEventTrackingRunLoopMode
                                                                 dequeue:YES]));
	
    return YES;
}

#pragma mark *** Delegate ***

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

#pragma mark *** Responder Control ***

- (BOOL)becomeFirstResponder;
{
    // reset tracking rects and redisplay
    [self resetTrackingRects];
    
    // AK: For some reason, the next line causes the table to render nothing but
    // the focused cell when switching Preferences tabs. Disabling seems
    // to not cause any issues
    
    // [[self controlView] display];
    
    return YES;
}

- (BOOL)resignFirstResponder;
{
	if (isRecording) {
		[self _endRecordingTransition];
	}
    
    [self resetTrackingRects];
    
    // AK: See comment in becomeFirstResponder
    // [[self controlView] display];
    
    return YES;
}

#pragma mark *** Key Combination Control ***

- (BOOL) performKeyEquivalent:(NSEvent *)theEvent
{
	NSUInteger flags = [self _filteredCocoaFlags: [theEvent modifierFlags]];
	NSNumber *keyCodeNumber = [NSNumber numberWithUnsignedShort: [theEvent keyCode]];
	BOOL snapback = [cancelCharacterSet containsObject: keyCodeNumber];
	BOOL validModifiers = [self _validModifierFlags: (snapback) ? [theEvent modifierFlags] : flags]; // Snapback key shouldn't interfer with required flags!
    
    // Special case for the space key when we aren't recording...
    if (!isRecording && [[theEvent characters] isEqualToString:@" "]) {
        [self _startRecordingTransition];
        return YES;
    }
	
	// Do something as long as we're in recording mode and a modifier key or cancel key is pressed
	if (isRecording && (validModifiers || snapback)) {
		if (!snapback || validModifiers) {
			BOOL goAhead = YES;
			
			// Special case: if a snapback key has been entered AND modifiers are deemed valid...
			if (snapback && validModifiers) {
				// ...AND we're set to allow plain keys
				if (allowsKeyOnly) {
					// ...AND modifiers are empty, or empty save for the Function key
					// (needed, since forward delete is fn+delete on laptops)
					if (flags == ShortcutRecorderEmptyFlags || flags == (ShortcutRecorderEmptyFlags | NSFunctionKeyMask)) {
						// ...check for behavior in escapeKeysRecord.
						if (!escapeKeysRecord) {
							goAhead = NO;
						}
					}
				}
			}
			
			if (goAhead) {
				
				NSString *character = [[theEvent charactersIgnoringModifiers] uppercaseString];
				
			// accents like "¬¥" or "`" will be ignored since we don't get a keycode
				if ([character length]) {
					NSError *error = nil;
					
				// Check if key combination is already used or not allowed by the delegate
					if ( [validator isKeyCode:[theEvent keyCode] 
								andFlagsTaken:[self _filteredCocoaToCarbonFlags:flags]
										error:&error] ) {
                    // display the error...
						NSAlert *alert = [NSAlert alertWithError:error];
						[alert setAlertStyle:NSCriticalAlertStyle];
						[alert runModal];
						
					// Recheck pressed modifier keys
						[self flagsChanged: [NSApp currentEvent]];
						
						return YES;
					} else {
					// All ok, set new combination
						keyCombo.flags = flags;
						keyCombo.code = [theEvent keyCode];
						
						hasKeyChars = YES;
						keyChars = [[theEvent characters] retain];
						keyCharsIgnoringModifiers = [[theEvent charactersIgnoringModifiers] retain];
//						NSLog(@"keychars: %@, ignoringmods: %@", keyChars, keyCharsIgnoringModifiers);
//						NSLog(@"calculated keychars: %@, ignoring: %@", SRStringForKeyCode(keyCombo.code), SRCharacterForKeyCodeAndCocoaFlags(keyCombo.code,keyCombo.flags));
						
					// Notify delegate
						if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
							[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
						
					// Save if needed
						[self _setJustChanged];
					}
				} else {
				// invalid character
					NSBeep();
				}
			}
		}
		
		// reset values and redisplay
		recordingFlags = ShortcutRecorderEmptyFlags;
        
        [self _endRecordingTransition];
		
		[self resetTrackingRects];
		[[self controlView] display];
		
		return YES;
	} else {
		//Start recording when the spacebar is pressed while the control is first responder
		if (([[[self controlView] window] firstResponder] == [self controlView]) &&
			([[theEvent characters] length] && [[theEvent characters] characterAtIndex:0] == 32) &&
			([self isEnabled]))
		{
			[self _startRecordingTransition];
		}
	}
	
	return NO;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	if (isRecording)
	{
		recordingFlags = [self _filteredCocoaFlags: [theEvent modifierFlags]];
        
        if (useSingleKeyMode) {
            BOOL validCombo = NO;
            if (theEvent.keyCode != kSRKeysFunction
                && theEvent.keyCode != kSRKeysLeftCommand
                && theEvent.keyCode != kSRKeysRightCommand)
            {
                keyCombo.flags = ShortcutRecorderEmptyFlags;
                keyCombo.code = theEvent.keyCode;
                validCombo = YES;
            }
            
            if (validCombo) {
                if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
                    [delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
                
                [self _setJustChanged];
                [self _endRecordingTransition];
                [self resetTrackingRects];
            }
        }
        
		[[self controlView] display];
	}
}

#pragma mark -

- (NSUInteger)allowedFlags
{
	return allowedFlags;
}

- (void)setAllowedFlags:(NSUInteger)flags
{
	allowedFlags = flags;
	
	// filter new flags and change keycombo if not recording
	if (isRecording)
	{
		recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];;
	}
	else
	{
		NSUInteger originalFlags = keyCombo.flags;
		keyCombo.flags = [self _filteredCocoaFlags: keyCombo.flags];
		
		if (keyCombo.flags != originalFlags && keyCombo.code > ShortcutRecorderEmptyCode)
		{
			// Notify delegate if keyCombo changed
			if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
				[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
		}
	}
	
	[[self controlView] display];
}

- (BOOL)allowsKeyOnly {
	return allowsKeyOnly;
}

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly {
	allowsKeyOnly = nAllowsKeyOnly;
}

- (BOOL)escapeKeysRecord {
	return escapeKeysRecord;
}

- (void)setEscapeKeysRecord:(BOOL)nEscapeKeysRecord {
	escapeKeysRecord = nEscapeKeysRecord;
}

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord {
	allowsKeyOnly = nAllowsKeyOnly;
	escapeKeysRecord = nEscapeKeysRecord;
}

- (BOOL)useSingleKeyMode {
    return useSingleKeyMode;
}

- (void)setUseSingleKeyMode:(BOOL)singleKey {
    useSingleKeyMode = singleKey;
}

- (BOOL)tableCellMode {
    return tableCellMode;
}

- (void)setTableCellMode:(BOOL)mode {
    tableCellMode = mode;
}

- (NSUInteger)requiredFlags
{
	return requiredFlags;
}

- (void)setRequiredFlags:(NSUInteger)flags
{
	requiredFlags = flags;
	
	// filter new flags and change keycombo if not recording
	if (isRecording)
	{
		recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];
	}
	else
	{
		NSUInteger originalFlags = keyCombo.flags;
		keyCombo.flags = [self _filteredCocoaFlags: keyCombo.flags];
		
		if (keyCombo.flags != originalFlags && keyCombo.code > ShortcutRecorderEmptyCode)
		{
			// Notify delegate if keyCombo changed
			if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
				[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
		}
	}
	
	[[self controlView] display];
}

- (KeyCombo)keyCombo
{
	return keyCombo;
}

- (void)setKeyCombo:(KeyCombo)aKeyCombo
{
	keyCombo = aKeyCombo;
	keyCombo.flags = [self _filteredCocoaFlags: aKeyCombo.flags];
	
	hasKeyChars = NO;

	// Notify delegate
	if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
		[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
	
	[[self controlView] display];
}

- (BOOL)canCaptureGlobalHotKeys
{
	return globalHotKeys;
}

- (void)setCanCaptureGlobalHotKeys:(BOOL)inState
{
	globalHotKeys = inState;
}

#pragma mark -

- (NSString *)keyComboString
{
	if ([self _isEmpty]) return nil;
	
    if (useSingleKeyMode) {
        if (keyCombo.flags != ShortcutRecorderEmptyFlags)
            return SRStringForCocoaModifierFlags( keyCombo.flags );
        if (keyCombo.code != ShortcutRecorderEmptyCode)
            return SRStringForKeyCode( keyCombo.code );
    }
    
    return [NSString stringWithFormat: @"%@%@",
            SRStringForCocoaModifierFlags( keyCombo.flags ),
            SRStringForKeyCode( keyCombo.code )];
}

- (NSString *)keyChars {
	if (!hasKeyChars) return SRStringForKeyCode(keyCombo.code);
	return keyChars;
}

- (NSString *)keyCharsIgnoringModifiers {
	if (!hasKeyChars) return SRCharacterForKeyCodeAndCocoaFlags(keyCombo.code,keyCombo.flags);
	return keyCharsIgnoringModifiers;
}

@end

#pragma mark -

@implementation SRRecorderCell (Private)

- (void)_privateInit
{
    // init the validator object...
    validator = [[SRValidator alloc] initWithDelegate:self];
    
	// Allow all modifier keys by default, nothing is required
	allowedFlags = ShortcutRecorderAllFlags;
	requiredFlags = ShortcutRecorderEmptyFlags;
	recordingFlags = ShortcutRecorderEmptyFlags;
	
	// Create clean KeyCombo
	keyCombo.flags = ShortcutRecorderEmptyFlags;
	keyCombo.code = ShortcutRecorderEmptyCode;
	
	keyChars = nil;
	keyCharsIgnoringModifiers = nil;
	hasKeyChars = NO;
    useSingleKeyMode = NO;
	
	// These keys will cancel the recoding mode if not pressed with any modifier
	cancelCharacterSet = [[NSSet alloc] initWithObjects: [NSNumber numberWithInteger:ShortcutRecorderEscapeKey],
		[NSNumber numberWithInteger:ShortcutRecorderBackspaceKey], [NSNumber numberWithInteger:ShortcutRecorderDeleteKey], nil];
		
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(_createGradient) name:NSSystemColorsDidChangeNotification object:nil]; // recreate gradient if needed
	[self _createGradient];
}

- (void)_createGradient
{
	NSColor *gradientStartColor = [[[NSColor alternateSelectedControlColor] shadowWithLevel: 0.2f] colorWithAlphaComponent: 0.9f];
	NSColor *gradientEndColor = [[[NSColor alternateSelectedControlColor] highlightWithLevel: 0.2f] colorWithAlphaComponent: 0.9f];
	
	recordingGradient = [[NSGradient alloc] initWithStartingColor:gradientStartColor endingColor:gradientEndColor];
}

- (void)_setJustChanged {
	comboJustChanged = YES;
}

- (BOOL)_effectiveIsAnimating {
	return isAnimating;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)bgStyle
{
    [super setBackgroundStyle:bgStyle];
    
    switch (bgStyle)
    {
    case NSBackgroundStyleDark:
        isRowSelected = YES;
        break;
    default:
    case NSBackgroundStyleLight:
        isRowSelected = NO;
        break;
    }
}

- (void)_startRecordingTransition {
	if ([self _effectiveIsAnimating]) {
		isAnimatingTowardsRecording = YES;
		isAnimatingNow = YES;
		transitionProgress = 0.0f;
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_transitionTick) object:nil];
		[self performSelector:@selector(_transitionTick) withObject:nil afterDelay:(SRTransitionDuration/SRTransitionFrames)];
//	NSLog(@"start recording-transition");
	} else {
		[self _startRecording];
	}
}

- (void)_endRecordingTransition {
	if ([self _effectiveIsAnimating]) {
		isAnimatingTowardsRecording = NO;
		isAnimatingNow = YES;
		transitionProgress = 0.0f;
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_transitionTick) object:nil];
		[self performSelector:@selector(_transitionTick) withObject:nil afterDelay:(SRTransitionDuration/SRTransitionFrames)];
//	NSLog(@"end recording-transition");
	} else {
		[self _endRecording];
	}
}

- (void)_transitionTick {
	transitionProgress += (1.0f/SRTransitionFrames);
//	NSLog(@"transition tick: %f", transitionProgress);
	if (transitionProgress >= 0.998f) {
//		NSLog(@"transition deemed complete");
		isAnimatingNow = NO;
		transitionProgress = 0.0f;
		if (isAnimatingTowardsRecording) {
			[self _startRecording];
		} else {
			[self _endRecording];
		}
	} else {
//		NSLog(@"more to do");
		[[self controlView] setNeedsDisplay:YES];
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_transitionTick) object:nil];
		[self performSelector:@selector(_transitionTick) withObject:nil afterDelay:(SRTransitionDuration/SRTransitionFrames)];
	}
}

- (void)_startRecording;
{
    // Jump into recording mode if mouse was inside the control but not over any image
    isRecording = YES;
    
    // Reset recording flags and determine which are required
    recordingFlags = [self _filteredCocoaFlags:ShortcutRecorderEmptyFlags];
    
/*	[self setFocusRingType:NSFocusRingTypeNone];
	[[self controlView] setFocusRingType:NSFocusRingTypeNone];*/	
	[[self controlView] setNeedsDisplay:YES];
	
    // invalidate the focus ring rect...
    NSView *controlView = [self controlView];
    [controlView setKeyboardFocusRingNeedsDisplayInRect:[controlView bounds]];
    
    if (globalHotKeys)
        hotKeyModeToken = PushSymbolicHotKeyMode(kHIHotKeyModeAllDisabled);
}

- (void)_endRecording;
{
    isRecording = NO;
	comboJustChanged = NO;

/*	[self setFocusRingType:NSFocusRingTypeNone];
	[[self controlView] setFocusRingType:NSFocusRingTypeNone];*/	
	[[self controlView] setNeedsDisplay:YES];
	
    // invalidate the focus ring rect...
    NSView *controlView = [self controlView];
    [controlView setKeyboardFocusRingNeedsDisplayInRect:[controlView bounds]];
	
	if (globalHotKeys) PopSymbolicHotKeyMode(hotKeyModeToken);
}

#pragma mark *** Drawing Helpers ***

- (NSRect)_removeButtonRectForFrame:(NSRect)cellFrame
{	
	if ([self _isEmpty] || ![self isEnabled])
        return NSZeroRect;
	
	NSRect removeButtonRect;
	NSImage *removeImage = [NSImage imageNamed:@"SRRemoveShortcut"];
	
    CGFloat x = NSMaxX(cellFrame) - [removeImage size].width - 4;
    CGFloat y = (NSMaxY(cellFrame) - [removeImage size].height) / 2;
    
	removeButtonRect.origin = NSMakePoint(x, y);
	removeButtonRect.size = [removeImage size];
    
	return removeButtonRect;
}

#pragma mark *** Filters ***

- (NSUInteger)_filteredCocoaFlags:(NSUInteger)flags
{
	NSUInteger filteredFlags = ShortcutRecorderEmptyFlags;
	NSUInteger a = allowedFlags;
	NSUInteger m = requiredFlags;

	if (m & NSCommandKeyMask) filteredFlags |= NSCommandKeyMask;
	else if ((flags & NSCommandKeyMask) && (a & NSCommandKeyMask)) filteredFlags |= NSCommandKeyMask;
	
    if (useSingleKeyMode && ((filteredFlags & NSCommandKeyMask) == NSCommandKeyMask))
        filteredFlags |= (flags & 0x18);
    
	if (m & NSAlternateKeyMask) filteredFlags |= NSAlternateKeyMask;
	else if ((flags & NSAlternateKeyMask) && (a & NSAlternateKeyMask)) filteredFlags |= NSAlternateKeyMask;
	
    if (useSingleKeyMode && ((filteredFlags & NSAlternateKeyMask) == NSAlternateKeyMask))
        filteredFlags |= (flags & 0x60);
    
	if ((m & NSControlKeyMask)) filteredFlags |= NSControlKeyMask;
	else if ((flags & NSControlKeyMask) && (a & NSControlKeyMask)) filteredFlags |= NSControlKeyMask;
	
    if (useSingleKeyMode && ((filteredFlags & NSControlKeyMask) == NSControlKeyMask))
        filteredFlags |= (flags & 0x2001);
    
	if ((m & NSShiftKeyMask)) filteredFlags |= NSShiftKeyMask;
	else if ((flags & NSShiftKeyMask) && (a & NSShiftKeyMask)) filteredFlags |= NSShiftKeyMask;
	
    if (useSingleKeyMode && ((filteredFlags & NSShiftKeyMask) == NSShiftKeyMask))
        filteredFlags |= (flags & 0x6);
    
	if ((m & NSFunctionKeyMask)) filteredFlags |= NSFunctionKeyMask;
	else if ((flags & NSFunctionKeyMask) && (a & NSFunctionKeyMask)) filteredFlags |= NSFunctionKeyMask;
	
	return filteredFlags;
}

- (BOOL)_validModifierFlags:(NSUInteger)flags
{
	return (allowsKeyOnly ? YES : (((flags & NSCommandKeyMask) || (flags & NSAlternateKeyMask) || (flags & NSControlKeyMask) || (flags & NSShiftKeyMask) || (flags & NSFunctionKeyMask)) ? YES : NO));	
}

#pragma mark -

- (NSUInteger)_filteredCocoaToCarbonFlags:(NSUInteger)cocoaFlags
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	NSUInteger filteredFlags = [self _filteredCocoaFlags: cocoaFlags];
	
	if (filteredFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
	if (filteredFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
	if (filteredFlags & NSControlKeyMask) carbonFlags |= controlKey;
	if (filteredFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
	
	// I couldn't find out the equivalent constant in Carbon, but apparently it must use the same one as Cocoa. -AK
	if (filteredFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}

#pragma mark *** Internal Check ***

- (BOOL)_isEmpty
{
    if (!useSingleKeyMode)
        return ( ![self _validModifierFlags: keyCombo.flags] || !SRStringForKeyCode( keyCombo.code ) );
    
    return keyCombo.flags == ShortcutRecorderEmptyFlags && keyCombo.code == ShortcutRecorderEmptyCode;
}

#pragma mark *** Delegate pass-through ***

- (BOOL) shortcutValidator:(SRValidator *)validator isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
{
    SEL selector = @selector( shortcutRecorderCell:isKeyCode:andFlagsTaken:reason: );
    if ( ( delegate ) && ( [delegate respondsToSelector:selector] ) )
    {
        return [delegate shortcutRecorderCell:self isKeyCode:keyCode andFlagsTaken:flags reason:aReason];
    }
    return NO;
}

@end