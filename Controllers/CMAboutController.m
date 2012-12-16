/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012 Akop Karapetyan
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
#import "CMAboutController.h"

@implementation CMWhitePanelView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
}

@end

@interface CMAboutController ()

@end

@implementation CMAboutController

- (id)init
{
    if ((self = [super initWithWindowNibName:@"About"]))
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - Actions

- (void)showLicense:(id)sender
{
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *documentPath = [resourcePath stringByAppendingPathComponent:@"Documents/LICENSE"];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:documentPath]];
}

- (void)showAuthors:(id)sender
{
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *documentPath = [resourcePath stringByAppendingPathComponent:@"Documents/AUTHORS"];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:documentPath]];
}

@end
