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
#import <Carbon/Carbon.h>

#import "CMJoyCaptureView.h"

#import "CMGamepadConfiguration.h"

@interface CMJoyCaptureView ()

- (NSRect)unmapRect;
- (BOOL)canUnmap;

@end

@implementation CMJoyCaptureView

static NSMutableDictionary *codeLookupTable;
static NSMutableDictionary *reverseCodeLookupTable;

+ (void)initialize
{
    codeLookupTable = [[NSMutableDictionary alloc] init];
    reverseCodeLookupTable = [[NSMutableDictionary alloc] init];
	
	NSDictionary *dict = @{ @"Up": @(CMMakeAnalog(CM_DIR_UP)),
							@"Down": @(CMMakeAnalog(CM_DIR_DOWN)),
							@"Left": @(CMMakeAnalog(CM_DIR_LEFT)),
							@"Right": @(CMMakeAnalog(CM_DIR_RIGHT)) };
	
	[dict enumerateKeysAndObjectsUsingBlock:^(NSString *desc, NSNumber *mask, BOOL * _Nonnull stop) {
		[codeLookupTable setObject:desc
							forKey:mask];
		[reverseCodeLookupTable setObject:mask
								   forKey:desc];
	}];
	
    for (int i = 1; i <= 31; i++) {
        NSNumber *code = @(CMMakeButton(i));
        NSString *desc = [NSString stringWithFormat:CMLoc(@"Button %d", @"Joystick button"), i];
        [codeLookupTable setObject:desc
                            forKey:code];
        [reverseCodeLookupTable setObject:code
                                   forKey:desc];
    }
}

#pragma mark - Input events

- (BOOL) becomeFirstResponder
{
    if ([super becomeFirstResponder]) {
        [self setEditable:NO];
        [self setSelectable:NO];
        
        return YES;
    }
    
    return NO;
}

- (void) mouseDown:(NSEvent *) theEvent
{
    [super mouseDown:theEvent];
    
    if ([self canUnmap]) {
        NSPoint mousePosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (NSPointInRect(mousePosition, [self unmapRect])) {
            [self captureCode:CM_NO_INPUT];
        }
    }
}

- (void) keyDown:(NSEvent *) theEvent
{
}

- (void) keyUp:(NSEvent *) theEvent
{
}

- (BOOL) captureCode:(NSInteger) code
{
    NSString *name = [CMJoyCaptureView descriptionForCode:code];
    if (!name) {
        name = @"";
    }
    
    // Update the editor's text with the code's description
    [[self textStorage] replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length])
                                      withString:name];
    
    // Resign first responder (closes the editor)
    [[self window] makeFirstResponder:(NSView *)self.delegate];
    
    return YES;
}

+ (NSString *) descriptionForCode:(NSInteger) code
{
	if (code != CM_NO_INPUT) {
        NSString *string = nil;
        if ((string = [codeLookupTable objectForKey:@(code)])) {
            return string;
        }
    }
	
    return @"";
}

+ (NSNumber *) codeForDescription:(NSString *) description
{
    if (description && [description length] > 0) {
        NSNumber *code = [reverseCodeLookupTable objectForKey:description];
        if (code) {
            return code;
        }
    }
	
	return @(CM_NO_INPUT);
}

#pragma mark - Private methods

- (BOOL) canUnmap
{
    return ([self string] && [[self string] length] > 0);
}

- (NSRect) unmapRect
{
    NSRect cellFrame = [self bounds];
    
    CGFloat diam = cellFrame.size.height * .70;
    return NSMakeRect(cellFrame.origin.x + cellFrame.size.width - cellFrame.size.height,
                      cellFrame.origin.y + (cellFrame.size.height - diam) / 2.0,
                      diam, diam);
}

#pragma mark - NSTextView

- (void) drawRect:(NSRect) dirtyRect
{
    [super drawRect:dirtyRect];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    if ([self canUnmap]) {
        NSRect circleRect = [self unmapRect];
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:circleRect];
        
        [[NSColor darkGrayColor] set];
        [path fill];
        
        NSRect dashRect = NSInsetRect(circleRect,
                                      circleRect.size.width * 0.2,
                                      circleRect.size.height * 0.6);
        
        path = [NSBezierPath bezierPathWithRect:dashRect];
        
        [[NSColor whiteColor] set];
        [path fill];
    } else {
        NSBezierPath *bgRect = [NSBezierPath bezierPathWithRect:[self bounds]];
        
        [[NSColor controlBackgroundColor] set];
        [bgRect fill];
        
        NSMutableParagraphStyle *mpstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [mpstyle setAlignment:[self alignment]];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    mpstyle, NSParagraphStyleAttributeName,
                                    [self font], NSFontAttributeName,
                                    [NSColor disabledControlTextColor], NSForegroundColorAttributeName,
                                    
                                    nil];
        
        [@"..." drawInRect:[self bounds] withAttributes:attributes];
    }
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
