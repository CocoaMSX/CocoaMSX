/*****************************************************************************
** File:
**      Breakpoints.h
**
** Copyright (C) 2003-2004 Daniel Vik
**
**  This software is provided 'as-is', without any express or implied
**  warranty.  In no event will the authors be held liable for any damages
**  arising from the use of this software.
**
**  Permission is granted to anyone to use this software for any purpose,
**  including commercial applications, and to alter it and redistribute it
**  freely, subject to the following restrictions:
**
**  1. The origin of this software must not be misrepresented; you must not
**     claim that you wrote the original software. If you use this software
**     in a product, an acknowledgment in the product documentation would be
**     appreciated but is not required.
**  2. Altered source versions must be plainly marked as such, and must not be
**     misrepresented as being the original software.
**  3. This notice may not be removed or altered from any source distribution.
**
******************************************************************************
*/
#ifndef BREAKPOINTS_H
#define BREAKPOINTS_H

#include "Debugger.h"
#include <vector>
#include "symbolinfo.hpp"

class Breakpoints {
public:

    struct BreakpointInfo {
        enum Type {
            UNINITIALIZED,
            BREAKPOINT,
            WATCHPOINT_MEM,
            WATCHPOINT_VRAM,
            WATCHPOINT_IO
        };

        enum Condition {
            CONDITION_ANY,
            CONDITION_EQUALS,
            CONDITION_NOT_EQUALS,
            CONDITION_LESS_THAN,
            CONDITION_GREATER_THAN
        };

        Type type;
        bool breakpointHit;
        int address;
        char label[32];
        DbgWatchpointCondition condition;
        int referenceValue;
        int size;
        bool enabled;

        BreakpointInfo() : address(-1), enabled(false), type(UNINITIALIZED) {
            label[0] = 0;
        }
        bool operator>(const BreakpointInfo& other) {
            if (condition < other.condition) return true;
            if (condition > other.condition) return false;
            return address > other.address;
        }

        bool operator==(const BreakpointInfo& other) {
            return type == other.type && address == other.address &&
                breakpointHit == other.breakpointHit && strcmp(label, other.label) == 0 &&
                condition == other.condition && referenceValue == other.referenceValue &&
                size == other.size;
        }

        DbgDeviceType getTypeAsDeviceType() const {
            switch (type) {
            case WATCHPOINT_MEM: return DbgDeviceType::DBGTYPE_CPU;
            case WATCHPOINT_VRAM: return DbgDeviceType::DBGTYPE_VIDEO;
            case WATCHPOINT_IO: return DbgDeviceType::DBGTYPE_PORT;
            }
            return DbgDeviceType::DBGTYPE_UNKNOWN;
        }

        const char* getTypeAsString() const {
            switch (type) {
            case BREAKPOINT: return "BP";
            case WATCHPOINT_MEM: return "MEM";
            case WATCHPOINT_VRAM: return "VRAM";
            case WATCHPOINT_IO: return "IO";
            }
            return "";
        }

        const char* getSizeAsString() const {
            static char buffer[32];
            if (size == 1) {
                return "1 byte";
            }
            else {
                sprintf(buffer, "%d bytes", size);
            }
            return buffer;
        }

        const char* getConditionAsString() const {
            switch(condition) {
            case CONDITION_ANY: return "";
            case CONDITION_EQUALS: return "=";
            case CONDITION_NOT_EQUALS: return "!=";
            case CONDITION_LESS_THAN: return "<";
            case CONDITION_GREATER_THAN: return ">";
            }
            return "";
        }

        const char* getReferenceValueAsString() const {
            if (condition == CONDITION_ANY) return "";
            char formatString[32];
            sprintf(formatString, "%%.%dXh", size * 2);
            static char buffer[32];
            sprintf(buffer, formatString, address);
            return buffer;
        }
    };

    Breakpoints(SymbolInfo* symbolInfo);
    ~Breakpoints();

    virtual void disableEdit();

    void updateContent();
    void invalidateContent();
    
    // Breakpoint access methods (not for watchpoints)
    static void SetBreakpoint(int address);
    static void ClearBreakpoint(int address);
    static void ToggleBreakpointEnable(int address);
    static bool IsBreakpointUnset(int address);
    static bool IsBreakpointSet(int address);
    static bool IsBreakpointDisabled(int address);

    void enableAllBreakpoints();
    void disableAllBreakpoints();
    void clearAllBreakpoints();
    
    void isBreakpointSet(const BreakpointInfo& breakpoint);
    void setBreakpoint(const BreakpointInfo& breakpoint);
    void clearBreakpoint(const BreakpointInfo& breakpoint);
    void toggleBreakpointEnable(const BreakpointInfo& breakpoint);
 
    void setWatchpoint(BreakpointInfo& breakpoint);

    void updateBreakpoints();
    bool setStepOverBreakpoint(const UInt8* memory, UInt16 address);
    void setStepOutBreakpoint(const UInt8* memory, UInt16 address);
    int  getEnabledBpCount();
    int  getDisabledBpCount();

    // Support for temporary disassembly breakpoints
    void setRuntoBreakpoint(UInt16 address);
    void clearRuntoBreakpoint();

private:
    static const BreakpointInfo& MakeBreakpoint(int address);
    
    BreakpointInfo* find(const BreakpointInfo& breakpointInfo);
    void toggleBreakpointEnable(Breakpoints::BreakpointInfo* bi);
    
    int      runtoBreakpoint;

    std::vector<BreakpointInfo*> breakpoints;

    int    textHeight;
    int    textWidth;
    int    numBreakpoints;
    int    selectedLine;

    SymbolInfo* symbolInfo;
};

#endif //BREAKPOINTS_H
