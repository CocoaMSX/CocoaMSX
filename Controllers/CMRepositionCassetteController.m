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
#import "CMRepositionCassetteController.h"

#include "Casette.h"

#pragma mark - CassetteEntry

@interface CMCassetteEntry : NSObject
{
    @public
    NSString *filename;
    NSString *typeName;
    NSString *posTimeReadable;
    NSInteger posTime;
}

@end

@implementation CMCassetteEntry

- (id)initWithContent:(const TapeContent*)tapeContent
{
    NSArray *types = [NSArray arrayWithObjects:
                      CMLoc(@"ASCII", @"Cassette tape data format"),
                      CMLoc(@"Binary", @"Cassette tape data format"),
                      CMLoc(@"BASIC", @"Cassette tape data format"),
                      CMLoc(@"Other", @"Cassette tape data format"), nil];
    
    if ((self = [super init]))
    {
        typeName = [[types objectAtIndex:tapeContent->type] copy];
        filename = [[NSString alloc] initWithCString:tapeContent->fileName
                                            encoding:NSASCIIStringEncoding];
        posTime = tapeContent->pos;
        posTimeReadable = [[NSString stringWithFormat:CMLoc(@"%dh %02dm %02ds", @"Time format (h:mm:ss)"),
                    posTime / 3600,
                    (posTime / 60) % 60,
                    posTime % 60] retain];
    }
    
    return self;
}

+ (id)entryWithContent:(const TapeContent*)tapeContent
{
    return [[[CMCassetteEntry alloc] initWithContent:tapeContent] autorelease];
}

- (void)dealloc
{
    [posTimeReadable release];
    [typeName release];
    [filename release];
    
    [super dealloc];
}

@end

#pragma mark - RepositionCassetteController

@interface CMRepositionCassetteController ()

- (void)loadContents;

@end

@implementation CMRepositionCassetteController

@synthesize delegate = _delegate;
@synthesize isSelectable = _isSelectable;

#pragma mark - Initialization, Destruction

- (id)init
{
    if ((self = [super initWithWindowNibName:@"RepositionCassette"]))
    {
        casEntries = [[NSMutableArray array] retain];
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.isSelectable = NO;
    [self loadContents];
    
    [tableView setDoubleAction:@selector(confirm:)];
}

- (void)dealloc
{
    [casEntries dealloc];
    
    [super dealloc];
}

#pragma mark - NSTableViewDataSourceDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return casEntries.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    CMCassetteEntry *entry = [casEntries objectAtIndex:rowIndex];
    
    NSString *columnIdentifer = [aTableColumn identifier];
    if ([columnIdentifer isEqualToString:@"time"])
        return entry->posTimeReadable;
    else if ([columnIdentifer isEqualToString:@"filename"])
        return entry->filename;
    else if ([columnIdentifer isEqualToString:@"type"])
        return entry->typeName;
    
    return nil;
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    self.isSelectable = ([tableView numberOfSelectedRows] > 0);
}

#pragma mark - Private Methods

- (void)loadContents
{
    int count = 0;
    TapeContent *tc = tapeGetContent(&count);
    
    for (int i = 0; i < count; i++)
    {
        CMCassetteEntry *entry = [CMCassetteEntry entryWithContent:&tc[i]];
        if (entry)
            [casEntries addObject:entry];
    }
}

#pragma mark - Methods

- (void)showSheetForWindow:(NSWindow *)window
{
    [NSApp beginSheet:self.window
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    [NSApp runModalForWindow:self.window];
    
    [NSApp endSheet:self.window];
    [self.window orderOut:self];
}

#pragma mark - Actions

- (void)dismiss:(id)sender
{
    [NSApp stopModal];
}

- (void)confirm:(id)sender
{
    if ([tableView numberOfSelectedRows] > 0)
    {
        CMCassetteEntry *entry = [casEntries objectAtIndex:[tableView selectedRow]];
        
        [self.delegate cassetteRepositionedTo:entry->posTime];
        [NSApp stopModal];
    }
}

@end
