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
#import "CMSpecialCartChooserController.h"

#include "MediaDb.h"
#include "Properties.h"

#pragma mark - CMSpecialCartNode

@interface CMSpecialCartNode : NSObject
{
@public
    NSInteger romType;
    const char *romName;
    
    NSString *displayName;
    NSMutableArray *children;
}

- (BOOL)isSelectable;
- (id)initWithLocalizedName:(NSString*)localizationKey;
- (void)addChildren:(CMSpecialCartNode*)child, ... NS_REQUIRES_NIL_TERMINATION;

@end

@implementation CMSpecialCartNode

- (id)initWithLocalizedName:(NSString *)localizationKey
{
    if ((self = [super init]))
    {
        displayName = nil;
        children = [[NSMutableArray alloc] init];
        
        if (localizationKey)
            displayName = [CMLoc(localizationKey) retain];
    }
    
    return self;
}

- (BOOL)isSelectable
{
    return children.count < 1;
}

+ (id)nodeWithLocalizedName:(NSString *)localizationKey
                    romType:(NSInteger)romType
                    romName:(const char*)romName
{
    CMSpecialCartNode *node = [[CMSpecialCartNode alloc] initWithLocalizedName:localizationKey];
    node->romType = romType;
    node->romName = romName;
    
    return [node autorelease];
}

+ (id)nodeWithLocalizedName:(NSString *)localizationKey
{
    return [[[CMSpecialCartNode alloc] initWithLocalizedName:localizationKey] autorelease];
}

- (void)addChildren:(CMSpecialCartNode*)child, ...
{
    id eachObject;
    va_list argumentList;
    
    NSMutableArray *unsorted = [NSMutableArray array];
    
    if (child)
    {
        [unsorted addObject:child];
        
        va_start(argumentList, child);
        while ((eachObject = va_arg(argumentList, id)))
            [unsorted addObject: eachObject];
        
        va_end(argumentList);
    }
    
    // Sort the list
    NSArray *sorted = [unsorted sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *displayName1 = ((CMSpecialCartNode*)obj1)->displayName;
        NSString *displayName2 = ((CMSpecialCartNode*)obj2)->displayName;
        
        NSComparisonResult result = [displayName1 compare:displayName2
                                                  options:NSNumericSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch
                                                    range:NSMakeRange(0, displayName1.length)
                                                   locale:[NSLocale currentLocale]];
        return result;
    }];
    
    [children addObjectsFromArray:sorted];
}

- (void)dealloc
{
    [displayName release];
    [children release];
    
    [super dealloc];
}

@end

#pragma mark - CMSpecialCartChooserController

@interface CMSpecialCartChooserController()

- (void)reloadCarts;
- (CMSpecialCartNode*)selectedNode;
- (CMSpecialCartNode*)nodeForColumn:(NSInteger)column
                  lastSelectedRow:(NSInteger)lastRow;

@end

@implementation CMSpecialCartChooserController

@synthesize delegate = _delegate;
@synthesize isSelectable = _isSelectable;
@synthesize cartridgeSlot = _cartridgeSlot;

#pragma mark - Initialization

