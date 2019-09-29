//
//  CMDebugger.m
//  CocoaMSX
//
//  Created by Mario Smit on 17/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#import "CMDebugger.h"
#import "CMBreakpoints.h"
#include "Debugger.h"


@implementation CMDebuggerController
{
    BlueDebugger* pDebugger;
}

- (IBAction)toolbarStart:(id)sender {
    dbgRun();
}
- (IBAction)toolbarStop:(id)sender {
    //[breakpoints setBreakpoint:0x416d]; //DRV_VERSION       5
    [breakpoints setBreakpoint:0x416d]; // DRV_INIT         1,2
    //[breakpoints setBreakpoint:0x465f]; // DRV_CONFIG       3,8
    //[breakpoints setBreakpoint:0x42a9]; // DEV_RW           6,7,8
    //[breakpoints setBreakpoint:0x480F]; // DISK_READ
    //[breakpoints setBreakpoint:0x4730]; // DEV_INFO
    //[breakpoints setBreakpoint:0x4405]; // DEV_STATUS
    //[breakpoints setBreakpoint:0x442B]; // LUN_INFO         4,9
    //[breakpoints setBreakpoint:0x6E8A]; // TRY_MSX_DOS
    //[breakpoints setBreakpoint:0x3BEB]; // rdwr_devcmd
    //[breakpoints setBreakpoint:0x39b6]; // CALL_UNIT
    //[breakpoints setBreakpoint:0x3411]; // RW_UNIT
    //[breakpoints setBreakpoint:0x2B0B]; // BF_SECTOR
    //[breakpoints setBreakpoint:0x1AC6]; // DI_NEXT
    //[breakpoints setBreakpoint:0x1A87]; // DI_FIRST
    //[breakpoints setBreakpoint:0x185B]; // FND_FIRST
    //[breakpoints setBreakpoint:0x17C4]; // LOC_FIB
    //[breakpoints setBreakpoint:0x1BE6]; // F_OPEN
    //[breakpoints setBreakpoint:0x39A1]; // READ_UNIT
    //[breakpoints setBreakpoint:0x35FB]; // bupc
    //[breakpoints setBreakpoint:0x35E8]; // build_upb_common
    
    /*
     4130: c3 e3 44     jp     #4539      DRV_TIMI
     4133: c3 fb 45     jp     #4651      DRV_VERSION
     4136: c3 e4 44     jp     #453a      DRV_INIT
     4139: c3 02 46     jp     #4658      DRV_BASSTAT
     413C: c3 05 46     jp     #465b      DRV_BASDEV
     413F: c3 07 46     jp     #465d      DRV_EXTBIO
     4142: c3 08 46     jp     #465e      DRV_DIRECT1
     4145: c3 08 46     jp     #465e      DRV_DIRECT2
     4148: c3 08 46     jp     #465e      DRV_DIRECT2
     414B: c3 08 46     jp     #465e      DRV_DIRECT3
     414E: c3 08 46     jp     #465e      DRV_DIRECT4
     4151: c3 83 46     jp     #465f      DRV_CONFIG
     4160: c3 0f 47     jp     #4676      DEV_RW
     4163: c3 eb 47     jp     #4730      DEV_INFO
     4166: c3 bd 48     jp     #47d2      DEV_STATUS
     4169: c3 8f 49     jp     #482e      LUN_INFO
     */
    return;
    
    dbgStop();
}
- (IBAction)toolbarPauze:(id)sender {
    dbgPause();
}
- (IBAction)toolbarStep:(id)sender {
    dbgStep();
}
- (IBAction)toolbarStepOut:(id)sender {
   dbgStepBack();
}
- (IBAction)toolbarStepOver:(id)sender {
    //[breakpoints setBreakpoint:0x4132];
    //dbgRun();
    //return;
    
    bool step = [breakpoints setStepOverBreakpoint:[myDebuggerController->disassembler getMemory] withPC:[myDebuggerController->disassembler getPC]];

    if (step) {
        dbgStep();
    }
    else {
        dbgRun();
    }
}
- (IBAction)toolbarPC:(id)sender {
}

