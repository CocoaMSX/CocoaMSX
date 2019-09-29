//
//  CMDisassemble.m
//  CocoaMSX
//
//  Created by Mario Smit on 17/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#include "CMDisassemble.h"
#include "disassemble.hpp"

@interface CMDisassemble () {
    Disassembly* disassembly;
    SymbolInfo* symbolInfo;
}
@end

@implementation CMDisassemble
- (id)init
{
    self = [super init];
    if (self)
    {
        symbolInfo = new SymbolInfo();
        disassembly = new Disassembly(symbolInfo);
        if (!disassembly) self = nil;
    }
    return self;
}
- (void)dealloc
{
    NSLog (@"CMDisassemble: destroyed");
    delete disassembly;
    delete symbolInfo;
}
- (NSMutableAttributedString*) buildString
{
    struct LineInfo* li = disassembly->getLineInfo();
    NSMutableAttributedString* str = [[NSMutableAttributedString alloc] init];
    //NSColor* color_accent = [NSColor colorWithDeviceRed:(float)62/255 green:(float)133/255 blue:(float)197/255 alpha:1.0];
    NSColor* color_accent = NSColor.systemGrayColor;
    NSColor* color_default = NSColor.blackColor;
    for (int i=0; i<disassembly->getNrLines();i++)
    {
        NSAttributedString* addr = [[NSAttributedString alloc] initWithString:
                                  [NSString stringWithFormat:@"%s ",li[i].addr]
                                                                 attributes:@{NSForegroundColorAttributeName:color_default}];;
        NSAttributedString* data = [[NSAttributedString alloc] initWithString:
                                    [NSString stringWithFormat:@"%s ",li[i].dataText]
                                                                   attributes:@{NSForegroundColorAttributeName:color_accent}];
        NSAttributedString* text = [[NSAttributedString alloc] initWithString:
                                    [NSString stringWithFormat:@"%s\n",li[i].text]
                                                                   attributes:@{NSForegroundColorAttributeName:color_default}];;
        if (li[i].haspc)
        {
            _charStart = [str length];
            //NSBackgroundColorAttributeName
        }
        [str appendAttributedString:addr];
        [str appendAttributedString:data];
        [str appendAttributedString:text];
        if (li[i].haspc)
        {
            _charEnd = [str length];
        }
    }
    NSFont* font = [NSFont fontWithName:@"Courier" size:14];
    [str addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [str length])];
    
    return str;
}
- (NSMutableAttributedString*)updateContentWithMemory:(UInt8*)memory program_counter:(UInt16)pc
{
    disassembly->updateContent(memory, pc);
    return [self buildString];
}
- (const UInt8*) getMemory
{
    return disassembly->getMemory();
}
- (UInt16) getPC
{
    return disassembly->getPc();
}
- (int) dasm:(const UInt8*)memory pc:(UInt16) PC dest:(char*)dest
{
    return disassembly->dasm(PC, dest);
}
@end
