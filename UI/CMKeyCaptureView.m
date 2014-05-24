/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2013 Akop Karapetyan
 **
 ** Portions of code from ShortcutRecorder by various contributors
 ** http://wafflesoftware.net/shortcut/
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

#import "CMKeyCaptureView.h"

@interface CMKeyCaptureView ()

- (NSRect)unmapRect;
- (BOOL)canUnmap;

@end

@implementation CMKeyCaptureView

#define CMKeyLeftCommand      55
#define CMKeyRightCommand     54
#define CMKeyFunctionModifier 63

#define CMCharAsString(x) [NSString stringWithFormat:@"%C", (unsigned short)x]

static NSMutableDictionary *keyCodeLookupTable;
static NSMutableDictionary *reverseKeyCodeLookupTable;
static NSArray *keyCodesToIgnore;

+ (void)initialize
{
    keyCodesToIgnore = [[NSArray alloc] initWithObjects:
                        
                        // Ignore the function modifier key (needed on MacBooks)
                        
                        @CMKeyFunctionModifier,
                        
                        // Ignore the Command modifier keys - they're used
                        // for shortcuts
                        
                        @CMKeyLeftCommand,
                        @CMKeyRightCommand,
                        
                        nil];

    keyCodeLookupTable = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                          
                          // These seem to be unused. Included here to avoid
                          // creating collisions in reverseKeyCodeLookupTable
                          // with identical names
                          
                          @"",    @0x66,
                          @"",    @0x68,
                          @"",    @0x6c,
                          @"",    @0x6e,
                          @"",    @0x70,
                          
                          // Well-known keys
                          
                          @"F1",  @0x7a,
                          @"F2",  @0x78,
                          @"F3",  @0x63,
                          @"F4",  @0x76,
                          @"F5",  @0x60,
                          @"F6",  @0x61,
                          @"F7",  @0x62,
                          @"F8",  @0x64,
                          @"F9",  @0x65,
                          @"F10", @0x6d,
                          @"F11", @0x67,
                          @"F12", @0x6f,
                          CMLoc(@"Print Screen", @"Mac Key"), @0x69,
                          @"F14", @0x6b,
                          @"F15", @0x71,
                          @"F16", @0x6a,
                          @"F17", @0x40,
                          @"F18", @0x4f,
                          @"F19", @0x50,
                          
                          CMLoc(@"Caps Lock", @"Mac Key"), @0x39,
                          CMLoc(@"Space", @"Mac Key"),     @0x31,
                          
                          [NSString stringWithFormat:CMLoc(@"Left %C", @"Mac Key"), kShiftUnicode],    @0x38,
                          [NSString stringWithFormat:CMLoc(@"Right %C", @"Mac Key"), kShiftUnicode],   @0x3c,
                          [NSString stringWithFormat:CMLoc(@"Left %C", @"Mac Key"), kControlUnicode],  @0x3b,
                          [NSString stringWithFormat:CMLoc(@"Right %C", @"Mac Key"), kControlUnicode], @0x3e,
                          [NSString stringWithFormat:CMLoc(@"Left %C", @"Mac Key"), kOptionUnicode],   @0x3a,
                          [NSString stringWithFormat:CMLoc(@"Right %C", @"Mac Key"), kOptionUnicode],  @0x3d,
                          [NSString stringWithFormat:CMLoc(@"Left %C", @"Mac Key"), kCommandUnicode],  @0x37,
                          [NSString stringWithFormat:CMLoc(@"Right %C", @"Mac Key"), kCommandUnicode], @0x36,
                          
                          CMLoc(@"Keypad .", @"Mac Key"),     @0x41,
                          CMLoc(@"Keypad *", @"Mac Key"),     @0x43,
                          CMLoc(@"Keypad +", @"Mac Key"),     @0x45,
                          CMLoc(@"Keypad /", @"Mac Key"),     @0x4b,
                          CMLoc(@"Keypad -", @"Mac Key"),     @0x4e,
                          CMLoc(@"Keypad =", @"Mac Key"),     @0x51,
                          CMLoc(@"Keypad 0", @"Mac Key"),     @0x52,
                          CMLoc(@"Keypad 1", @"Mac Key"),     @0x53,
                          CMLoc(@"Keypad 2", @"Mac Key"),     @0x54,
                          CMLoc(@"Keypad 3", @"Mac Key"),     @0x55,
                          CMLoc(@"Keypad 4", @"Mac Key"),     @0x56,
                          CMLoc(@"Keypad 5", @"Mac Key"),     @0x57,
                          CMLoc(@"Keypad 6", @"Mac Key"),     @0x58,
                          CMLoc(@"Keypad 7", @"Mac Key"),     @0x59,
                          CMLoc(@"Keypad 8", @"Mac Key"),     @0x5b,
                          CMLoc(@"Keypad 9", @"Mac Key"),     @0x5c,
                          CMLoc(@"Keypad Enter", @"Mac Key"), @0x4c,
                          
                          CMLoc(@"Insert", "Mac Key"),    @0x72, // Insert
                          CMCharAsString(0x232B),         @0x33, // Backspace
                          CMCharAsString(0x2326),         @0x75, // Delete
                          CMLoc(@"Num Lock", "Mac Key"),  @0x47, // Numpad
                          CMCharAsString(0x2190),         @0x7b, // Cursor Left
                          CMCharAsString(0x2192),         @0x7c, // Cursor Right
                          CMCharAsString(0x2191),         @0x7e, // Cursor Up
                          CMCharAsString(0x2193),         @0x7d, // Cursor Down
                          CMLoc(@"Home", "Mac Key"),      @0x73, // Home
                          CMLoc(@"End", "Mac Key"),       @0x77, // End
                          CMLoc(@"Escape", "Mac Key"),    @0x35, // Escape
                          CMLoc(@"Page Down", "Mac Key"), @0x79, // Page Down
                          CMLoc(@"Page Up", "Mac Key"),   @0x74, // Page Up
                          CMCharAsString(0x21A9),         @0x24, // Return R-L
                          CMCharAsString(0x21E5),         @0x30, // Tab
                          
                          nil];
    
    // Get names for the remaining keys by going through the list of codes
    
	OSStatus err;
	TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    
    if (tisSource)
    {
        CFDataRef layoutData;
        UInt32 keysDown = 0;
        layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource,
                                                          kTISPropertyUnicodeKeyLayoutData);
        
        CFRelease(tisSource);
        
        // For non-unicode layouts such as Chinese, Japanese, and
        // Korean, get the ASCII capable layout
        
        if (!layoutData)
        {
            tisSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
            layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource,
                                                              kTISPropertyUnicodeKeyLayoutData);
            CFRelease(tisSource);
        }
        
        if (layoutData)
        {
            const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
            
            UniCharCount length = 4, realLength;
            UniChar chars[4];
            
            for (int keyCode = 0; keyCode < 255; keyCode++)
            {
                NSNumber *keyCodeObj = @(keyCode);
                
                // Skip through codes we already know
                if ([keyCodeLookupTable objectForKey:keyCodeObj])
                    continue;
                
                err = UCKeyTranslate(keyLayout,
                                     keyCode,
                                     kUCKeyActionDisplay,
                                     0,
                                     LMGetKbdType(),
                                     kUCKeyTranslateNoDeadKeysBit,
                                     &keysDown,
                                     length,
                                     &realLength,
                                     chars);
                
                if (err == noErr && realLength > 0)
                {
                    NSString *keyName = [[NSString stringWithCharacters:chars length:1] uppercaseString];
                    
                    [keyCodeLookupTable setObject:keyName forKey:keyCodeObj];
                }
            }
        }
    }
    
    // Generate reverse lookup table
    reverseKeyCodeLookupTable = [[NSMutableDictionary alloc] init];
    
    [keyCodeLookupTable enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        NSNumber *keyCodeObj = key;
        NSString *keyName = obj;
        NSNumber *existingCode;
        
        if ([keyName length] > 0)
        {
            if ((existingCode = [reverseKeyCodeLookupTable objectForKey:keyName]))
            {
                NSLog(@"reverseKeyCodeLookupTable conflict: name: '%@' code: %@ (existing: %@)",
                      keyName, keyCodeObj, existingCode);
                
                return;
            }
            
            [reverseKeyCodeLookupTable setObject:keyCodeObj forKey:keyName];
        }
    }];
}