void updateDeviceState(NSScrollView* disassemblyView)
{
    bool disassemblyUpdated = false;
    
    if (dbgGetState() == DBG_RUNNING) {
        return;
    }
    
    DbgSnapshot* snapshot = dbgSnapshotCreate();
    if (snapshot != NULL) {
        int deviceCount = dbgSnapshotGetDeviceCount(snapshot);
        
        for (int i = 0; i < deviceCount; i++) {
            DbgDevice* device = (DbgDevice*) dbgSnapshotGetDevice(snapshot, i);
            
            int memCount = dbgDeviceGetMemoryBlockCount(device);
            /*
            int j;
            for (j = 0; j < memCount; j++) {
                DbgMemoryBlock* mem = (DbgMemoryBlock*) dbgDeviceGetMemoryBlock(device, j);
            }
            
            int regBankCount = dbgDeviceGetRegisterBankCount(device);
            for (j = 0; j < regBankCount; j++) {
                DbgRegisterBank* regBank = (DbgRegisterBank*) dbgDeviceGetRegisterBank(device, j);
            }
            
            int ioPortsCount = dbgDeviceGetIoPortsCount(device);
            for (j = 0; j < ioPortsCount; j++) {
                DbgIoPorts* ioPorts = (DbgIoPorts*) dbgDeviceGetIoPorts(device, j);
            }
            */
            if (device->type == DBGTYPE_CPU && memCount > 0) {
                UInt16 pc = 0;
                UInt16 sp = 0;
                
                NSMutableAttributedString* str = [[NSMutableAttributedString alloc] init];
                NSColor* color_default = NSColor.blackColor;
                NSColor* color_light = NSColor.grayColor;
                NSFont* font = [NSFont fontWithName:@"Courier" size:14];
                
                DbgMemoryBlock* mem = (DbgMemoryBlock*) dbgDeviceGetMemoryBlock(device, 0);
                if (mem->size == 0x10000)
                {
                    DbgRegisterBank* regBank = (DbgRegisterBank*) dbgDeviceGetRegisterBank(device, 0);
                    for (UInt32 k = 0; k < regBank->count; k++) {
                        UInt8 memval=0;
                        bool sign,zero,parity,carry = false;
                        if (0 == strcmp("AF", regBank->reg[k].name))
                        {
                            sign = regBank->reg[k].value & 0b10000000;
                            zero = regBank->reg[k].value & 0b01000000;
                            parity = regBank->reg[k].value & 0b00000100;
                            carry = regBank->reg[k].value & 0b00000001;
                            
                            NSMutableAttributedString* rg = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"S Z P C\n"]
                                attributes:@{NSForegroundColorAttributeName:color_light}];
                            if (sign)
                                [rg addAttribute:NSForegroundColorAttributeName value:color_default range:NSMakeRange(0, 1)];
                            if (zero)
                                [rg addAttribute:NSForegroundColorAttributeName value:color_default range:NSMakeRange(2, 1)];
                            if (parity)
                                [rg addAttribute:NSForegroundColorAttributeName value:color_default range:NSMakeRange(4, 1)];
                            if (carry)
                                [rg addAttribute:NSForegroundColorAttributeName value:color_default range:NSMakeRange(6, 1)];
                            [str appendAttributedString:[[NSAttributedString alloc] initWithString:@"FLAG: "]];
                            [str appendAttributedString:rg];
                            NSAttributedString* rg2 = [[NSAttributedString alloc] initWithString:
                            [NSString stringWithFormat:@"%4c: %02X\n",'A',(regBank->reg[k].value & 0xff00)>>8]
                                attributes:@{NSForegroundColorAttributeName:color_default}];
                            [str appendAttributedString:rg2];
                        }
                        else if (0 == strcmp("BC", regBank->reg[k].name) ||
                            0 == strcmp("DE", regBank->reg[k].name) ||
                            0 == strcmp("HL", regBank->reg[k].name) ||
                            0 == strcmp("IX", regBank->reg[k].name) ||
                            0 == strcmp("IY", regBank->reg[k].name)) {
                            memval = mem->memory[regBank->reg[k].value];
                            
                            NSAttributedString* rg = [[NSAttributedString alloc] initWithString:
                            [NSString stringWithFormat:@"%4s: %04X -> (%02X)\n",regBank->reg[k].name,regBank->reg[k].value,memval]
                                attributes:@{NSForegroundColorAttributeName:color_default}];
                            [str appendAttributedString:rg];
                        }
                        else
                        {
                            NSAttributedString* rg = [[NSAttributedString alloc] initWithString:
                            [NSString stringWithFormat:@"%4s: %04X\n",regBank->reg[k].name,regBank->reg[k].value]
                                attributes:@{NSForegroundColorAttributeName:color_default}];
                            [str appendAttributedString:rg];
                        }
                        
                        if (0 == strcmp("PC", regBank->reg[k].name)) {
                            pc = (UInt16)regBank->reg[k].value;
                        }
                        if (0 == strcmp("SP", regBank->reg[k].name)) {
                            sp = (UInt16)regBank->reg[k].value;
                        }
                    }
                    [str addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [str length])];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSTextView* doc = myDebuggerController->registersView.documentView;
                        [doc.textStorage setAttributedString: str];
                    });
                    
                    NSMutableAttributedString* str = [myDebuggerController->disassembler updateContentWithMemory:mem->memory program_counter:pc];
                    unsigned long start =[myDebuggerController->disassembler charStart];
                    unsigned long end =[myDebuggerController->disassembler charEnd];
                    NSRange rng = NSMakeRange(start, end-start);
                    NSColor* color_back = NSColor.redColor;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSTextView* doc = disassemblyView.documentView;
                        [str addAttribute:NSBackgroundColorAttributeName value:color_back range:rng];
                        
                        NSTextStorage *newStorage = [[NSTextStorage alloc] initWithAttributedString: str];
                        [doc.layoutManager replaceTextStorage: newStorage];
                        [doc scrollRangeToVisible:rng];
                    });
                    disassemblyUpdated = true;
                }
                
                
                
                NSMutableAttributedString* strStack = [[NSMutableAttributedString alloc] init];
                DbgCallstack* stack = (DbgCallstack*) dbgDeviceGetCallstack(device, 0);
                if (stack != NULL) {
                    for (int index = stack->size - 1; index >= 0; index--)
                    {
                        UInt16 addr = (UInt16)stack->callstack[index];
                        char text[128]="";
                        UInt16 addr2 = [myDebuggerController->disassembler dasm:mem->memory pc:(addr-1) dest:text];
                        NSAttributedString* stk = [[NSAttributedString alloc] initWithString:
                                                  [NSString stringWithFormat:@"%.4X: %s\n",addr2,text]
                                                       attributes:@{NSForegroundColorAttributeName:color_default}];
                        [strStack appendAttributedString:stk];
                    }
                }
                [strStack addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [strStack length])];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSTextView* doc = myDebuggerController->callstackView.documentView;
                    [doc.textStorage setAttributedString: strStack];
                });
            }
        }
        
        //memory->updateContent(snapshot);
        //periRegisters->updateContent(snapshot);
        //ioPorts->updateContent(snapshot);
    }
}

