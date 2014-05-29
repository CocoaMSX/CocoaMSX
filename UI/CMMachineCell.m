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
#import "CMMachineCell.h"

#import "CMMachine.h"

@implementation CMMachineCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    CMMachine *machine = [self objectValue];
    
    [controlView lockFocus];
    
    NSColor *textColor;
    
    if ([self isHighlighted])
    {
        textColor = [NSColor whiteColor];
    }
    else
    {
        textColor = [machine status] != CMMachineInstalled
            ? [NSColor disabledControlTextColor] : [NSColor controlTextColor];
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
    
    [controlView unlockFocus];
}

@end
