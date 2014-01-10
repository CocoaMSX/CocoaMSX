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
#import "CMSlotEditorController.h"

#include "MediaDb.h"

#pragma mark - CMRomType

@implementation CMRomType

- (id)initWithName:(NSString *)aName
           romType:(RomType)aRomType
{
    if ((self = [super init]))
    {
        name = [aName copy];
        romType = aRomType;
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    
    [super dealloc];
}

@end

#pragma mark - CMSlot

#define CM_MAKE_SLOT(i, j) (i & 0xf | (j & 0xf) << 4 | 1 << 8)
#define CM_SLOT(k) (k & 0xf)
#define CM_SUBSLOT(k) ((k >> 4) & 0xf)

@implementation CMSlot

- (id)initWithName:(NSString *)aName
{
    if ((self = [super init]))
    {
        subslotted = YES;
        name = [aName copy];
        slotRange = 0;
    }
    
    return self;
}

- (id)initWithName:(NSString *)aName
              slot:(NSInteger)slot
           subslot:(NSInteger)subslot
{
    if ((self = [super init]))
    {
        subslotted = YES;
        name = [aName copy];
        slotRange = CM_MAKE_SLOT(slot, subslot);
    }
    
    return self;
}

- (id)initWithName:(NSString *)aName
              slot:(NSInteger)slot
{
    if ((self = [super init]))
    {
        subslotted = NO;
        name = [aName copy];
        slotRange = CM_MAKE_SLOT(slot, 0);
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    
    [super dealloc];
}

@end

#pragma mark - CMSlotEditorController

@interface CMSlotEditorController ()

- (void)resyncUI;

@end

@implementation CMSlotEditorController

@synthesize selectedRomType = _selectedRomType;
@synthesize selectedSlot = _selectedSlot;

- (id)init
{
    if ((self = [super initWithWindowNibName:@"SlotEditor"]))
    {
    }
    
    return self;
}

- (void)awakeFromNib
{
    // Initialize list of ROM types
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"AllRomTypes"
                                                             ofType:@"plist"
                                                        inDirectory:@"Data"];
    NSMutableArray *romTypes = [NSMutableArray array];
    
    NSDictionary *romTypeMap = [NSDictionary dictionaryWithContentsOfFile:resourcePath];
    [romTypeMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        CMRomType *romType = [[CMRomType alloc] initWithName:obj
                                                     romType:(RomType)[key intValue]];
        
        [romTypes addObject:[romType autorelease]];
    }];
    
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                         ascending:YES];
    
    [romTypeArrayController setContent:romTypes];
    [romTypeArrayController setSortDescriptors:@[sd]];
    
    // Synchronize the UI to the selected SlotInfo
    [self resyncUI];
}

- (void)reinitializeWithMachine:(Machine *)aMachine
{
    // Create a new SlotInfo
    machine = aMachine;
    
    [self setSelectedRomType:ROM_NORMAL];
    [self setSelectedSlot:CM_MAKE_SLOT(0, 0)];
    
    [self resyncUI];
}

#pragma mark - Private methods