#pragma mark - Input events

- (BOOL)becomeFirstResponder
{
    if ([super becomeFirstResponder])
    {
        [self setEditable:NO];
        [self setSelectable:NO];
        
        return YES;
    }
    
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    if ([self canUnmap])
    {
        NSPoint mousePosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (NSPointInRect(mousePosition, [self unmapRect]))
            [self captureKeyCode:CMKeyNone];
    }
}

- (void)keyDown:(NSEvent *)theEvent
{
}

- (void)keyUp:(NSEvent *)theEvent
{
}

#pragma mark - Private methods

- (BOOL)captureKeyCode:(NSInteger)keyCode
{
    if ([keyCodesToIgnore containsObject:@(keyCode)])
        return NO;

    NSString *keyName = [CMKeyCaptureView descriptionForKeyCode:@(keyCode)];
    if (!keyName)
        keyName = @"";
    
    // Update the editor's text with the code's description
    [[self textStorage] replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length])
                                      withString:keyName];
    
    // Resign first responder (closes the editor)
    [[self window] makeFirstResponder:(NSView *)self.delegate];
    
    return YES;
}

+ (NSString *)descriptionForKeyCode:(NSNumber *)keyCode
{
	if ([keyCode integerValue] != CMKeyNone)
    {
        NSString *string = nil;
        if ((string = [keyCodeLookupTable objectForKey:keyCode]))
            return string;
    }
	
    return @"";
}

+ (NSNumber *)keyCodeForDescription:(NSString *)description
{
    if (description && [description length] > 0)
    {
        NSNumber *keyCode = [reverseKeyCodeLookupTable objectForKey:description];
        if (keyCode)
            return keyCode;
    }
    
    return @CMKeyNone;
}

- (BOOL)canUnmap
{
    return ([self string] && [[self string] length] > 0);
}

- (NSRect)unmapRect
{
    NSRect cellFrame = [self bounds];
    
    CGFloat diam = cellFrame.size.height * .70;
    return NSMakeRect(cellFrame.origin.x + cellFrame.size.width - cellFrame.size.height,
                      cellFrame.origin.y + (cellFrame.size.height - diam) / 2.0,
                      diam, diam);
}

#pragma mark - NSTextView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    if ([self canUnmap])
    {
        // Valid key
        
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
    }
    else
    {
        // No key
        
        NSBezierPath *bgRect = [NSBezierPath bezierPathWithRect:[self bounds]];
        
        [[NSColor controlBackgroundColor] set];
        [bgRect fill];
        
        NSMutableParagraphStyle *mpstyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
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
