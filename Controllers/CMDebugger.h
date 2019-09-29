//
//  CMDebugger.h
//  CocoaMSX
//
//  Created by Mario Smit on 17/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#ifndef CMDebugger_h
#define CMDebugger_h

#import "CMDisassemble.h"
#import "CMBreakpoints.h"

@interface CMDebuggerController : NSWindowController<NSWindowDelegate>
{
    CMDisassemble* disassembler;
    CMBreakpoints* breakpoints;
    
    __weak IBOutlet NSScrollView *disassemblyView;
    __weak IBOutlet NSScrollView *registersView;
    __weak IBOutlet NSScrollView *callstackView;
    __weak IBOutlet NSTextField *addressTextField;
}
@end
CMDebuggerController* myDebuggerController;

#endif /* CMDebugger_h */
