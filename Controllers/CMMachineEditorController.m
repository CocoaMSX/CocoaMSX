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
#import "CMMachineEditorController.h"

#import "CMSlotEditorController.h"

@interface CMMachineEditorController ()

- (void)unloadMachine;

- (NSString *)descriptionForSlotInfo:(SlotInfo)slotInfo;
- (NSString *)slotSpanForSlotInfo:(SlotInfo)slotInfo;
- (NSString *)addressForSlotInfo:(SlotInfo)slotInfo;
- (NSString *)romPathForSlotInfo:(SlotInfo)slotInfo;

@end

@implementation CMMachineEditorController

- (id)init
{
    if ((self = [super initWithWindowNibName:@"MachineEditor"]))
    {
        loadedMachine = NULL;
    }
    
    return self;
}

- (void)dealloc
{
    [slotEditorController release];
    slotEditorController = nil;
    
    [self unloadMachine];
    
    [super dealloc];
}

- (void)unloadMachine
{
    if (loadedMachine)
    {
        machineDestroy(loadedMachine);
        loadedMachine = NULL;
    }
}

- (BOOL)loadMachineNamed:(NSString *)aMachineName
{
    [self unloadMachine];
    
    loadedMachine = machineCreate([aMachineName cStringUsingEncoding:NSUTF8StringEncoding]);
    if (loadedMachine == NULL)
    {
        // FIXME: error
        return NO;
    }
    
    machineUpdate(loadedMachine);
    
    return YES;
}

- (NSString *)descriptionForSlotInfo:(SlotInfo)slotInfo
{
    if (slotInfo.romType == RAM_MAPPER ||
        slotInfo.romType == RAM_NORMAL ||
        slotInfo.romType == ROM_EXTRAM ||
        slotInfo.romType == ROM_MEGARAM ||
        slotInfo.romType == SRAM_MEGASCSI ||
        slotInfo.romType == SRAM_ESERAM ||
        slotInfo.romType == SRAM_WAVESCSI ||
        slotInfo.romType == SRAM_ESESCC)
    {
        int size = slotInfo.pageCount * 8;
        if (size < 1024) {
            return [NSString stringWithFormat:@"%d kB %s",
                    size, romTypeToString(slotInfo.romType)];
        }
        else {
            return [NSString stringWithFormat:@"%d MB %s",
                    size / 1024, romTypeToString(slotInfo.romType)];
        }
    }
    
    return [NSString stringWithCString:romTypeToString(slotInfo.romType)
                              encoding:NSUTF8StringEncoding];
}

- (NSString *)slotSpanForSlotInfo:(SlotInfo)slotInfo
{
    if (slotInfo.pageCount == 0)
        return @"";
    else if (slotInfo.subslot || loadedMachine->slot[slotInfo.slot].subslotted)
        return [NSString stringWithFormat:@"%d-%d",
                slotInfo.slot, slotInfo.subslot];
    else
        return [NSString stringWithFormat:@"%d", slotInfo.slot];
}

- (NSString *)addressForSlotInfo:(SlotInfo)slotInfo
{
    if (slotInfo.slot == 0 &&
        slotInfo.subslot == 0 &&
        slotInfo.startPage == 0 &&
        slotInfo.pageCount == 0)
    {
        return @"";
    }
    else
    {
        int start;
        int end;
        
        if  (slotInfo.romType == SRAM_MEGASCSI ||
             slotInfo.romType == SRAM_ESERAM   ||
             slotInfo.romType == SRAM_WAVESCSI ||
             slotInfo.romType == SRAM_ESESCC)
        {
            start = 0x4000;
            end   = 0xbfff;
        }
        else
        {
            start = slotInfo.startPage * 0x2000;
            end   = start + slotInfo.pageCount * 0x2000 - 1;
            
            if (end > 0xffff)
                end = 0xffff;
        }
        
        return [NSString stringWithFormat:@"%.4X-%.4X", start, end];
    }
}

- (NSString *)romPathForSlotInfo:(SlotInfo)slotInfo
{
    const char *name;
    if (*slotInfo.inZipName)
        name = slotInfo.inZipName;
    else
        name = slotInfo.name;
    
    return [[NSString stringWithCString:name
                               encoding:NSUTF8StringEncoding] lastPathComponent];
}

#pragma mark - NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - Actions

- (void)tabChanged:(id)sender
{
    NSToolbarItem *selectedItem = (NSToolbarItem*)sender;
    
    [tabView selectTabViewItemWithIdentifier:selectedItem.itemIdentifier];
}

- (void)addSlotClicked:(id)sender
{
    if (!slotEditorController)
        slotEditorController = [[CMSlotEditorController alloc] init];
    
    [slotEditorController reinitializeWithMachine:loadedMachine];
    [slotEditorController showWindow:self];
}

#pragma mark - NSTableViewDataSourceDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (!loadedMachine)
        return 0;
    
    return loadedMachine->slotInfoCount;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *columnIdentifer = [aTableColumn identifier];
    SlotInfo info = loadedMachine->slotInfo[rowIndex];
    
    if ([columnIdentifer isEqualToString:@"title"])
        return [self descriptionForSlotInfo:info];
    else if ([columnIdentifer isEqualToString:@"slotSpan"])
        return [self slotSpanForSlotInfo:info];
    else if ([columnIdentifer isEqualToString:@"address"])
        return [self addressForSlotInfo:info];
    else if ([columnIdentifer isEqualToString:@"romPath"])
        return [self romPathForSlotInfo:info];
    
    return nil;
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}

@end
