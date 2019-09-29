//
//  symbolinfo.hpp
//  CocoaMSX
//
//  Created by Mario Smit on 17/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#ifndef symbolinfo_hpp
#define symbolinfo_hpp
/*****************************************************************************
 ** File:
 **      SymbolInfo.h
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
#include <map>
#include "msxtypes.h"

class SymbolInfo {
public:
    SymbolInfo();
    ~SymbolInfo();
    
    void show();
    void hide();
    bool getShowStatus();
    
    void clear();
    void append(std::string& buffer);
    
    const char* find(UInt16 address);
    bool rfind(const char* symbolName, UInt16* addr);
    const char* toString(UInt16 address);
    
private:
    
    bool showSymbols;
    
    class Symbol {
    public:
        Symbol() { name[0] = 0; }
        Symbol(char* label) { strncpy(name, label, 63); name[63] = 0; }
        ~Symbol() {}
        Symbol(const Symbol& li) { strcpy(name, li.name); }
        void operator=(const Symbol& li) { strcpy(name, li.name); }
        
        char name[64];
    };
    
    std::map<UInt16, Symbol> symbolMap;
};


#endif /* symbolinfo_hpp */
