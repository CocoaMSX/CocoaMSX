/*****************************************************************************
** File:        Breakpoints.cpp
**
** Author:      Daniel Vik
**
** Copyright (C) 2003-2012s Daniel Vik
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
#include "breakpoints.hpp"
#include "disassemble.hpp"

#ifndef max
#define max(a,b) ((a) > (b) ? (a) : (b))
#endif
#ifndef min
#define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#define TB_NEW_BREAKPOINT  37030
#define TB_NEW_WATCHPOINT  37031
#define TB_DELETE_BREAKPOINT  37032

static Breakpoints* breakpointsInstance = NULL;

Breakpoints::Breakpoints(SymbolInfo* symInfo) :
    selectedLine(-1), runtoBreakpoint(-1),
    symbolInfo(symInfo)
{
    breakpointsInstance = this;
}

Breakpoints::~Breakpoints()
{
    breakpointsInstance = NULL;
}

void Breakpoints::disableEdit()
{
    //DbgWindow::disableEdit();
}

void Breakpoints::updateContent()
{
    BreakpointInfo* bi;
    if (selectedLine >= 0 && selectedLine < breakpoints.size()) {
        bi = breakpoints[selectedLine];
    }

    selectedLine = -1;

    int firstHitIndex = -1;
    for (int i = 0; i < breakpoints.size(); ++i) {
        if (breakpoints[i]->breakpointHit) {
            firstHitIndex = i;
            break;
        }
        if (breakpoints[i] == bi) {
            selectedLine = i;
        }
    }
    if (firstHitIndex >= 0) {
        selectedLine = firstHitIndex;
    }
}


void Breakpoints::SetBreakpoint(int address) {
    if (breakpointsInstance != NULL) {
        breakpointsInstance->setBreakpoint(MakeBreakpoint(address));
    }
}

void Breakpoints::ClearBreakpoint(int address) {
    if (breakpointsInstance != NULL) {
        breakpointsInstance->clearBreakpoint(MakeBreakpoint(address));
    }
}

void Breakpoints::ToggleBreakpointEnable(int address) {
    if (breakpointsInstance != NULL) {
        breakpointsInstance->toggleBreakpointEnable(MakeBreakpoint(address));
    }
}

bool Breakpoints::IsBreakpointUnset(int address) {
    if (breakpointsInstance == NULL) return true;
    BreakpointInfo* bi = breakpointsInstance->find(MakeBreakpoint(address));
    return bi == NULL;
}

bool Breakpoints::IsBreakpointSet(int address) {
    if (breakpointsInstance == NULL) return false;
    BreakpointInfo* bi = breakpointsInstance->find(MakeBreakpoint(address));
    return bi != NULL && bi->enabled;
}

bool Breakpoints::IsBreakpointDisabled(int address) {
    if (breakpointsInstance == NULL) return false;
    BreakpointInfo* bi = breakpointsInstance->find(MakeBreakpoint(address));
    return bi != NULL && !bi->enabled;
}

Breakpoints::BreakpointInfo* Breakpoints::find(const Breakpoints::BreakpointInfo& breakpointInfo) {
    for (std::vector<BreakpointInfo*>::iterator i = breakpoints.begin(); i != breakpoints.end(); ++i) {
        if ((*i)->address == breakpointInfo.address && (*i)->type == breakpointInfo.type) {
            return *i;
        }
    }
    return NULL;
}

const Breakpoints::BreakpointInfo& Breakpoints::MakeBreakpoint(int address) {
    static Breakpoints::BreakpointInfo breakpointInfo;
    breakpointInfo.type = BreakpointInfo::BREAKPOINT;
    breakpointInfo.address = address;
    return breakpointInfo;
}

void Breakpoints::setBreakpoint(const Breakpoints::BreakpointInfo& breakpointInfo) {
    BreakpointInfo* bi = find(breakpointInfo);
    if (bi == NULL) {
        bi = new BreakpointInfo(breakpointInfo);
        bi->enabled = false;
        // Insert new breakpoint sorted.
        std::vector<BreakpointInfo*>::iterator i = breakpoints.begin();
        for (; i != breakpoints.end(); ++i) {
            if (*(*i) > *bi) {
                break;
            }
        }
        breakpoints.insert(i, bi);
    }
    else if (bi->enabled) {
        return;
    }
    toggleBreakpointEnable(bi);
}

void Breakpoints::clearBreakpoint(const Breakpoints::BreakpointInfo& breakpointInfo)
{
    BreakpointInfo* bi = find(breakpointInfo);
    if (bi == NULL) {
        return;
    }
    if (bi->enabled) {
        toggleBreakpointEnable(bi);
    }
    for (std::vector<BreakpointInfo*>::iterator i = breakpoints.begin(); i != breakpoints.end(); ++i) {
        if (*i == bi) {
            breakpoints.erase(i);
            break;
        }
    }
}

void Breakpoints::toggleBreakpointEnable(const Breakpoints::BreakpointInfo& breakpointInfo)
{
    BreakpointInfo* bi = find(breakpointInfo);
    if (bi != NULL) {
        toggleBreakpointEnable(bi);
    }
}

void Breakpoints::toggleBreakpointEnable(Breakpoints::BreakpointInfo* bi)
{
    if (bi == NULL) {
        return;
    }

    if (bi->enabled) {
        bi->enabled = false;
        if (bi->type == BreakpointInfo::BREAKPOINT) {
            dbgClearBreakpoint(bi->address);
        }
        else {
            dbgClearWatchpoint(bi->getTypeAsDeviceType(), bi->address);
        }
    }
    else {
        bi->enabled = true;
        if (bi->type == BreakpointInfo::BREAKPOINT) {
            dbgSetBreakpoint(bi->address);
        }
        else {
            dbgSetWatchpoint(bi->getTypeAsDeviceType(), bi->address, bi->condition, bi->referenceValue, bi->size);
        }
    }
}

void Breakpoints::clearAllBreakpoints()
{
    while (!breakpoints.empty()) {
        delete breakpoints.front();
        breakpoints.erase(breakpoints.begin());
    }
}

int Breakpoints::getEnabledBpCount() {
    int count = 0;
    for (std::vector<BreakpointInfo*>::iterator i = breakpoints.begin(); i != breakpoints.end(); ++i) {
        if (!(*i)->enabled) {
            count++;
        }
    }
    return count;
}

int Breakpoints::getDisabledBpCount() {
    return breakpoints.size() - getEnabledBpCount();
}

void Breakpoints::enableAllBreakpoints()
{
    for (std::vector<BreakpointInfo*>::iterator i = breakpoints.begin(); i != breakpoints.end(); ++i) {
        if (!(*i)->enabled) {
            toggleBreakpointEnable(*i);
        }
    }
}

void Breakpoints::disableAllBreakpoints()
{
    for (std::vector<BreakpointInfo*>::iterator i = breakpoints.begin(); i != breakpoints.end(); ++i) {
        if ((*i)->enabled) {
            toggleBreakpointEnable(*i);
        }
    }
}

void Breakpoints::updateBreakpoints()
{
    for (std::vector<BreakpointInfo*>::iterator i = breakpoints.begin(); i != breakpoints.end(); ++i) {
        if ((*i)->enabled) {
            (*i)->enabled = false;
            toggleBreakpointEnable(*i);
        }
    }
}

void Breakpoints::setStepOutBreakpoint(const UInt8* memory, UInt16 address)
{
    char str[128];
    setRuntoBreakpoint((address + Disassembly::dasm(symbolInfo, memory, address, str)) & 0xffff);
}

bool Breakpoints::setStepOverBreakpoint(const UInt8* memory, UInt16 address)
{
    char str[128];
    UInt16 delta = Disassembly::dasm(symbolInfo, memory, address, str);
    // If call or rst instruction we need to set a runto breakpoint
    // otherwise its just a regular single step
    bool step = strncmp(str, "call", 4) != 0 &&
                strncmp(str, "ldir", 4) != 0 &&
                strncmp(str, "lddr", 4) != 0 &&
                strncmp(str, "cpir", 4) != 0 &&
                strncmp(str, "inir", 4) != 0 &&
                strncmp(str, "indr", 4) != 0 &&
                strncmp(str, "otir", 4) != 0 &&
                strncmp(str, "otdr", 4) != 0 &&
                strncmp(str, "rst",  3) != 0;
    if (!step) {
        setRuntoBreakpoint((address + delta) & 0xffff);
    }
    return step;
}

void Breakpoints::setRuntoBreakpoint(UInt16 address)
{
    if (address < 0) {
        return;
    }

    runtoBreakpoint = address;
    dbgSetBreakpoint(runtoBreakpoint);
}

void Breakpoints::clearRuntoBreakpoint()
{
    if (runtoBreakpoint >= 0) {
        if (!IsBreakpointSet(runtoBreakpoint)) {
            dbgClearBreakpoint(runtoBreakpoint);
        }
        runtoBreakpoint = -1;
    }
}