- (id)init
{
    if ((self = [super initWithWindowNibName:@"SpecialCartChooser"]))
    {
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.isSelectable = NO;
    
    [browser setDoubleAction:@selector(selectCartridge:)];
    
    [self reloadCarts];
}

- (void)dealloc
{
    [root release];
    
    [super dealloc];
}

#pragma mark - NSBrowserDelegate

- (id)rootItemForBrowser:(NSBrowser *)browser
{
    return root;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
    CMSpecialCartNode *node = (CMSpecialCartNode *)item;
    return node->children.count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
    CMSpecialCartNode *node = (CMSpecialCartNode *)item;
    return [node->children objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
    CMSpecialCartNode *node = (CMSpecialCartNode *)item;
    return node->children.count < 1;
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
    CMSpecialCartNode *node = (CMSpecialCartNode *)item;
    return node->displayName;
}

- (CMSpecialCartNode*)nodeForColumn:(NSInteger)column
                  lastSelectedRow:(NSInteger)lastRow
{
    CMSpecialCartNode *current = root;
    int currentColumn = 0;
    int selectedRow;
    
    do
    {
        selectedRow = [browser selectedRowInColumn:currentColumn];
        if (currentColumn == column && lastRow >= 0)
            selectedRow = lastRow;
        
        if (selectedRow < 0)
            break;
        
        current = [current->children objectAtIndex:selectedRow];
    } while (currentColumn++ < column);
    
    return current;
}

- (CMSpecialCartNode*)selectedNode
{
    return [self nodeForColumn:browser.lastColumn
               lastSelectedRow:-1];
}

- (NSIndexSet *)browser:(NSBrowser *)browser selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes inColumn:(NSInteger)column
{
    NSInteger proposedRow = proposedSelectionIndexes.firstIndex;
    CMSpecialCartNode *proposedNode = [self nodeForColumn:column
                                        lastSelectedRow:proposedRow];
    
    // Toggle the OK button
    self.isSelectable = [proposedNode isSelectable];
    
    return proposedSelectionIndexes;
}

#pragma mark - Methods

- (void)reloadCarts
{
    [root release];
    root = [[CMSpecialCartNode alloc] initWithLocalizedName:nil];
    
    CMSpecialCartNode *gameReaderCart = [CMSpecialCartNode nodeWithLocalizedName:@"GameReaderCartridge"
                                                                     romType:ROM_GAMEREADER
                                                                     romName:CARTNAME_GAMEREADER];
    CMSpecialCartNode *joyrexCart = [CMSpecialCartNode nodeWithLocalizedName:@"JoyrexPsgCartridge"
                                                                 romType:ROM_JOYREXPSG
                                                                 romName:CARTNAME_JOYREXPSG];
    CMSpecialCartNode *sccCart = [CMSpecialCartNode nodeWithLocalizedName:@"SccCartridge"
                                                              romType:ROM_SCC
                                                              romName:CARTNAME_SCC];
    CMSpecialCartNode *sccICart = [CMSpecialCartNode nodeWithLocalizedName:@"SccICartridge"
                                                               romType:ROM_SCCPLUS
                                                               romName:CARTNAME_SCCPLUS];
    
    CMSpecialCartNode *eseSccCart = [CMSpecialCartNode nodeWithLocalizedName:@"EseSccCartridge"];
    [eseSccCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart128kB"
                                    romType:SRAM_ESESCC128
                                    romName:CARTNAME_ESESCC128],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart256kB"
                                    romType:SRAM_ESESCC256
                                    romName:CARTNAME_ESESCC256],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart512kB"
                                    romType:SRAM_ESESCC512
                                    romName:CARTNAME_ESESCC512], nil];
    
    // IDE
    CMSpecialCartNode *ideCart = [CMSpecialCartNode nodeWithLocalizedName:@"IdeCartridge"];
    [ideCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"SunriseCartridge"
                                    romType:ROM_SUNRISEIDE
                                    romName:CARTNAME_SUNRISEIDE],
     [CMSpecialCartNode nodeWithLocalizedName:@"BeerCartridge"
                                    romType:ROM_BEERIDE
                                    romName:CARTNAME_BEERIDE],
     [CMSpecialCartNode nodeWithLocalizedName:@"GideCartridge"
                                    romType:ROM_GIDE
                                    romName:CARTNAME_GIDE], nil];
    
    // SCSI
    CMSpecialCartNode *scsiCart = [CMSpecialCartNode nodeWithLocalizedName:@"ScsiCartridge"];
    CMSpecialCartNode *megaScsiCart = [CMSpecialCartNode nodeWithLocalizedName:@"MegaScsiCartridge"];
    [megaScsiCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart128kB"
                                    romType:SRAM_MEGASCSI128
                                    romName:CARTNAME_MEGASCSI128],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart256kB"
                                    romType:SRAM_MEGASCSI256
                                    romName:CARTNAME_MEGASCSI256],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart512kB"
                                    romType:SRAM_MEGASCSI512
                                    romName:CARTNAME_MEGASCSI512],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart1Mb"
                                    romType:SRAM_MEGASCSI1MB
                                    romName:CARTNAME_MEGASCSI1MB], nil];
    CMSpecialCartNode *waveScsiCart = [CMSpecialCartNode nodeWithLocalizedName:@"WaveScsiCartridge"];
    [waveScsiCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart128kB"
                                    romType:SRAM_WAVESCSI128
                                    romName:CARTNAME_WAVESCSI128],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart256kB"
                                    romType:SRAM_WAVESCSI256
                                    romName:CARTNAME_WAVESCSI256],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart512kB"
                                    romType:SRAM_WAVESCSI512
                                    romName:CARTNAME_WAVESCSI512],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart1Mb"
                                    romType:SRAM_WAVESCSI1MB
                                    romName:CARTNAME_WAVESCSI1MB], nil];
    [scsiCart addChildren:megaScsiCart, waveScsiCart,
     [CMSpecialCartNode nodeWithLocalizedName:@"GoudaScsiCartridge"
                                    romType:ROM_GOUDASCSI
                                    romName:CARTNAME_GOUDASCSI], nil];
    
    // Nowind
    CMSpecialCartNode *nowindCart = [CMSpecialCartNode nodeWithLocalizedName:@"NowindUsbController"];
    [nowindCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"MsxDos1Cartridge"
                                    romType:ROM_NOWIND
                                    romName:CARTNAME_NOWINDDOS1],
     [CMSpecialCartNode nodeWithLocalizedName:@"MsxDos2Cartridge"
                                    romType:ROM_NOWIND
                                    romName:CARTNAME_NOWINDDOS2], nil];
    
    CMSpecialCartNode *fmpacCart = [CMSpecialCartNode nodeWithLocalizedName:@"FmPacCartridge"
                                                                romType:ROM_FMPAC
                                                                romName:CARTNAME_FMPAC];
    CMSpecialCartNode *pacCart = [CMSpecialCartNode nodeWithLocalizedName:@"PacCartridge"
                                                              romType:ROM_PAC
                                                              romName:CARTNAME_PAC];
    
    CMSpecialCartNode *hbiCart = [CMSpecialCartNode nodeWithLocalizedName:@"SonyHbi55Cartridge"
                                                              romType:ROM_SONYHBI55
                                                              romName:CARTNAME_SONYHBI55];
    CMSpecialCartNode *nmsCart = [CMSpecialCartNode nodeWithLocalizedName:@"PhilipsNms1210Interface"
                                                              romType:ROM_NMS1210
                                                              romName:CARTNAME_NMS1210];
    
    // External RAM
    CMSpecialCartNode *externRamCart = [CMSpecialCartNode nodeWithLocalizedName:@"ExternalRamCartridge"];
    [externRamCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart16kB"
                                    romType:ROM_EXTRAM16KB
                                    romName:CARTNAME_EXTRAM16KB],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart32kB"
                                    romType:ROM_EXTRAM32KB
                                    romName:CARTNAME_EXTRAM32KB],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart48kB"
                                    romType:ROM_EXTRAM48KB
                                    romName:CARTNAME_EXTRAM48KB],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart64kB"
                                    romType:ROM_EXTRAM64KB
                                    romName:CARTNAME_EXTRAM64KB],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart512kB"
                                    romType:ROM_EXTRAM512KB
                                    romName:CARTNAME_EXTRAM512KB],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart1Mb"
                                    romType:ROM_EXTRAM1MB
                                    romName:CARTNAME_EXTRAM1MB],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart2Mb"
                                    romType:ROM_EXTRAM2MB
                                    romName:CARTNAME_EXTRAM2MB],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart4MB"
                                    romType:ROM_EXTRAM4MB
                                    romName:CARTNAME_EXTRAM4MB], nil];
    
    // Mega RAM
    CMSpecialCartNode *megaRamCart = [CMSpecialCartNode nodeWithLocalizedName:@"MegaRamCartridge"];
    [megaRamCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart128kB"
                                    romType:ROM_MEGARAM128
                                    romName:CARTNAME_MEGARAM128],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart256kB"
                                    romType:ROM_MEGARAM256
                                    romName:CARTNAME_MEGARAM256],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart512kB"
                                    romType:ROM_MEGARAM512
                                    romName:CARTNAME_MEGARAM512],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart768kB"
                                    romType:ROM_MEGARAM768
                                    romName:CARTNAME_MEGARAM768],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart2Mb"
                                    romType:ROM_MEGARAM2M
                                    romName:CARTNAME_MEGARAM2M], nil];
    
    // Ese-RAM
    CMSpecialCartNode *eseRamCart = [CMSpecialCartNode nodeWithLocalizedName:@"EseRamCartridge"];
    [eseRamCart addChildren:
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart128kB"
                                    romType:SRAM_ESERAM128
                                    romName:CARTNAME_ESERAM128],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart256kB"
                                    romType:SRAM_ESERAM256
                                    romName:CARTNAME_ESERAM256],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart512kB"
                                    romType:SRAM_ESERAM512
                                    romName:CARTNAME_ESERAM512],
     [CMSpecialCartNode nodeWithLocalizedName:@"Cart1Mb"
                                    romType:SRAM_ESERAM1MB
                                    romName:CARTNAME_ESERAM1MB], nil];
    
    CMSpecialCartNode *megaFlashSccCart = [CMSpecialCartNode nodeWithLocalizedName:@"MegaFlashRomScc"
                                                                       romType:ROM_MEGAFLSHSCC
                                                                       romName:CARTNAME_MEGAFLSHSCC];
    
    [root addChildren:gameReaderCart, joyrexCart, sccCart, sccICart, eseSccCart,
     ideCart, scsiCart, nowindCart, fmpacCart, pacCart, hbiCart, nmsCart,
     externRamCart, megaRamCart, eseRamCart, megaFlashSccCart, nil];
}

- (void)showSheetForWindow:(NSWindow *)window
             cartridgeSlot:(NSInteger)cartSlot
{
    self.cartridgeSlot = cartSlot;
    [self reloadCarts];
    
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

- (void)dismissChooser:(id)sender
{
    [NSApp stopModal];
}

- (void)selectCartridge:(id)sender
{
    CMSpecialCartNode *selected =[self selectedNode];
    if ([selected isSelectable])
    {
        [self.delegate cartSelectedOfType:selected->romType
                                  romName:selected->romName
                                     slot:self.cartridgeSlot];
        
        [NSApp stopModal];
    }
}

@end
