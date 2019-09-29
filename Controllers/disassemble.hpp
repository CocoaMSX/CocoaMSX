//
//  disassemble.h
//  CocoaMSX
//
//  Created by Mario Smit on 17/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#ifndef disassemble_h
#define disassemble_h

#include "symbolinfo.hpp"

struct LineInfo {
    UInt16 address;
    bool isLabel;
    bool haspc;
    char text[128];
    int  textLength;
    char addr[48];
    int  addrLength;
    char dataText[48];
    int  dataTextLength;
};

class Disassembly
{
public:
    
    
    Disassembly(SymbolInfo* symInfo/*, Breakpoints* breakpoints*/);
    ~Disassembly();
    
    void refresh();
    UInt16 dasm(UInt16 pc, char* dest);
    static int dasm(SymbolInfo* symbolInfo, const UInt8* memory, UInt16 PC, char* dest);
    static UInt16 GetPc();
    void updateContent(UInt8* memory, UInt16 pc);
    void invalidateContent();
    void setCursor(UInt16 address);
    UInt16 getPc() { return backupPc; }
    const UInt8* getMemory() { return backupMemory; }
    int getCurrentAddress() { return currentLine < 0 ? -1 : lineInfo[currentLine].address; }
    //bool isBpOnCcursor() { return currentLine >= 0 && !Breakpoints::IsBreakpointUnset(lineInfo[currentLine].address); }
    bool isCursorPresent()    { return currentLine >= 0; }
    bool writeToFile(const char* fileName);
    LineInfo* getLineInfo () {return (LineInfo*) &lineInfo;}
    int getNrLines () {return lineCount-1;}
    int getCurrentLine () {return currentLine;}
    
private:
    int      programCounter;
    int      firstVisibleLine;
    int      lineCount;
    int      currentLine;
    LineInfo lineInfo[0x20000];
    int      linePos;
    bool     hasKeyboardFocus;
    
    UInt8 backupMemory[0x10000];
    UInt16 backupPc;
    
    SymbolInfo* symbolInfo;
    //Breakpoints* breakpoints;
};
#endif /* disassemble_h */
