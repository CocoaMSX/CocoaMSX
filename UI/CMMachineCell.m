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
#import "CMMachineCell.h"

#import "CMMachine.h"

@implementation CMMachineCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [controlView lockFocus];
    
    NSColor *textColor;
    NSImage *downloadIcon;
    
    if ([self isHighlighted])
    {
        textColor = [NSColor whiteColor];
        downloadIcon = [NSImage imageNamed:@"icon-downloading-inverse"];
    }
    else
    {
        textColor = ![machine installed]
            ? [NSColor disabledControlTextColor] : [NSColor controlTextColor];
        downloadIcon = [NSImage imageNamed:@"icon-downloading"];
    }
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSFont systemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName,
                                    textColor, NSForegroundColorAttributeName,
                                    nil];
    
    NSSize textSize = [[machine name] sizeWithAttributes:textAttributes];
    
    NSColor *subtextColor = ([self isHighlighted]) ? [NSColor whiteColor] : [NSColor disabledControlTextColor];
    NSDictionary *subtextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
                                       subtextColor, NSForegroundColorAttributeName,
                                       nil];
    
    [[machine name] drawAtPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y)
                 withAttributes:textAttributes];
    [[machine systemName] drawAtPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + textSize.height)
                       withAttributes:subtextAttributes];
    
    if ([machine downloading])
    {
        [downloadIcon drawInRect:NSMakeRect(cellFrame.origin.x + cellFrame.size.width - downloadIcon.size.width * 1.5,
                                            cellFrame.origin.y + (cellFrame.size.height - downloadIcon.size.height) / 2.0,
                                            downloadIcon.size.width,
                                            downloadIcon.size.height)
                        fromRect:NSMakeRect(0, 0, downloadIcon.size.width, downloadIcon.size.height)
                       operation:NSCompositeSourceOver
                        fraction:1.0
                  respectFlipped:YES
                           hints:nil];
    }
    
    [controlView unlockFocus];
}

- (void)setObjectValue:(id <NSCopying>)object
{
    machine = (CMMachine *)object;
}

@end
