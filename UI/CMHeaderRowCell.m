/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2013 Akop Karapetyan
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
#import "CMHeaderRowCell.h"

@implementation CMHeaderRowCell

- (id)initWithHeaderText:(NSString *)text
{
    if (self = [super init])
    {
        headerText = [text copy];
    }
    
    return self;
}

- (void)dealloc
{
    [headerText release];
    
    [super dealloc];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        headerText = [[aDecoder decodeObjectForKey:@"headerText"] retain];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:headerText forKey:@"headerText"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CMHeaderRowCell *copy = [super copyWithZone:zone];
    
    if (copy)
    {
        copy->headerText = [headerText copy];
    }
    
    return copy;
}

#pragma mark - NSCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // Initialize
    
    NSRect outlineRect = [controlView frame];
    
    NSColor *gradientStartColor = [[NSColor alternateSelectedControlColor] highlightWithLevel:0.90f];
    NSColor *gradientEndColor = [[NSColor alternateSelectedControlColor] highlightWithLevel:0.6f];
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:gradientStartColor
                                                          endingColor:gradientEndColor] autorelease];
    
    NSFont *headerFont = [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    headerFont, NSFontAttributeName,
                                    [NSColor textColor], NSForegroundColorAttributeName, nil];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    // Draw the separator
    
    NSRect gridRect = NSMakeRect(outlineRect.origin.x, cellFrame.origin.y,
                                 outlineRect.size.width, cellFrame.size.height + 1);
    
    [[[NSColor gridColor] shadowWithLevel:0.3] set];
    [[NSBezierPath bezierPathWithRect:gridRect] fill];
    
    // Fill the gradient
    
    NSRect gradientRect = NSMakeRect(outlineRect.origin.x, cellFrame.origin.y - 1,
                                     outlineRect.size.width, cellFrame.size.height + 1);
    
    [gradient drawInRect:gradientRect angle:90.0f];
    
    // Display the title
    
    NSSize textSize = [headerText sizeWithAttributes:textAttributes];
    NSPoint textPos = NSMakePoint(cellFrame.origin.x + 6,
                                  cellFrame.origin.y + (cellFrame.size.height - textSize.height) / 2 - 1);
    
    [headerText drawAtPoint:textPos withAttributes:textAttributes];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
