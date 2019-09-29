//
//  CMBreakpoints.m
//  CocoaMSX
//
//  Created by Mario Smit on 22/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#include "CMBreakpoints.h"
#include "breakpoints.hpp"

@interface CMBreakpoints () {
    Breakpoints* breakpoints;
    SymbolInfo* symbolInfo;
}
@end

@implementation CMBreakpoints
- (id)init
{
    self = [super init];
    if (self)
    {
        symbolInfo = new SymbolInfo();
        breakpoints = new Breakpoints (symbolInfo);
        if (!breakpoints) self = nil;
    }
    return self;
}
- (void)dealloc
{
    NSLog (@"CMBreakpoints: destroyed");
    delete breakpoints;
    delete symbolInfo;
}

- (bool) setStepOverBreakpoint:(UInt8*)memory withPC:(UInt16)pc
{
    return breakpoints->setStepOverBreakpoint(memory, pc);
}
- (void) setBreakpoint:(UInt16) address
{
    breakpoints->SetBreakpoint(address);
}
- (void) clearRunToBreakpoint
{
    breakpoints->clearRuntoBreakpoint();
}

@end