void onEmulatorStart(void* pTest)
{
    if (myDebuggerController==nil)
        return;
    
    [myDebuggerController->disassemblyView.documentView setString:@"nothing to show"];
    [myDebuggerController->registersView.documentView setString:@"also nothing to show"];
}
void onEmulatorStop(void* pTest)
{
    if (myDebuggerController==nil)
        return;
    
    [myDebuggerController->disassemblyView.documentView setString:@"nothing to show"];
    [myDebuggerController->registersView.documentView setString:@"also nothing to show"];
}

void onEmulatorPause(void* pTest)
{
    [myDebuggerController->breakpoints clearRunToBreakpoint];
    updateDeviceState(myDebuggerController->disassemblyView);
}
void onEmulatorResume(void* pTest)
{
    if (myDebuggerController==nil)
        return;
    
    [myDebuggerController->disassemblyView.documentView setString:@"nothing to show"];
    [myDebuggerController->registersView.documentView setString:@"also nothing to show"];
}
void onEmulatorReset(void* pTest)
{
    
}
void onDebugTrace(void* pTest, const char* test)
{
    
}
void onDebugSetBp(void* pTest, UInt16 a, UInt16 b, UInt16 c)
{
    
}
- (id)init
{
    pDebugger = nil;
    if ((self = [super initWithWindowNibName:@"Debugger"]))
    {

    }
    disassembler = [[CMDisassemble alloc] init];
    breakpoints = [[CMBreakpoints alloc] init];
    myDebuggerController = self;
    return self;
}

- (void)dealloc
{
    if (pDebugger) {debuggerDestroy (pDebugger);pDebugger = NULL; };
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    pDebugger = debuggerCreate( onEmulatorStart,
                               onEmulatorStop,
                               onEmulatorPause,
                               onEmulatorResume,
                               onEmulatorReset,
                               onDebugTrace,
                               onDebugSetBp,
                               nil);
}

@end
