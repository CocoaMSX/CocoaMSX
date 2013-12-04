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
    NSMutableArray *slots = [NSMutableArray array];
    
    RomType romType = [self selectedRomType];
    if (romType == SRAM_MATSUCHITA || romType == SRAM_S1985 ||
        romType == ROM_S1990 || romType == ROM_KANJI || romType == ROM_GIDE ||
        romType == ROM_TURBORTIMER || romType == ROM_TURBORIO ||
        romType == ROM_NMS1210 || romType == ROM_F4INVERTED ||
        romType == ROM_F4DEVICE || romType == ROM_NMS8280DIGI ||
        romType == ROM_MOONSOUND || romType == ROM_MSXMIDI ||
        romType == ROM_MSXAUDIODEV || romType == ROM_TURBORPCM ||
        romType == ROM_JOYREXPSG || romType == ROM_KANJI12 ||
        romType == ROM_JISYO || romType == ROM_OPCODEPSG ||
        romType == ROM_OPCODESLOT || romType == ROM_SVI328FDC ||
        romType == ROM_SVI328PRN || romType == ROM_MSXPRN ||
        romType == ROM_SVI328RS232)
    {
        CMSlot *slot = [[[CMSlot alloc] initWithName:CMLoc(@"Unmapped", @"ROM slot")] autorelease];
        [slots addObject:slot];
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
    }
    
    [slotArrayController setContent:slots];
    
//    [self setSelectedRomType:[self selectedRomType]];
//    [self setSelectedSlot:CM_MAKE_SLOT(currentSlotInfo.slot, currentSlotInfo.subslot)];
}

#pragma mark - Actions

- (void)romTypeSelected:(id)sender
{
    [self setSelectedSlot:CM_MAKE_SLOT(0, 0)];
    
    [self resyncUI];
}

- (void)slotSelected:(id)sender
{
    NSLog(@"slot type: 0x%02ld (%ld,%ld)", [self selectedSlot], CM_SLOT([self selectedSlot]), CM_SUBSLOT([self selectedSlot]));
//    currentSlotInfo.romType = [self selectedRomType];
    
    [self resyncUI];
}

@end
