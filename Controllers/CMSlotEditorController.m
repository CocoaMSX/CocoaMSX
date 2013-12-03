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

@synthesize romType;

- (id)initWithName:(NSString *)aName
           romType:(RomType)aRomType
{
    if ((self = [super init]))
    {
        name = [aName copy];
        romType = @(aRomType);
    }
    
    return self;
}

- (NSString *)name
{
    return name;
}

- (void)dealloc
{
    [name release];
    [romType release];
    
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ [0x%04x]", name, [romType intValue]];
}

@end

#pragma mark - CMSlotEditorController

@interface CMSlotEditorController ()

- (void)resyncUI;

@end

@implementation CMSlotEditorController

#define CM_MAKE_SLOT(i, j) (i & 0x03 | (j & 0x03 << 2))
#define CM_SLOT(k) (k & 0x03)
#define CM_SUBSLOT(k) (k & 0x03 << 2)

- (id)init
{
    if ((self = [super initWithWindowNibName:@"SlotEditor"]))
    {
//        slotIndices = [[NSMutableArray alloc] init];
//        slotNames = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
//    [slotIndices release];
//    [slotNames release];

    [super dealloc];
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

    [self resyncUI];
}

- (void)reinitializeWithMachine:(Machine *)aMachine
{
    machine = aMachine;
    
    memset(&currentSlotInfo, 0, sizeof(currentSlotInfo));
    currentSlotInfo.romType = ROM_NORMAL;
    
    [self resyncUI];
}

- (void)reinitializeWithMachine:(Machine *)aMachine
                       slotInfo:(SlotInfo)slotInfo
{
    machine = aMachine;
    currentSlotInfo = slotInfo;
    
    [self resyncUI];
}

#pragma mark - Private methods

//- (void)initializeSystemInfo
//{
//    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"RomTypes"
//                                                             ofType:@"plist"
//                                                        inDirectory:@"Data"];
//    
//    NSDictionary *romTypeMap = [NSDictionary dictionaryWithContentsOfFile:resourcePath];
//    
//    // Sort ROM type ID's by name
//    NSArray *sortedRomTypeIds = [[romTypeMap allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
//                                 {
//                                     if ([a isEqualTo:@"0"])
//                                         return -1;
//                                     else if ([b isEqualTo:@"0"])
//                                         return 1;
//                                     
//                                     NSString *titleA = [romTypeMap objectForKey:a];
//                                     NSString *titleB = [romTypeMap objectForKey:b];
//                                     
//                                     return [titleA caseInsensitiveCompare:titleB];
//                                 }];
//    
//    [sortedRomTypeIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
//     {
//         NSNumber *index = @(idx);
//         NSNumber *type = [NSNumber numberWithInt:[obj intValue]];
//         
//         [romTypes setObject:type forKey:index];
//         [romTypeIndices setObject:index forKey:type];
//         [romTypeNames addObject:[romTypeMap valueForKey:obj]];
//     }];
//}

//- (RomType)romType
//{
//    int romTypeIndex = [romTypeDropdown indexOfItem:[romTypeDropdown selectedItem]];
//    return [[romTypes objectForKey:@(romTypeIndex)] intValue];
//}
//
//- (void)setRomType:(RomType)type
//{
//    NSNumber *index = [romTypeIndices objectForKey:@(type)];
//    [romTypeDropdown selectItemWithTag:<#(NSInteger)#>]
//    [romTypeDropdown add]
//    
//    int romTypeIndex = [romTypeDropdown indexOfItem:[romTypeDropdown selectedItem]];
//    return [[romTypes objectForKey:@(romTypeIndex)] intValue];
//}

- (void)resyncUI
{
//    [slotNames removeAllObjects];
//    [slotIndices removeAllObjects];
//    
////    int romTypeIndex = [romTypeDropdown indexOfItem:[romTypeDropdown selectedItem]];
////    RomType romType = [[romTypes objectForKey:@(romTypeIndex)] intValue];
////
//    if (romType == SRAM_MATSUCHITA || romType == SRAM_S1985 ||
//        romType == ROM_S1990 || romType == ROM_KANJI || romType == ROM_GIDE ||
//        romType == ROM_TURBORTIMER || romType == ROM_TURBORIO ||
//        romType == ROM_NMS1210 || romType == ROM_F4INVERTED ||
//        romType == ROM_F4DEVICE || romType == ROM_NMS8280DIGI ||
//        romType == ROM_MOONSOUND || romType == ROM_MSXMIDI ||
//        romType == ROM_MSXAUDIODEV || romType == ROM_TURBORPCM ||
//        romType == ROM_JOYREXPSG || romType == ROM_KANJI12 ||
//        romType == ROM_JISYO || romType == ROM_OPCODEPSG ||
//        romType == ROM_OPCODESLOT || romType == ROM_SVI328FDC ||
//        romType == ROM_SVI328PRN || romType == ROM_MSXPRN ||
//        romType == ROM_SVI328RS232)
//    {
//        [slotDropdown setEnabled:NO];
//        
//        [slotNames addObject:CMLoc(@"Unmapped", @"ROM Slot")];
//        [slotIndices addObject:@(CM_MAKE_SLOT(0, 0))];
//    }
//    else
//    {
//        [slotDropdown setEnabled:YES];
//        
//        for (int i = 0; i < 4; i++)
//        {
//            if (machine->slot[i].subslotted)
//            {
//                for (int j = 0; j < 4; j++)
//                {
//                    NSString *format = CMLoc(@"Slot %1$d-%2$d", @"ROM Slot range");
//                    NSString *slotName = [NSString stringWithFormat:format, i, j];
//                    
//                    [slotNames addObject:slotName];
//                    [slotIndices addObject:@(CM_MAKE_SLOT(i, j))];
////                    if (editSlotInfo.slot == i && editSlotInfo.subslot == j) {
////                        SendDlgItemMessage(hDlg, IDC_ROMSLOT, CB_SETCURSEL, index, 0);
////                    }
//                }
//            }
//            else
//            {
//                NSString *format = CMLoc(@"Slot %1$d", @"ROM Slot");
//                NSString *slotName = [NSString stringWithFormat:format, i];
//                
//                [slotNames addObject:slotName];
//                [slotIndices addObject:@(CM_MAKE_SLOT(i, 0))];
////                if (editSlotInfo.slot == i) {
////                    SendDlgItemMessage(hDlg, IDC_ROMSLOT, CB_SETCURSEL, index, 0);
////                }
//            }
//        }
//    }
//    
//    [slotDropdown removeAllItems];
//    [slotDropdown addItemsWithTitles:slotNames];
    
    NSLog(@"Resyncing %d (%@)", currentSlotInfo.romType, romTypeDropdown);
    [[romTypeArrayController selection] setSelectedObjects:@[@(currentSlotInfo.romType)]];
}

#pragma mark - Actions

- (void)romTypeSelected:(id)sender
{
    NSLog(@"Selected: %@", [[[romTypeArrayController selectedObjects] firstObject] romType]);
//    [self resyncUI];
}

@end
