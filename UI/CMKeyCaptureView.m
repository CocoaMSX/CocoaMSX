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

- (void)captureKeyCode:(NSInteger)keyCode;
- (NSRect)unmapRect;
- (BOOL)canUnmap;

@end

@implementation CMKeyCaptureView

#define CMKeyLeftCommand      55
#define CMKeyRightCommand     54
#define CMKeyFunctionModifier 63

#define CMCharAsString(x) [NSString stringWithFormat:@"%C", (unsigned short)x]
#define CMFormattedCharAsString(fmt, x) [NSString stringWithFormat:CMLoc(fmt), x]

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
                          
                          @"",    @102,
                          @"",    @104,
                          @"",    @108,
                          @"",    @110,
                          @"",    @112,
                          
                          // Well-known keys
                          
                          @"F1",  @122,
                          @"F2",  @120,
                          @"F3",  @99,
                          @"F4",  @118,
                          @"F5",  @96,
                          @"F6",  @97,
                          @"F7",  @98,
                          @"F8",  @100,
                          @"F9",  @101,
                          @"F10", @109,
                          @"F11", @103,
                          @"F12", @111,
                          @"F13", @105,
                          @"F14", @107,
                          @"F15", @113,
                          @"F16", @106,
                          @"F17", @64,
                          @"F18", @79,
                          @"F19", @80,
                          
                          CMLoc(@"CapsLock"), @57,
                          CMLoc(@"Spacebar"), @49,
                          
                          CMFormattedCharAsString(@"LeftKey_f", kShiftUnicode),    @56,
                          CMFormattedCharAsString(@"RightKey_f", kShiftUnicode),   @60,
                          CMFormattedCharAsString(@"LeftKey_f", kControlUnicode),  @59,
                          CMFormattedCharAsString(@"RightKey_f", kControlUnicode), @62,
                          CMFormattedCharAsString(@"LeftKey_f", kOptionUnicode),   @58,
                          CMFormattedCharAsString(@"RightKey_f", kOptionUnicode),  @61,
                          CMFormattedCharAsString(@"LeftKey_f", kCommandUnicode),  @55,
                          CMFormattedCharAsString(@"RightKey_f", kCommandUnicode), @54,
                          
                          CMFormattedCharAsString(@"NumpadKey_f", @"."), @65,
                          CMFormattedCharAsString(@"NumpadKey_f", @"*"), @67,
                          CMFormattedCharAsString(@"NumpadKey_f", @"/"), @75,
                          CMFormattedCharAsString(@"NumpadKey_f", @"-"), @78,
                          CMFormattedCharAsString(@"NumpadKey_f", @"="), @81,
                          CMFormattedCharAsString(@"NumpadKey_f", @"0"), @82,
                          CMFormattedCharAsString(@"NumpadKey_f", @"1"), @83,
                          CMFormattedCharAsString(@"NumpadKey_f", @"2"), @84,
                          CMFormattedCharAsString(@"NumpadKey_f", @"3"), @85,
                          CMFormattedCharAsString(@"NumpadKey_f", @"4"), @86,
                          CMFormattedCharAsString(@"NumpadKey_f", @"5"), @87,
                          CMFormattedCharAsString(@"NumpadKey_f", @"6"), @88,
                          CMFormattedCharAsString(@"NumpadKey_f", @"7"), @89,
                          CMFormattedCharAsString(@"NumpadKey_f", @"8"), @91,
                          CMFormattedCharAsString(@"NumpadKey_f", @"9"), @92,
                          
                          CMCharAsString(0x232B), @51,  // Backspace
                          CMCharAsString(0x2326), @117, // Delete
                          CMCharAsString(0x2327), @71,  // Numpad
                          CMCharAsString(0x2190), @123, // Cursor Left
                          CMCharAsString(0x2192), @124, // Cursor Right
                          CMCharAsString(0x2191), @126, // Cursor Up
                          CMCharAsString(0x2193), @125, // Cursor Down
                          CMCharAsString(0x2196), @115, // Home
                          CMCharAsString(0x2198), @119, // End
                          CMCharAsString(0x238B), @53,  // Escape
                          CMCharAsString(0x21DF), @121, // Page Down
                          CMCharAsString(0x21DE), @116, // Page Up
                          CMCharAsString(0x21A9), @36,  // Return R-L
                          CMCharAsString(0x2305), @76,  // Return
                          CMCharAsString(0x21E5), @48,  // Tab
                          CMCharAsString(0x003F), @114, // Help
                          
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

- (void)keyDown:(NSEvent *)theEvent
{
    if (![keyCodesToIgnore containsObject:@([theEvent keyCode])])
        [self captureKeyCode:[theEvent keyCode]];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    if (![keyCodesToIgnore containsObject:@([theEvent keyCode])])
        [self captureKeyCode:[theEvent keyCode]];
}

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

#pragma mark - Private methods

- (void)captureKeyCode:(NSInteger)keyCode
{
    NSString *keyName = [CMKeyCaptureView descriptionForKeyCode:@(keyCode)];
    if (!keyName)
        keyName = @"";
    
    // Update the editor's text with the code's description
    [[self textStorage] replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length])
                                      withString:keyName];
    
    // Resign first responder (closes the editor)
    [[self window] makeFirstResponder:(NSView *)self.delegate];
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