- (void)resyncUI
{
    RomType selectedRomType = [self selectedRomType];
    NSInteger selectedSlot = [self selectedSlot];
    
    // Rebuild slots
    NSMutableArray *slots = [NSMutableArray array];
    
    if (selectedRomType == SRAM_MATSUCHITA || selectedRomType == SRAM_S1985 ||
        selectedRomType == ROM_S1990 || selectedRomType == ROM_KANJI ||
        selectedRomType == ROM_GIDE ||
        selectedRomType == ROM_TURBORTIMER || selectedRomType == ROM_TURBORIO ||
        selectedRomType == ROM_NMS1210 || selectedRomType == ROM_F4INVERTED ||
        selectedRomType == ROM_F4DEVICE || selectedRomType == ROM_NMS8280DIGI ||
        selectedRomType == ROM_MOONSOUND || selectedRomType == ROM_MSXMIDI ||
        selectedRomType == ROM_MSXAUDIODEV || selectedRomType == ROM_TURBORPCM ||
        selectedRomType == ROM_JOYREXPSG || selectedRomType == ROM_KANJI12 ||
        selectedRomType == ROM_JISYO || selectedRomType == ROM_OPCODEPSG ||
        selectedRomType == ROM_OPCODESLOT || selectedRomType == ROM_SVI328FDC ||
        selectedRomType == ROM_SVI328PRN || selectedRomType == ROM_MSXPRN ||
        selectedRomType == ROM_SVI328RS232)
    {
        CMSlot *slot = [[[CMSlot alloc] initWithName:CMLoc(@"Unmapped", @"ROM slot")] autorelease];
        [slots addObject:slot];
        
        selectedSlot = 0;
    }
    else
    {
        for (int i = 0; i < 4; i++)
        {
            if (machine->slot[i].subslotted)
            {
                for (int j = 0; j < 4; j++)
                {
                    NSString *format = CMLoc(@"Slot %1$d/%2$d", @"Subslotted ROM slot");
                    NSString *slotName = [NSString stringWithFormat:format, i, j];
                    
                    CMSlot *slot = [[[CMSlot alloc] initWithName:slotName
                                                            slot:i
                                                         subslot:j] autorelease];
                    [slots addObject:slot];
                }
            }
            else
            {
                NSString *format = CMLoc(@"Slot %1$d", @"ROM Slot");
                NSString *slotName = [NSString stringWithFormat:format, i];
                
                CMSlot *slot = [[[CMSlot alloc] initWithName:slotName
                                                        slot:i] autorelease];
                [slots addObject:slot];
            }
        }
        
        if (selectedSlot == 0)
            selectedSlot = CM_MAKE_SLOT(0, 0);
    }
    
    [slotArrayController setContent:slots];
    [self setSelectedSlot:selectedSlot];
    
    // Addresses
//    if (selectedRomType == RAM_NORMAL || selectedRomType == RAM_1KB_MIRRORED ||
//        selectedRomType == RAM_2KB_MIRRORED || selectedRomType == ROM_NORMAL ||
//        selectedRomType == ROM_DISKPATCH || selectedRomType == ROM_CASPATCH ||
//        selectedRomType == ROM_MICROSOL || selectedRomType == ROM_NATIONALFDC ||
//        selectedRomType == ROM_PHILIPSFDC || selectedRomType == ROM_SVI738FDC ||
//        selectedRomType == ROM_MSXMUSIC || selectedRomType == ROM_BEERIDE ||
//        selectedRomType == ROM_DRAM || selectedRomType == ROM_FMPAC ||
//        selectedRomType == ROM_PAC || selectedRomType == ROM_BUNSETU ||
//        selectedRomType == ROM_MICROSOL80)
//    {
//        int size;
//        
//        switch (selectedRomType)
//        {
//        case RAM_NORMAL:
//            size = editRamNormalSize / 0x2000;
//            break;
//        case RAM_1KB_MIRRORED:
//            size = editRamMirroredSize / 0x2000;
//            break;
//        case RAM_2KB_MIRRORED:
//            size = editRamMirroredSize / 0x2000;
//            break;
//        case ROM_NATIONALFDC:
//        case ROM_PHILIPSFDC:
//        case ROM_SVI738FDC:
//            size = 4;
//            break;
//        case ROM_FMPAC:
//        case ROM_PAC:
//            size = 2;
//            break;
//        default:
//            size = romPages;
//            if (size > 8)
//                size = 8;
//            else if (size < 1)
//                size = 1;
//        }
//        
//        int end = 8 - size;
//        int start = (editSlotInfo.startPage < end)
//            ? editSlotInfo.startPage : end;
//        
//        for (int i = 0; i <= end; i++)
//        {
//            char buffer[32];
//            sprintf(buffer, "%.4X - %.4X", i * 0x2000, (i + size) * 0x2000 - 1);
//            SendDlgItemMessage(hDlg, IDC_ROMADDR, CB_ADDSTRING, 0, (LPARAM)buffer);
//            if (i == start) {
//                SendDlgItemMessage(hDlg, IDC_ROMADDR, CB_SETCURSEL, i, 0);
//            }
//        }
//    }
}

#pragma mark - Actions

- (void)romTypeSelected:(id)sender
{
    [self resyncUI];
}

- (void)slotSelected:(id)sender
{
    NSLog(@"slot type: 0x%02ld (%ld,%ld)", [self selectedSlot], CM_SLOT([self selectedSlot]), CM_SUBSLOT([self selectedSlot]));
//    currentSlotInfo.romType = [self selectedRomType];
    
    [self resyncUI];
}

@end
