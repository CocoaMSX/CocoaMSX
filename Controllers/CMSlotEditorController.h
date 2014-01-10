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
#import <Foundation/Foundation.h>

#include "Machine.h"

@interface CMRomType: NSObject
{
    NSString *name;
    RomType romType;
}

- (id)initWithName:(NSString *)aName
           romType:(RomType)aRomType;

@end

@interface CMSlot: NSObject
{
    BOOL subslotted;
    NSString *name;
    NSInteger slotRange;
}

- (id)initWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName
              slot:(NSInteger)slot
           subslot:(NSInteger)subslot;
- (id)initWithName:(NSString *)aName
              slot:(NSInteger)slot;

@end

@interface CMSlotEditorController : NSWindowController<NSToolbarDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSPopUpButton *romTypeDropdown;
    IBOutlet NSPopUpButton *slotDropdown;
    
    IBOutlet NSArrayController *romTypeArrayController;
    IBOutlet NSArrayController *slotArrayController;
    
    RomType _selectedRomType;
    NSInteger _selectedSlot;

    Machine *machine;
}

@property (nonatomic, assign) RomType selectedRomType;
@property (nonatomic, assign) NSInteger selectedSlot;

- (IBAction)romTypeSelected:(id)sender;
- (IBAction)slotSelected:(id)sender;

- (void)reinitializeWithMachine:(Machine *)aMachine;

@end
