/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2014 Akop Karapetyan
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
#import <Foundation/Foundation.h>

#import "CMInputMethod.h"

#define CMKeyNoCode      (-1)

#define CMKeyLeft           123
#define CMKeyUp             126
#define CMKeyRight          124
#define CMKeyDown           125
#define CMKeyF1             122
#define CMKeyF2             120
#define CMKeyF3             99
#define CMKeyF4             118
#define CMKeyF5             96
#define CMKeyA              0
#define CMKeyB              11
#define CMKeyC              8
#define CMKeyD              2
#define CMKeyE              14
#define CMKeyF              3
#define CMKeyG              5
#define CMKeyH              4
#define CMKeyI              34
#define CMKeyJ              38
#define CMKeyK              40
#define CMKeyL              37
#define CMKeyM              46
#define CMKeyN              45
#define CMKeyO              31
#define CMKeyP              35
#define CMKeyQ              12
#define CMKeyR              15
#define CMKeyS              1
#define CMKeyT              17
#define CMKeyU              32
#define CMKeyV              9
#define CMKeyW              13
#define CMKeyX              7
#define CMKeyY              16
#define CMKeyZ              6
#define CMKey0              29
#define CMKey1              18
#define CMKey2              19
#define CMKey3              20
#define CMKey4              21
#define CMKey5              23
#define CMKey6              22
#define CMKey7              26
#define CMKey8              28
#define CMKey9              25
#define CMKeyNumpadAsterisk 67
#define CMKeyNumpadPlus     69
#define CMKeyNumpadSlash    75
#define CMKeyNumpadMinus    78
#define CMKeyNumpadDecimal  65
#define CMKeyNumpadEnter    76
#define CMKeyNumpad0        82
#define CMKeyNumpad1        83
#define CMKeyNumpad2        84
#define CMKeyNumpad3        85
#define CMKeyNumpad4        86
#define CMKeyNumpad5        87
#define CMKeyNumpad6        88
#define CMKeyNumpad7        89
#define CMKeyNumpad8        91
#define CMKeyNumpad9        92
#define CMKeyBacktick       50
#define CMKeyEscape         53
#define CMKeyTab            48
#define CMKeySpacebar       49
#define CMKeyComma          43
#define CMKeyPeriod         47
#define CMKeySlash          44
#define CMKeyMinus          27
#define CMKeyEquals         24
#define CMKeySemicolon      41
#define CMKeyQuote          39
#define CMKeyLeftBracket    33
#define CMKeyRightBracket   30
#define CMKeyBackslash      42
#define CMKeyEnter          36
#define CMKeyBackspace      51
#define CMKeyDelete         117
#define CMKeyHome           115
#define CMKeyEnd            119
#define CMKeyPageDown       121
#define CMKeyPageUp         116
#define CMKeyPrintScreen    105
#define CMKeyCapsLock       57
#define CMKeyLeftShift      56
#define CMKeyRightShift     60
#define CMKeyLeftControl    59
#define CMKeyRightControl   62
#define CMKeyLeftAlt        58
#define CMKeyRightAlt       61
#define CMKeyLeftCommand    55
#define CMKeyRightCommand   54
#define CMKeyFunction       63

#define CMLeftShiftKeyMask    (NSShiftKeyMask | 0x2)
#define CMRightShiftKeyMask   (NSShiftKeyMask | 0x4)
#define CMLeftControlKeyMask  (NSControlKeyMask | 0x1)
#define CMRightControlKeyMask (NSControlKeyMask | 0x2000)
#define CMLeftAltKeyMask      (NSAlternateKeyMask | 0x20)
#define CMRightAltKeyMask     (NSAlternateKeyMask | 0x40)
#define CMLeftCommandKeyMask  (NSCommandKeyMask | 0x08)
#define CMRightCommandKeyMask (NSCommandKeyMask | 0x10)
#define CMCapsLockKeyMask     NSAlphaShiftKeyMask

@interface CMKeyboardInput : CMInputMethod
{
    NSInteger _keyCode;
}

+ (CMKeyboardInput *)keyboardInputWithKeyCode:(NSInteger)keyCode;

@property (nonatomic, assign) NSInteger keyCode;

@end
