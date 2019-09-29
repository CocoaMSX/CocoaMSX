//
//  symbolinfo.cpp
//  CocoaMSX
//
//  Created by Mario Smit on 17/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#include "symbolinfo.hpp"
/*****************************************************************************
 ** File:        SymbolInfo.cpp
 **
 ** Author:      Daniel Vik
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

#include <string>

using namespace std;

void SymbolInfo::clear()
{
    symbolMap.erase(symbolMap.begin(), symbolMap.end());
}

const char* SymbolInfo::find(UInt16 address)
{
    if (!showSymbols) {
        return NULL;
    }
    map<UInt16, Symbol>::const_iterator i = symbolMap.find(address);
    if (i == symbolMap.end()) {
        return NULL;
    }
    
    return (i->second).name;
}

bool SymbolInfo::rfind(const char* symbolName, UInt16* addr)
{
    if (!showSymbols) {
        return false;
    }
    map<UInt16, Symbol>::const_iterator i;
    
    for (i = symbolMap.begin(); i != symbolMap.end(); ++i) {
        if (0 == strncmp((i->second).name, symbolName, 64)) {
            *addr = i->first;
            return true;
        }
    }
    return false;
}

const char* SymbolInfo::toString(UInt16 address)
{
    static char buf[256];
    
    const char* r = find(address);
    
    if (r != NULL) {
        sprintf(buf, "%s", r);
    }
    else {
        sprintf(buf, "#%04x", address);
    }
    return buf;
}

static int isHexNumber(const char* t)
{
    int isHexNum;
    int l = strlen(t);
    if (l == 0) {
        return 0;
    }
    
    if (t[l - 1] == 'h') {
        l--;
    }
    else if (t[0] == '$') {
        t++;
        l--;
    }
    
    isHexNum = l > 0;
    
    while (--l >= 0) {
        isHexNum &= (t[l] >= '0' && t[l] <= '9') ||
        (t[l] >= 'A' && t[l] <= 'F') ||
        (t[l] >= 'a' && t[l] <= 'f');
    }
    return isHexNum ? strlen(t) : 0;
}

void SymbolInfo::append(string& buffer)
{
    int index = 0;
    bool lastLine = false;
    while (!lastLine) {
        int nextIndex = buffer.find('\n', index);
        
        lastLine = nextIndex == string::npos;
        
        string line = lastLine ? buffer.substr(index) : buffer.substr(index, nextIndex - index);
        
        if (line.length() > 0) {
            char lineBuffer[512];
            strcpy(lineBuffer, line.c_str());
            char* t1 = strtok(lineBuffer, "\r\n\t ");
            char* t2  = strtok(NULL, "\r\n\t ");
            if (t2 && 0 == strcmp(t2, "equ")) {
                t2  = strtok(NULL, "\r\n\t ");
            }
            if (t1 && t2) {
                char* label;
                char* addr;
                if (isHexNumber(t1) > isHexNumber(t2)) {
                    addr  = t1;
                    label = t2;
                }
                else {
                    addr  = t2;
                    label = t1;
                }
                int labelLen = strlen(label);
                if (label[labelLen - 1] == ':') {
                    label[labelLen - 1] = 0;
                }
                int address;
                int count = sscanf(addr, "%xh", &address);
                if (count == 0) {
                    count = sscanf(addr, "$%x", &address);
                }
                if (count == 1 && labelLen) {
                    UInt16 addr = address;
                    symbolMap[addr] = Symbol(label);
                }
            }
        }
        
        index = nextIndex + 1;
    }
}


SymbolInfo::SymbolInfo() : showSymbols(false)
{
}

SymbolInfo::~SymbolInfo()
{
}

void SymbolInfo::show()
{
    showSymbols = true;
}

void SymbolInfo::hide()
{
    showSymbols = false;
}


bool SymbolInfo::getShowStatus()
{
    return showSymbols;
}
