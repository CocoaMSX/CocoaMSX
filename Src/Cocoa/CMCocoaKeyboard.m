/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012 Akop Karapetyan
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
#import <AppKit/NSEvent.h>

#import "CMCocoaKeyboard.h"

#import "CMKeyboardInput.h"
#import "CMInputDeviceLayout.h"
#import "CMPreferences.h"

#import "CMEmulatorController.h"

#include "InputEvent.h"

#pragma mark - CMMsxKeyInfo

#define CMIntAsNumber(x) [NSNumber numberWithInteger:x]
#define CMMakeMsxKeyInfo(d, s) \
    [CMMsxKeyInfo keyInfoWithDefaultStateLabel:d shiftedStateLabel:s]

@interface CMMsxKeyInfo : NSObject

@property (nonatomic, copy) NSString *defaultStateLabel;
@property (nonatomic, copy) NSString *shiftedStateLabel;

@end

@implementation CMMsxKeyInfo

+ (CMMsxKeyInfo *)keyInfoWithDefaultStateLabel:(NSString *)defaultStateLabel
                             shiftedStateLabel:(NSString *)shiftedStateLabel
{
    CMMsxKeyInfo *info = [[CMMsxKeyInfo alloc] init];
    
    info.defaultStateLabel = defaultStateLabel;
    info.shiftedStateLabel = shiftedStateLabel;
    
    return [info autorelease];
}

- (void)dealloc
{
    self.defaultStateLabel = nil;
    self.shiftedStateLabel = nil;
    
    [super dealloc];
}

@end

// FIXME: this class needs to poll, and not just modify the virtual matrix
//        whenever a key is pressed

//#define DEBUG_KEY_STATE

#pragma mark - CMCocoaKeyboard

static NSArray *orderOfAppearance = nil;
static NSDictionary *staticLayout = nil;
static NSMutableDictionary *typewriterLayouts = nil;

@interface CMCocoaKeyboard ()

- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;

@end

@implementation CMCocoaKeyboard

+ (void)initialize
{
    orderOfAppearance = [[NSArray alloc] initWithObjects:
                         CMIntAsNumber(EC_RBRACK),
                         CMIntAsNumber(EC_1),
                         CMIntAsNumber(EC_2),
                         CMIntAsNumber(EC_3),
                         CMIntAsNumber(EC_4),
                         CMIntAsNumber(EC_5),
                         CMIntAsNumber(EC_6),
                         CMIntAsNumber(EC_7),
                         CMIntAsNumber(EC_8),
                         CMIntAsNumber(EC_9),
                         CMIntAsNumber(EC_0),
                         CMIntAsNumber(EC_NEG),
                         CMIntAsNumber(EC_CIRCFLX),
                         CMIntAsNumber(EC_Q),
                         CMIntAsNumber(EC_W),
                         CMIntAsNumber(EC_E),
                         CMIntAsNumber(EC_R),
                         CMIntAsNumber(EC_T),
                         CMIntAsNumber(EC_Y),
                         CMIntAsNumber(EC_U),
                         CMIntAsNumber(EC_I),
                         CMIntAsNumber(EC_O),
                         CMIntAsNumber(EC_P),
                         CMIntAsNumber(EC_AT),
                         CMIntAsNumber(EC_LBRACK),
                         CMIntAsNumber(EC_A),
                         CMIntAsNumber(EC_S),
                         CMIntAsNumber(EC_D),
                         CMIntAsNumber(EC_F),
                         CMIntAsNumber(EC_G),
                         CMIntAsNumber(EC_H),
                         CMIntAsNumber(EC_J),
                         CMIntAsNumber(EC_K),
                         CMIntAsNumber(EC_L),
                         CMIntAsNumber(EC_SEMICOL),
                         CMIntAsNumber(EC_COLON),
                         CMIntAsNumber(EC_BKSLASH),
                         CMIntAsNumber(EC_Z),
                         CMIntAsNumber(EC_X),
                         CMIntAsNumber(EC_C),
                         CMIntAsNumber(EC_V),
                         CMIntAsNumber(EC_B),
                         CMIntAsNumber(EC_N),
                         CMIntAsNumber(EC_M),
                         CMIntAsNumber(EC_COMMA),
                         CMIntAsNumber(EC_PERIOD),
                         CMIntAsNumber(EC_DIV),
                         CMIntAsNumber(EC_UNDSCRE),
                         CMIntAsNumber(EC_LSHIFT),
                         CMIntAsNumber(EC_RSHIFT),
                         CMIntAsNumber(EC_CTRL),
                         CMIntAsNumber(EC_GRAPH),
                         CMIntAsNumber(EC_CODE),
                         CMIntAsNumber(EC_CAPS),
                         CMIntAsNumber(EC_LEFT),
                         CMIntAsNumber(EC_UP),
                         CMIntAsNumber(EC_RIGHT),
                         CMIntAsNumber(EC_DOWN),
                         CMIntAsNumber(EC_F1),
                         CMIntAsNumber(EC_F2),
                         CMIntAsNumber(EC_F3),
                         CMIntAsNumber(EC_F4),
                         CMIntAsNumber(EC_F5),
                         CMIntAsNumber(EC_NUM0),
                         CMIntAsNumber(EC_NUM1),
                         CMIntAsNumber(EC_NUM2),
                         CMIntAsNumber(EC_NUM3),
                         CMIntAsNumber(EC_NUM4),
                         CMIntAsNumber(EC_NUM5),
                         CMIntAsNumber(EC_NUM6),
                         CMIntAsNumber(EC_NUM7),
                         CMIntAsNumber(EC_NUM8),
                         CMIntAsNumber(EC_NUM9),
                         CMIntAsNumber(EC_NUMDIV),
                         CMIntAsNumber(EC_NUMMUL),
                         CMIntAsNumber(EC_NUMSUB),
                         CMIntAsNumber(EC_NUMADD),
                         CMIntAsNumber(EC_NUMPER),
                         CMIntAsNumber(EC_NUMCOM),
                         CMIntAsNumber(EC_ESC),
                         CMIntAsNumber(EC_TAB),
                         CMIntAsNumber(EC_STOP),
                         CMIntAsNumber(EC_CLS),
                         CMIntAsNumber(EC_SELECT),
                         CMIntAsNumber(EC_INS),
                         CMIntAsNumber(EC_DEL),
                         CMIntAsNumber(EC_BKSPACE),
                         CMIntAsNumber(EC_RETURN),
                         CMIntAsNumber(EC_SPACE),
                         CMIntAsNumber(EC_PRINT),
                         CMIntAsNumber(EC_PAUSE),
                         CMIntAsNumber(EC_TORIKE),
                         CMIntAsNumber(EC_JIKKOU),
                         CMIntAsNumber(EC_JOY1_UP),
                         CMIntAsNumber(EC_JOY1_DOWN),
                         CMIntAsNumber(EC_JOY1_LEFT),
                         CMIntAsNumber(EC_JOY1_RIGHT),
                         CMIntAsNumber(EC_JOY2_UP),
                         CMIntAsNumber(EC_JOY2_DOWN),
                         CMIntAsNumber(EC_JOY2_LEFT),
                         CMIntAsNumber(EC_JOY2_RIGHT),
                         CMIntAsNumber(EC_JOY1_BUTTON1),
                         CMIntAsNumber(EC_JOY1_BUTTON2),
                         CMIntAsNumber(EC_JOY2_BUTTON1),
                         CMIntAsNumber(EC_JOY2_BUTTON2),
                         
                         nil];
    
    staticLayout = [[NSDictionary alloc] initWithObjectsAndKeys:
                    CMLoc(@"KeyLeftShift"),  CMIntAsNumber(EC_LSHIFT),
                    CMLoc(@"KeyRightShift"), CMIntAsNumber(EC_RSHIFT),
                    CMLoc(@"KeyCtrl"),       CMIntAsNumber(EC_CTRL),
                    CMLoc(@"KeyGraph"),      CMIntAsNumber(EC_GRAPH),
                    CMLoc(@"KeyCode"),       CMIntAsNumber(EC_CODE),
                    CMLoc(@"KeyTorike"),     CMIntAsNumber(EC_TORIKE),
                    CMLoc(@"KeyJikkou"),     CMIntAsNumber(EC_JIKKOU),
                    CMLoc(@"KeyCapsLock"),   CMIntAsNumber(EC_CAPS),
                    
                    CMLoc(@"KeyCursorLeft"),  CMIntAsNumber(EC_LEFT),
                    CMLoc(@"KeyCursorUp"),    CMIntAsNumber(EC_UP),
                    CMLoc(@"KeyCursorRight"), CMIntAsNumber(EC_RIGHT),
                    CMLoc(@"KeyCursorDown"),  CMIntAsNumber(EC_DOWN),
                    
                    @"F1", CMIntAsNumber(EC_F1),
                    @"F2", CMIntAsNumber(EC_F2),
                    @"F3", CMIntAsNumber(EC_F3),
                    @"F4", CMIntAsNumber(EC_F4),
                    @"F5", CMIntAsNumber(EC_F5),
                    
                    @"*", CMIntAsNumber(EC_NUMMUL),
                    @"+", CMIntAsNumber(EC_NUMADD),
                    @"/", CMIntAsNumber(EC_NUMDIV),
                    @"-", CMIntAsNumber(EC_NUMSUB),
                    @".", CMIntAsNumber(EC_NUMPER),
                    @",", CMIntAsNumber(EC_NUMCOM),
                    @"0", CMIntAsNumber(EC_NUM0),
                    @"1", CMIntAsNumber(EC_NUM1),
                    @"2", CMIntAsNumber(EC_NUM2),
                    @"3", CMIntAsNumber(EC_NUM3),
                    @"4", CMIntAsNumber(EC_NUM4),
                    @"5", CMIntAsNumber(EC_NUM5),
                    @"6", CMIntAsNumber(EC_NUM6),
                    @"7", CMIntAsNumber(EC_NUM7),
                    @"8", CMIntAsNumber(EC_NUM8),
                    @"9", CMIntAsNumber(EC_NUM9),
                    
                    CMLoc(@"KeyEscape"),    CMIntAsNumber(EC_ESC),
                    CMLoc(@"KeyTab"),       CMIntAsNumber(EC_TAB),
                    CMLoc(@"KeyStop"),      CMIntAsNumber(EC_STOP),
                    CMLoc(@"KeyCls"),       CMIntAsNumber(EC_CLS),
                    CMLoc(@"KeySelect"),    CMIntAsNumber(EC_SELECT),
                    CMLoc(@"KeyInsert"),    CMIntAsNumber(EC_INS),
                    CMLoc(@"KeyDelete"),    CMIntAsNumber(EC_DEL),
                    CMLoc(@"KeyBackspace"), CMIntAsNumber(EC_BKSPACE),
                    CMLoc(@"KeyReturn"),    CMIntAsNumber(EC_RETURN),
                    CMLoc(@"KeySpace"),     CMIntAsNumber(EC_SPACE),
                    CMLoc(@"KeyPrint"),     CMIntAsNumber(EC_PRINT),
                    CMLoc(@"KeyPause"),     CMIntAsNumber(EC_PAUSE),
                    
                    CMLoc(@"JoyButtonOne"), CMIntAsNumber(EC_JOY1_BUTTON1),
                    CMLoc(@"JoyButtonTwo"), CMIntAsNumber(EC_JOY1_BUTTON2),
                    CMLoc(@"JoyUp"),        CMIntAsNumber(EC_JOY1_UP),
                    CMLoc(@"JoyDown"),      CMIntAsNumber(EC_JOY1_DOWN),
                    CMLoc(@"JoyLeft"),      CMIntAsNumber(EC_JOY1_LEFT),
                    CMLoc(@"JoyRight"),     CMIntAsNumber(EC_JOY1_RIGHT),
                    
                    CMLoc(@"JoyButtonOne"), CMIntAsNumber(EC_JOY2_BUTTON1),
                    CMLoc(@"JoyButtonTwo"), CMIntAsNumber(EC_JOY2_BUTTON2),
                    CMLoc(@"JoyUp"),        CMIntAsNumber(EC_JOY2_UP),
                    CMLoc(@"JoyDown"),      CMIntAsNumber(EC_JOY2_DOWN),
                    CMLoc(@"JoyLeft"),      CMIntAsNumber(EC_JOY2_LEFT),
                    CMLoc(@"JoyRight"),     CMIntAsNumber(EC_JOY2_RIGHT),
                    
                    nil];
    
    NSMutableDictionary *euroLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       CMMakeMsxKeyInfo(@"`", @"~"), CMIntAsNumber(EC_RBRACK),
                                       CMMakeMsxKeyInfo(@"1", @"!"), CMIntAsNumber(EC_1),
                                       CMMakeMsxKeyInfo(@"2", @"@"), CMIntAsNumber(EC_2),
                                       CMMakeMsxKeyInfo(@"3", @"#"), CMIntAsNumber(EC_3),
                                       CMMakeMsxKeyInfo(@"4", @"$"), CMIntAsNumber(EC_4),
                                       CMMakeMsxKeyInfo(@"5", @"%"), CMIntAsNumber(EC_5),
                                       CMMakeMsxKeyInfo(@"6", @"^"), CMIntAsNumber(EC_6),
                                       CMMakeMsxKeyInfo(@"7", @"&"), CMIntAsNumber(EC_7),
                                       CMMakeMsxKeyInfo(@"8", @"*"), CMIntAsNumber(EC_8),
                                       CMMakeMsxKeyInfo(@"9", @"("), CMIntAsNumber(EC_9),
                                       CMMakeMsxKeyInfo(@"0", @")"), CMIntAsNumber(EC_0),
                                       CMMakeMsxKeyInfo(@"-", @"_"), CMIntAsNumber(EC_NEG),
                                       CMMakeMsxKeyInfo(@"=", @"+"), CMIntAsNumber(EC_CIRCFLX),
                                       
                                       CMMakeMsxKeyInfo(@"q", @"Q"), CMIntAsNumber(EC_Q),
                                       CMMakeMsxKeyInfo(@"w", @"W"), CMIntAsNumber(EC_W),
                                       CMMakeMsxKeyInfo(@"e", @"E"), CMIntAsNumber(EC_E),
                                       CMMakeMsxKeyInfo(@"r", @"R"), CMIntAsNumber(EC_R),
                                       CMMakeMsxKeyInfo(@"t", @"T"), CMIntAsNumber(EC_T),
                                       CMMakeMsxKeyInfo(@"y", @"Y"), CMIntAsNumber(EC_Y),
                                       CMMakeMsxKeyInfo(@"u", @"U"), CMIntAsNumber(EC_U),
                                       CMMakeMsxKeyInfo(@"i", @"I"), CMIntAsNumber(EC_I),
                                       CMMakeMsxKeyInfo(@"o", @"O"), CMIntAsNumber(EC_O),
                                       CMMakeMsxKeyInfo(@"p", @"P"), CMIntAsNumber(EC_P),
                                       CMMakeMsxKeyInfo(@"[", @"{"), CMIntAsNumber(EC_AT),
                                       CMMakeMsxKeyInfo(@"]", @"}"), CMIntAsNumber(EC_LBRACK),
                                       
                                       CMMakeMsxKeyInfo(@"a", @"A"), CMIntAsNumber(EC_A),
                                       CMMakeMsxKeyInfo(@"s", @"S"), CMIntAsNumber(EC_S),
                                       CMMakeMsxKeyInfo(@"d", @"D"), CMIntAsNumber(EC_D),
                                       CMMakeMsxKeyInfo(@"f", @"F"), CMIntAsNumber(EC_F),
                                       CMMakeMsxKeyInfo(@"g", @"G"), CMIntAsNumber(EC_G),
                                       CMMakeMsxKeyInfo(@"h", @"H"), CMIntAsNumber(EC_H),
                                       CMMakeMsxKeyInfo(@"j", @"J"), CMIntAsNumber(EC_J),
                                       CMMakeMsxKeyInfo(@"k", @"K"), CMIntAsNumber(EC_K),
                                       CMMakeMsxKeyInfo(@"l", @"L"), CMIntAsNumber(EC_L),
                                       CMMakeMsxKeyInfo(@";", @":"), CMIntAsNumber(EC_SEMICOL),
                                       CMMakeMsxKeyInfo(@"'", @"\""), CMIntAsNumber(EC_COLON),
                                       CMMakeMsxKeyInfo(@"\\", @"|"), CMIntAsNumber(EC_BKSLASH),
                                       
                                       CMMakeMsxKeyInfo(@"z", @"Z"), CMIntAsNumber(EC_Z),
                                       CMMakeMsxKeyInfo(@"x", @"X"), CMIntAsNumber(EC_X),
                                       CMMakeMsxKeyInfo(@"c", @"C"), CMIntAsNumber(EC_C),
                                       CMMakeMsxKeyInfo(@"v", @"V"), CMIntAsNumber(EC_V),
                                       CMMakeMsxKeyInfo(@"b", @"B"), CMIntAsNumber(EC_B),
                                       CMMakeMsxKeyInfo(@"n", @"N"), CMIntAsNumber(EC_N),
                                       CMMakeMsxKeyInfo(@"m", @"M"), CMIntAsNumber(EC_M),
                                       CMMakeMsxKeyInfo(@",", @"<"), CMIntAsNumber(EC_COMMA),
                                       CMMakeMsxKeyInfo(@".", @">"), CMIntAsNumber(EC_PERIOD),
                                       CMMakeMsxKeyInfo(@"/", @"?"), CMIntAsNumber(EC_DIV),
                                       CMMakeMsxKeyInfo(@"`", @"'"), CMIntAsNumber(EC_UNDSCRE),
                                       
                                       nil];
    
    NSMutableDictionary *brazilianLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            CMMakeMsxKeyInfo(@"ç", @"Ç"), CMIntAsNumber(EC_RBRACK),
                                            CMMakeMsxKeyInfo(@"1", @"!"), CMIntAsNumber(EC_1),
                                            CMMakeMsxKeyInfo(@"2", @"\""), CMIntAsNumber(EC_2),
                                            CMMakeMsxKeyInfo(@"3", @"#"), CMIntAsNumber(EC_3),
                                            CMMakeMsxKeyInfo(@"4", @"$"), CMIntAsNumber(EC_4),
                                            CMMakeMsxKeyInfo(@"5", @"%"), CMIntAsNumber(EC_5),
                                            CMMakeMsxKeyInfo(@"6", @"^"), CMIntAsNumber(EC_6),
                                            CMMakeMsxKeyInfo(@"7", @"&"), CMIntAsNumber(EC_7),
                                            CMMakeMsxKeyInfo(@"8", @"'"), CMIntAsNumber(EC_8),
                                            CMMakeMsxKeyInfo(@"9", @"("), CMIntAsNumber(EC_9),
                                            CMMakeMsxKeyInfo(@"0", @")"), CMIntAsNumber(EC_0),
                                            CMMakeMsxKeyInfo(@"-", @"_"), CMIntAsNumber(EC_NEG),
                                            CMMakeMsxKeyInfo(@"=", @"+"), CMIntAsNumber(EC_CIRCFLX),
                                            
                                            CMMakeMsxKeyInfo(@"q", @"Q"), CMIntAsNumber(EC_Q),
                                            CMMakeMsxKeyInfo(@"w", @"W"), CMIntAsNumber(EC_W),
                                            CMMakeMsxKeyInfo(@"e", @"E"), CMIntAsNumber(EC_E),
                                            CMMakeMsxKeyInfo(@"r", @"R"), CMIntAsNumber(EC_R),
                                            CMMakeMsxKeyInfo(@"t", @"T"), CMIntAsNumber(EC_T),
                                            CMMakeMsxKeyInfo(@"y", @"Y"), CMIntAsNumber(EC_Y),
                                            CMMakeMsxKeyInfo(@"u", @"U"), CMIntAsNumber(EC_U),
                                            CMMakeMsxKeyInfo(@"i", @"I"), CMIntAsNumber(EC_I),
                                            CMMakeMsxKeyInfo(@"o", @"O"), CMIntAsNumber(EC_O),
                                            CMMakeMsxKeyInfo(@"p", @"P"), CMIntAsNumber(EC_P),
                                            CMMakeMsxKeyInfo(@"'", @"`"), CMIntAsNumber(EC_AT),
                                            CMMakeMsxKeyInfo(@"[", @"]"), CMIntAsNumber(EC_LBRACK),
                                            
                                            CMMakeMsxKeyInfo(@"a", @"A"), CMIntAsNumber(EC_A),
                                            CMMakeMsxKeyInfo(@"s", @"S"), CMIntAsNumber(EC_S),
                                            CMMakeMsxKeyInfo(@"d", @"D"), CMIntAsNumber(EC_D),
                                            CMMakeMsxKeyInfo(@"f", @"F"), CMIntAsNumber(EC_F),
                                            CMMakeMsxKeyInfo(@"g", @"G"), CMIntAsNumber(EC_G),
                                            CMMakeMsxKeyInfo(@"h", @"H"), CMIntAsNumber(EC_H),
                                            CMMakeMsxKeyInfo(@"j", @"J"), CMIntAsNumber(EC_J),
                                            CMMakeMsxKeyInfo(@"k", @"K"), CMIntAsNumber(EC_K),
                                            CMMakeMsxKeyInfo(@"l", @"L"), CMIntAsNumber(EC_L),
                                            CMMakeMsxKeyInfo(@"~", @"^"), CMIntAsNumber(EC_SEMICOL),
                                            CMMakeMsxKeyInfo(@"*", @"@"), CMIntAsNumber(EC_COLON),
                                            CMMakeMsxKeyInfo(@"{", @"}"), CMIntAsNumber(EC_BKSLASH),
                                            
                                            CMMakeMsxKeyInfo(@"z", @"Z"), CMIntAsNumber(EC_Z),
                                            CMMakeMsxKeyInfo(@"x", @"X"), CMIntAsNumber(EC_X),
                                            CMMakeMsxKeyInfo(@"c", @"C"), CMIntAsNumber(EC_C),
                                            CMMakeMsxKeyInfo(@"v", @"V"), CMIntAsNumber(EC_V),
                                            CMMakeMsxKeyInfo(@"b", @"B"), CMIntAsNumber(EC_B),
                                            CMMakeMsxKeyInfo(@"n", @"N"), CMIntAsNumber(EC_N),
                                            CMMakeMsxKeyInfo(@"m", @"M"), CMIntAsNumber(EC_M),
                                            CMMakeMsxKeyInfo(@",", @"<"), CMIntAsNumber(EC_COMMA),
                                            CMMakeMsxKeyInfo(@".", @">"), CMIntAsNumber(EC_PERIOD),
                                            CMMakeMsxKeyInfo(@";", @":"), CMIntAsNumber(EC_DIV),
                                            CMMakeMsxKeyInfo(@"/", @"?"), CMIntAsNumber(EC_UNDSCRE),
                                            
                                            nil];
    
    NSMutableDictionary *estonianLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           CMMakeMsxKeyInfo(@"^", @"~"), CMIntAsNumber(EC_RBRACK),
                                           CMMakeMsxKeyInfo(@"1", @"!"), CMIntAsNumber(EC_1),
                                           CMMakeMsxKeyInfo(@"2", @"\""), CMIntAsNumber(EC_2),
                                           CMMakeMsxKeyInfo(@"3", @"#"), CMIntAsNumber(EC_3),
                                           CMMakeMsxKeyInfo(@"4", @"$"), CMIntAsNumber(EC_4),
                                           CMMakeMsxKeyInfo(@"5", @"%"), CMIntAsNumber(EC_5),
                                           CMMakeMsxKeyInfo(@"6", @"&"), CMIntAsNumber(EC_6),
                                           CMMakeMsxKeyInfo(@"7", @"/"), CMIntAsNumber(EC_7),
                                           CMMakeMsxKeyInfo(@"8", @"("), CMIntAsNumber(EC_8),
                                           CMMakeMsxKeyInfo(@"9", @")"), CMIntAsNumber(EC_9),
                                           CMMakeMsxKeyInfo(@"0", @"="), CMIntAsNumber(EC_0),
                                           CMMakeMsxKeyInfo(@"+", @"?"), CMIntAsNumber(EC_NEG),
                                           CMMakeMsxKeyInfo(@"'", @"`"), CMIntAsNumber(EC_CIRCFLX),
                                           
                                           CMMakeMsxKeyInfo(@"q", @"Q"), CMIntAsNumber(EC_Q),
                                           CMMakeMsxKeyInfo(@"w", @"W"), CMIntAsNumber(EC_W),
                                           CMMakeMsxKeyInfo(@"e", @"E"), CMIntAsNumber(EC_E),
                                           CMMakeMsxKeyInfo(@"r", @"R"), CMIntAsNumber(EC_R),
                                           CMMakeMsxKeyInfo(@"t", @"T"), CMIntAsNumber(EC_T),
                                           CMMakeMsxKeyInfo(@"y", @"Y"), CMIntAsNumber(EC_Y),
                                           CMMakeMsxKeyInfo(@"u", @"U"), CMIntAsNumber(EC_U),
                                           CMMakeMsxKeyInfo(@"i", @"I"), CMIntAsNumber(EC_I),
                                           CMMakeMsxKeyInfo(@"o", @"O"), CMIntAsNumber(EC_O),
                                           CMMakeMsxKeyInfo(@"p", @"P"), CMIntAsNumber(EC_P),
                                           CMMakeMsxKeyInfo(@"[", @"{"), CMIntAsNumber(EC_AT),
                                           CMMakeMsxKeyInfo(@"]", @"}"), CMIntAsNumber(EC_LBRACK),
                                           
                                           CMMakeMsxKeyInfo(@"a", @"A"), CMIntAsNumber(EC_A),
                                           CMMakeMsxKeyInfo(@"s", @"S"), CMIntAsNumber(EC_S),
                                           CMMakeMsxKeyInfo(@"d", @"D"), CMIntAsNumber(EC_D),
                                           CMMakeMsxKeyInfo(@"f", @"F"), CMIntAsNumber(EC_F),
                                           CMMakeMsxKeyInfo(@"g", @"G"), CMIntAsNumber(EC_G),
                                           CMMakeMsxKeyInfo(@"h", @"H"), CMIntAsNumber(EC_H),
                                           CMMakeMsxKeyInfo(@"j", @"J"), CMIntAsNumber(EC_J),
                                           CMMakeMsxKeyInfo(@"k", @"K"), CMIntAsNumber(EC_K),
                                           CMMakeMsxKeyInfo(@"l", @"L"), CMIntAsNumber(EC_L),
                                           CMMakeMsxKeyInfo(@"\\", @"|"), CMIntAsNumber(EC_SEMICOL),
                                           CMMakeMsxKeyInfo(@"<", @">"), CMIntAsNumber(EC_COLON),
                                           CMMakeMsxKeyInfo(@"'", @"*"), CMIntAsNumber(EC_BKSLASH),
                                           
                                           CMMakeMsxKeyInfo(@"z", @"Z"), CMIntAsNumber(EC_Z),
                                           CMMakeMsxKeyInfo(@"x", @"X"), CMIntAsNumber(EC_X),
                                           CMMakeMsxKeyInfo(@"c", @"C"), CMIntAsNumber(EC_C),
                                           CMMakeMsxKeyInfo(@"v", @"V"), CMIntAsNumber(EC_V),
                                           CMMakeMsxKeyInfo(@"b", @"B"), CMIntAsNumber(EC_B),
                                           CMMakeMsxKeyInfo(@"n", @"N"), CMIntAsNumber(EC_N),
                                           CMMakeMsxKeyInfo(@"m", @"M"), CMIntAsNumber(EC_M),
                                           CMMakeMsxKeyInfo(@",", @";"), CMIntAsNumber(EC_COMMA),
                                           CMMakeMsxKeyInfo(@".", @":"), CMIntAsNumber(EC_PERIOD),
                                           CMMakeMsxKeyInfo(@"-", @"_"), CMIntAsNumber(EC_DIV),
                                           CMMakeMsxKeyInfo(@" ", @" "), CMIntAsNumber(EC_UNDSCRE), // None
                                           
                                           nil];
    
    NSMutableDictionary *frenchLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         CMMakeMsxKeyInfo(@"#", @"£"), CMIntAsNumber(EC_RBRACK),
                                         CMMakeMsxKeyInfo(@"&", @"1"), CMIntAsNumber(EC_1),
                                         CMMakeMsxKeyInfo(@"é", @"2"), CMIntAsNumber(EC_2),
                                         CMMakeMsxKeyInfo(@"\"", @"3"), CMIntAsNumber(EC_3),
                                         CMMakeMsxKeyInfo(@"'", @"4"), CMIntAsNumber(EC_4),
                                         CMMakeMsxKeyInfo(@"(", @"5"), CMIntAsNumber(EC_5),
                                         CMMakeMsxKeyInfo(@"§", @"6"), CMIntAsNumber(EC_6),
                                         CMMakeMsxKeyInfo(@"è", @"7"), CMIntAsNumber(EC_7),
                                         CMMakeMsxKeyInfo(@"!", @"8"), CMIntAsNumber(EC_8),
                                         CMMakeMsxKeyInfo(@"ç", @"9"), CMIntAsNumber(EC_9),
                                         CMMakeMsxKeyInfo(@"à", @"0"), CMIntAsNumber(EC_0),
                                         CMMakeMsxKeyInfo(@")", @"º"), CMIntAsNumber(EC_NEG),
                                         CMMakeMsxKeyInfo(@"-", @"_"), CMIntAsNumber(EC_CIRCFLX),
                                         
                                         CMMakeMsxKeyInfo(@"a", @"A"), CMIntAsNumber(EC_Q),
                                         CMMakeMsxKeyInfo(@"z", @"Z"), CMIntAsNumber(EC_W),
                                         CMMakeMsxKeyInfo(@"e", @"E"), CMIntAsNumber(EC_E),
                                         CMMakeMsxKeyInfo(@"r", @"R"), CMIntAsNumber(EC_R),
                                         CMMakeMsxKeyInfo(@"t", @"T"), CMIntAsNumber(EC_T),
                                         CMMakeMsxKeyInfo(@"y", @"Y"), CMIntAsNumber(EC_Y),
                                         CMMakeMsxKeyInfo(@"u", @"U"), CMIntAsNumber(EC_U),
                                         CMMakeMsxKeyInfo(@"i", @"I"), CMIntAsNumber(EC_I),
                                         CMMakeMsxKeyInfo(@"o", @"O"), CMIntAsNumber(EC_O),
                                         CMMakeMsxKeyInfo(@"p", @"P"), CMIntAsNumber(EC_P),
                                         CMMakeMsxKeyInfo(@"`", @"'"), CMIntAsNumber(EC_AT),
                                         CMMakeMsxKeyInfo(@"$", @"*"), CMIntAsNumber(EC_LBRACK),
                                         
                                         CMMakeMsxKeyInfo(@"q", @"Q"), CMIntAsNumber(EC_A),
                                         CMMakeMsxKeyInfo(@"s", @"S"), CMIntAsNumber(EC_S),
                                         CMMakeMsxKeyInfo(@"d", @"D"), CMIntAsNumber(EC_D),
                                         CMMakeMsxKeyInfo(@"f", @"F"), CMIntAsNumber(EC_F),
                                         CMMakeMsxKeyInfo(@"g", @"G"), CMIntAsNumber(EC_G),
                                         CMMakeMsxKeyInfo(@"h", @"H"), CMIntAsNumber(EC_H),
                                         CMMakeMsxKeyInfo(@"j", @"J"), CMIntAsNumber(EC_J),
                                         CMMakeMsxKeyInfo(@"k", @"K"), CMIntAsNumber(EC_K),
                                         CMMakeMsxKeyInfo(@"l", @"L"), CMIntAsNumber(EC_L),
                                         CMMakeMsxKeyInfo(@"m", @"M"), CMIntAsNumber(EC_SEMICOL),
                                         CMMakeMsxKeyInfo(@"ù", @"%"), CMIntAsNumber(EC_COLON),
                                         CMMakeMsxKeyInfo(@"<", @">"), CMIntAsNumber(EC_BKSLASH),
                                         
                                         CMMakeMsxKeyInfo(@"w", @"W"), CMIntAsNumber(EC_Z),
                                         CMMakeMsxKeyInfo(@"x", @"X"), CMIntAsNumber(EC_X),
                                         CMMakeMsxKeyInfo(@"c", @"C"), CMIntAsNumber(EC_C),
                                         CMMakeMsxKeyInfo(@"v", @"V"), CMIntAsNumber(EC_V),
                                         CMMakeMsxKeyInfo(@"b", @"B"), CMIntAsNumber(EC_B),
                                         CMMakeMsxKeyInfo(@"n", @"N"), CMIntAsNumber(EC_N),
                                         CMMakeMsxKeyInfo(@",", @"?"), CMIntAsNumber(EC_M),
                                         CMMakeMsxKeyInfo(@";", @"."), CMIntAsNumber(EC_COMMA),
                                         CMMakeMsxKeyInfo(@":", @"/"), CMIntAsNumber(EC_PERIOD),
                                         CMMakeMsxKeyInfo(@"=", @"+"), CMIntAsNumber(EC_DIV),
                                         CMMakeMsxKeyInfo(@" ", @" "), CMIntAsNumber(EC_UNDSCRE), // None
                                         
                                         nil];
    
    NSMutableDictionary *germanLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         CMMakeMsxKeyInfo(@"#", @"^"), CMIntAsNumber(EC_RBRACK),
                                         CMMakeMsxKeyInfo(@"1", @"!"), CMIntAsNumber(EC_1),
                                         CMMakeMsxKeyInfo(@"2", @"\""), CMIntAsNumber(EC_2),
                                         CMMakeMsxKeyInfo(@"3", @"§"), CMIntAsNumber(EC_3),
                                         CMMakeMsxKeyInfo(@"4", @"$"), CMIntAsNumber(EC_4),
                                         CMMakeMsxKeyInfo(@"5", @"%"), CMIntAsNumber(EC_5),
                                         CMMakeMsxKeyInfo(@"6", @"&"), CMIntAsNumber(EC_6),
                                         CMMakeMsxKeyInfo(@"7", @"/"), CMIntAsNumber(EC_7),
                                         CMMakeMsxKeyInfo(@"8", @"("), CMIntAsNumber(EC_8),
                                         CMMakeMsxKeyInfo(@"9", @")"), CMIntAsNumber(EC_9),
                                         CMMakeMsxKeyInfo(@"0", @"="), CMIntAsNumber(EC_0),
                                         CMMakeMsxKeyInfo(@"ß", @"?"), CMIntAsNumber(EC_NEG),
                                         CMMakeMsxKeyInfo(@"'", @"`"), CMIntAsNumber(EC_CIRCFLX),
                                         
                                         CMMakeMsxKeyInfo(@"q", @"Q"), CMIntAsNumber(EC_Q),
                                         CMMakeMsxKeyInfo(@"w", @"W"), CMIntAsNumber(EC_W),
                                         CMMakeMsxKeyInfo(@"e", @"E"), CMIntAsNumber(EC_E),
                                         CMMakeMsxKeyInfo(@"r", @"R"), CMIntAsNumber(EC_R),
                                         CMMakeMsxKeyInfo(@"t", @"T"), CMIntAsNumber(EC_T),
                                         CMMakeMsxKeyInfo(@"z", @"Z"), CMIntAsNumber(EC_Y),
                                         CMMakeMsxKeyInfo(@"u", @"U"), CMIntAsNumber(EC_U),
                                         CMMakeMsxKeyInfo(@"i", @"I"), CMIntAsNumber(EC_I),
                                         CMMakeMsxKeyInfo(@"o", @"O"), CMIntAsNumber(EC_O),
                                         CMMakeMsxKeyInfo(@"p", @"P"), CMIntAsNumber(EC_P),
                                         CMMakeMsxKeyInfo(@"ü", @"Ü"), CMIntAsNumber(EC_AT),
                                         CMMakeMsxKeyInfo(@"+", @"*"), CMIntAsNumber(EC_LBRACK),
                                         
                                         CMMakeMsxKeyInfo(@"a", @"A"), CMIntAsNumber(EC_A),
                                         CMMakeMsxKeyInfo(@"s", @"S"), CMIntAsNumber(EC_S),
                                         CMMakeMsxKeyInfo(@"d", @"D"), CMIntAsNumber(EC_D),
                                         CMMakeMsxKeyInfo(@"f", @"F"), CMIntAsNumber(EC_F),
                                         CMMakeMsxKeyInfo(@"g", @"G"), CMIntAsNumber(EC_G),
                                         CMMakeMsxKeyInfo(@"h", @"H"), CMIntAsNumber(EC_H),
                                         CMMakeMsxKeyInfo(@"j", @"J"), CMIntAsNumber(EC_J),
                                         CMMakeMsxKeyInfo(@"k", @"K"), CMIntAsNumber(EC_K),
                                         CMMakeMsxKeyInfo(@"l", @"L"), CMIntAsNumber(EC_L),
                                         CMMakeMsxKeyInfo(@"ö", @"Ö"), CMIntAsNumber(EC_SEMICOL),
                                         CMMakeMsxKeyInfo(@"ä", @"Ä"), CMIntAsNumber(EC_COLON),
                                         CMMakeMsxKeyInfo(@"<", @">"), CMIntAsNumber(EC_BKSLASH),
                                         
                                         CMMakeMsxKeyInfo(@"y", @"Y"), CMIntAsNumber(EC_Z),
                                         CMMakeMsxKeyInfo(@"x", @"X"), CMIntAsNumber(EC_X),
                                         CMMakeMsxKeyInfo(@"c", @"C"), CMIntAsNumber(EC_C),
                                         CMMakeMsxKeyInfo(@"v", @"V"), CMIntAsNumber(EC_V),
                                         CMMakeMsxKeyInfo(@"b", @"B"), CMIntAsNumber(EC_B),
                                         CMMakeMsxKeyInfo(@"n", @"N"), CMIntAsNumber(EC_N),
                                         CMMakeMsxKeyInfo(@"m", @"M"), CMIntAsNumber(EC_M),
                                         CMMakeMsxKeyInfo(@",", @";"), CMIntAsNumber(EC_COMMA),
                                         CMMakeMsxKeyInfo(@".", @":"), CMIntAsNumber(EC_PERIOD),
                                         CMMakeMsxKeyInfo(@"-", @"_"), CMIntAsNumber(EC_DIV),
                                         CMMakeMsxKeyInfo(@" ", @" "), CMIntAsNumber(EC_UNDSCRE), // None
                                         
                                         nil];
    
    NSMutableDictionary *japaneseLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           CMMakeMsxKeyInfo(@"]", @"}"), CMIntAsNumber(EC_RBRACK),
                                           CMMakeMsxKeyInfo(@"1", @"!"), CMIntAsNumber(EC_1),
                                           CMMakeMsxKeyInfo(@"2", @"\""), CMIntAsNumber(EC_2),
                                           CMMakeMsxKeyInfo(@"3", @"#"), CMIntAsNumber(EC_3),
                                           CMMakeMsxKeyInfo(@"4", @"$"), CMIntAsNumber(EC_4),
                                           CMMakeMsxKeyInfo(@"5", @"%"), CMIntAsNumber(EC_5),
                                           CMMakeMsxKeyInfo(@"6", @"&"), CMIntAsNumber(EC_6),
                                           CMMakeMsxKeyInfo(@"7", @"'"), CMIntAsNumber(EC_7),
                                           CMMakeMsxKeyInfo(@"8", @"("), CMIntAsNumber(EC_8),
                                           CMMakeMsxKeyInfo(@"9", @")"), CMIntAsNumber(EC_9),
                                           CMMakeMsxKeyInfo(@"0", @" "), CMIntAsNumber(EC_0),
                                           CMMakeMsxKeyInfo(@"-", @"="), CMIntAsNumber(EC_NEG),
                                           CMMakeMsxKeyInfo(@"^", @"~"), CMIntAsNumber(EC_CIRCFLX),
                                           
                                           CMMakeMsxKeyInfo(@"q", @"Q"), CMIntAsNumber(EC_Q),
                                           CMMakeMsxKeyInfo(@"w", @"W"), CMIntAsNumber(EC_W),
                                           CMMakeMsxKeyInfo(@"e", @"E"), CMIntAsNumber(EC_E),
                                           CMMakeMsxKeyInfo(@"r", @"R"), CMIntAsNumber(EC_R),
                                           CMMakeMsxKeyInfo(@"t", @"T"), CMIntAsNumber(EC_T),
                                           CMMakeMsxKeyInfo(@"y", @"Y"), CMIntAsNumber(EC_Y),
                                           CMMakeMsxKeyInfo(@"u", @"U"), CMIntAsNumber(EC_U),
                                           CMMakeMsxKeyInfo(@"i", @"I"), CMIntAsNumber(EC_I),
                                           CMMakeMsxKeyInfo(@"o", @"O"), CMIntAsNumber(EC_O),
                                           CMMakeMsxKeyInfo(@"p", @"P"), CMIntAsNumber(EC_P),
                                           CMMakeMsxKeyInfo(@"@", @"`"), CMIntAsNumber(EC_AT),
                                           CMMakeMsxKeyInfo(@"[", @"{"), CMIntAsNumber(EC_LBRACK),
                                           
                                           CMMakeMsxKeyInfo(@"a", @"A"), CMIntAsNumber(EC_A),
                                           CMMakeMsxKeyInfo(@"s", @"S"), CMIntAsNumber(EC_S),
                                           CMMakeMsxKeyInfo(@"d", @"D"), CMIntAsNumber(EC_D),
                                           CMMakeMsxKeyInfo(@"f", @"F"), CMIntAsNumber(EC_F),
                                           CMMakeMsxKeyInfo(@"g", @"G"), CMIntAsNumber(EC_G),
                                           CMMakeMsxKeyInfo(@"h", @"H"), CMIntAsNumber(EC_H),
                                           CMMakeMsxKeyInfo(@"j", @"J"), CMIntAsNumber(EC_J),
                                           CMMakeMsxKeyInfo(@"k", @"K"), CMIntAsNumber(EC_K),
                                           CMMakeMsxKeyInfo(@"l", @"L"), CMIntAsNumber(EC_L),
                                           CMMakeMsxKeyInfo(@";", @"+"), CMIntAsNumber(EC_SEMICOL),
                                           CMMakeMsxKeyInfo(@":", @"*"), CMIntAsNumber(EC_COLON),
                                           CMMakeMsxKeyInfo(@"¥", @"|"), CMIntAsNumber(EC_BKSLASH),
                                           
                                           CMMakeMsxKeyInfo(@"z", @"Z"), CMIntAsNumber(EC_Z),
                                           CMMakeMsxKeyInfo(@"x", @"X"), CMIntAsNumber(EC_X),
                                           CMMakeMsxKeyInfo(@"c", @"C"), CMIntAsNumber(EC_C),
                                           CMMakeMsxKeyInfo(@"v", @"V"), CMIntAsNumber(EC_V),
                                           CMMakeMsxKeyInfo(@"b", @"B"), CMIntAsNumber(EC_B),
                                           CMMakeMsxKeyInfo(@"n", @"N"), CMIntAsNumber(EC_N),
                                           CMMakeMsxKeyInfo(@"m", @"M"), CMIntAsNumber(EC_M),
                                           CMMakeMsxKeyInfo(@",", @"<"), CMIntAsNumber(EC_COMMA),
                                           CMMakeMsxKeyInfo(@".", @">"), CMIntAsNumber(EC_PERIOD),
                                           CMMakeMsxKeyInfo(@"/", @"?"), CMIntAsNumber(EC_DIV),
                                           CMMakeMsxKeyInfo(@" ", @"_"), CMIntAsNumber(EC_UNDSCRE),
                                           
                                           nil];
    
    // Korean is the same as Japanese, except for the currency symbol
    
    NSMutableDictionary *koreanLayout = [[japaneseLayout mutableCopy] autorelease];
    [koreanLayout setObject:CMMakeMsxKeyInfo(@"￦", @"|") forKey:CMIntAsNumber(EC_BKSLASH)];
    
    NSMutableDictionary *russianLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          CMMakeMsxKeyInfo(@">", @"."), CMIntAsNumber(EC_RBRACK),
                                          CMMakeMsxKeyInfo(@"+", @";"), CMIntAsNumber(EC_1),
                                          CMMakeMsxKeyInfo(@"!", @"1"), CMIntAsNumber(EC_2),
                                          CMMakeMsxKeyInfo(@"\"", @"2"), CMIntAsNumber(EC_3),
                                          CMMakeMsxKeyInfo(@"#", @"3"), CMIntAsNumber(EC_4),
                                          CMMakeMsxKeyInfo(@"Ȣ", @"4"), CMIntAsNumber(EC_5),
                                          CMMakeMsxKeyInfo(@"%", @"5"), CMIntAsNumber(EC_6),
                                          CMMakeMsxKeyInfo(@"&", @"6"), CMIntAsNumber(EC_7),
                                          CMMakeMsxKeyInfo(@"'", @"7"), CMIntAsNumber(EC_8),
                                          CMMakeMsxKeyInfo(@"(", @"8"), CMIntAsNumber(EC_9),
                                          CMMakeMsxKeyInfo(@")", @"9"), CMIntAsNumber(EC_0),
                                          CMMakeMsxKeyInfo(@"$", @"0"), CMIntAsNumber(EC_NEG),
                                          CMMakeMsxKeyInfo(@"=", @"_"), CMIntAsNumber(EC_CIRCFLX),
                                          
                                          CMMakeMsxKeyInfo(@"j", @"J"), CMIntAsNumber(EC_Q),
                                          CMMakeMsxKeyInfo(@"c", @"C"), CMIntAsNumber(EC_W),
                                          CMMakeMsxKeyInfo(@"u", @"U"), CMIntAsNumber(EC_E),
                                          CMMakeMsxKeyInfo(@"k", @"K"), CMIntAsNumber(EC_R),
                                          CMMakeMsxKeyInfo(@"e", @"E"), CMIntAsNumber(EC_T),
                                          CMMakeMsxKeyInfo(@"n", @"N"), CMIntAsNumber(EC_Y),
                                          CMMakeMsxKeyInfo(@"g", @"G"), CMIntAsNumber(EC_U),
                                          CMMakeMsxKeyInfo(@"[", @"{"), CMIntAsNumber(EC_I),
                                          CMMakeMsxKeyInfo(@"]", @"}"), CMIntAsNumber(EC_O),
                                          CMMakeMsxKeyInfo(@"z", @"Z"), CMIntAsNumber(EC_P),
                                          CMMakeMsxKeyInfo(@"h", @"H"), CMIntAsNumber(EC_AT),
                                          CMMakeMsxKeyInfo(@"*", @":"), CMIntAsNumber(EC_LBRACK),
                                          
                                          CMMakeMsxKeyInfo(@"f", @"F"), CMIntAsNumber(EC_A),
                                          CMMakeMsxKeyInfo(@"y", @"Y"), CMIntAsNumber(EC_S),
                                          CMMakeMsxKeyInfo(@"w", @"W"), CMIntAsNumber(EC_D),
                                          CMMakeMsxKeyInfo(@"a", @"A"), CMIntAsNumber(EC_F),
                                          CMMakeMsxKeyInfo(@"p", @"P"), CMIntAsNumber(EC_G),
                                          CMMakeMsxKeyInfo(@"r", @"R"), CMIntAsNumber(EC_H),
                                          CMMakeMsxKeyInfo(@"o", @"O"), CMIntAsNumber(EC_J),
                                          CMMakeMsxKeyInfo(@"l", @"L"), CMIntAsNumber(EC_K),
                                          CMMakeMsxKeyInfo(@"d", @"D"), CMIntAsNumber(EC_L),
                                          CMMakeMsxKeyInfo(@"v", @"V"), CMIntAsNumber(EC_SEMICOL),
                                          CMMakeMsxKeyInfo(@"\\", @"\\"), CMIntAsNumber(EC_COLON),
                                          CMMakeMsxKeyInfo(@"-", @"^"), CMIntAsNumber(EC_BKSLASH),
                                          
                                          CMMakeMsxKeyInfo(@"q", @"Q"), CMIntAsNumber(EC_Z),
                                          CMMakeMsxKeyInfo(@"|", @"~"), CMIntAsNumber(EC_X),
                                          CMMakeMsxKeyInfo(@"s", @"S"), CMIntAsNumber(EC_C),
                                          CMMakeMsxKeyInfo(@"m", @"M"), CMIntAsNumber(EC_V),
                                          CMMakeMsxKeyInfo(@"i", @"I"), CMIntAsNumber(EC_B),
                                          CMMakeMsxKeyInfo(@"t", @"T"), CMIntAsNumber(EC_N),
                                          CMMakeMsxKeyInfo(@"x", @"X"), CMIntAsNumber(EC_M),
                                          CMMakeMsxKeyInfo(@"b", @"B"), CMIntAsNumber(EC_COMMA),
                                          CMMakeMsxKeyInfo(@"@", @" "), CMIntAsNumber(EC_PERIOD),
                                          CMMakeMsxKeyInfo(@"<", @","), CMIntAsNumber(EC_DIV),
                                          CMMakeMsxKeyInfo(@"?", @"/"), CMIntAsNumber(EC_UNDSCRE),
                                          
                                          nil];
    
    // Spanish is mostly the same as European
    
    NSMutableDictionary *spanishLayout = [[euroLayout mutableCopy] autorelease];
    [spanishLayout setObject:CMMakeMsxKeyInfo(@";", @":") forKey:CMIntAsNumber(EC_RBRACK)];
    [spanishLayout setObject:CMMakeMsxKeyInfo(@"ñ", @"Ñ") forKey:CMIntAsNumber(EC_SEMICOL)];
    [spanishLayout setObject:CMMakeMsxKeyInfo(@"'", @"~") forKey:CMIntAsNumber(EC_SEMICOL)];
    
    // Swedish is mostly the same as German
    
    NSMutableDictionary *swedishLayout = [[germanLayout mutableCopy] autorelease];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"'", @"*") forKey:CMIntAsNumber(EC_RBRACK)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"3", @"#") forKey:CMIntAsNumber(EC_3)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"+", @"?") forKey:CMIntAsNumber(EC_NEG)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"é", @"É") forKey:CMIntAsNumber(EC_CIRCFLX)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"y", @"Y") forKey:CMIntAsNumber(EC_Y)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"å", @"Å") forKey:CMIntAsNumber(EC_AT)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"ü", @"Ü") forKey:CMIntAsNumber(EC_LBRACK)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"z", @"Z") forKey:CMIntAsNumber(EC_Z)];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"'", @"`") forKey:CMIntAsNumber(EC_UNDSCRE)];
    
    typewriterLayouts = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         euroLayout, CMIntAsNumber(CMKeyLayoutArabic),
                         brazilianLayout, CMIntAsNumber(CMKeyLayoutBrazilian),
                         estonianLayout, CMIntAsNumber(CMKeyLayoutEstonian),
                         frenchLayout, CMIntAsNumber(CMKeyLayoutFrench),
                         germanLayout, CMIntAsNumber(CMKeyLayoutGerman),
                         euroLayout, CMIntAsNumber(CMKeyLayoutEuropean),
                         japaneseLayout, CMIntAsNumber(CMKeyLayoutJapanese),
                         koreanLayout, CMIntAsNumber(CMKeyLayoutKorean),
                         russianLayout, CMIntAsNumber(CMKeyLayoutRussian),
                         spanishLayout, CMIntAsNumber(CMKeyLayoutSpanish),
                         swedishLayout, CMIntAsNumber(CMKeyLayoutSwedish),
                         nil];
}

- (id)init
{
    if ((self = [super init]))
    {
        [self resetState];
    }
    
    return self;
}

- (void)dealloc
{
    self.emulatorHasFocus = NO;
    
    [super dealloc];
}

#pragma mark - Key event methods

- (void)keyDown:(NSEvent*)event
{
    if ([event isARepeat])
        return;
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"keyDown: %i", [event keyCode]);
#endif
    
    // Ignore keys while Command is pressed - they don't generate keyUp
    if ((event.modifierFlags & NSCommandKeyMask) != 0)
        return;
    
    [self handleKeyEvent:event.keyCode isDown:YES];
}

- (void)keyUp:(NSEvent*)event
{
    if ([event isARepeat])
        return;
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"keyUp: %i", [event keyCode]);
#endif
    
    [self handleKeyEvent:event.keyCode isDown:NO];
}

- (void)flagsChanged:(NSEvent *)event
{
#ifdef DEBUG_KEY_STATE
    NSLog(@"flagsChanged: %1$x; flags: %2$ld (0x%2$lx)",
          event.keyCode, event.modifierFlags);
#endif
    
    if (event.keyCode == CMKeyLeftShift)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftShiftKeyMask) == CMLeftShiftKeyMask)];
    else if (event.keyCode == CMKeyRightShift)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightShiftKeyMask) == CMRightShiftKeyMask)];
    else if (event.keyCode == CMKeyLeftAlt)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftAltKeyMask) == CMLeftAltKeyMask)];
    else if (event.keyCode == CMKeyRightAlt)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightAltKeyMask) == CMRightAltKeyMask)];
    else if (event.keyCode == CMKeyLeftControl)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftControlKeyMask) == CMLeftControlKeyMask)];
    else if (event.keyCode == CMKeyRightControl)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightControlKeyMask) == CMRightControlKeyMask)];
    else if (event.keyCode == CMKeyLeftCommand)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMLeftCommandKeyMask) == CMLeftCommandKeyMask)];
    else if (event.keyCode == CMKeyRightCommand)
        [self handleKeyEvent:event.keyCode
                      isDown:((event.modifierFlags & CMRightCommandKeyMask) == CMRightCommandKeyMask)];
    else if (event.keyCode == CMKeyCapsLock)
    {
        // Caps Lock has no up/down - just toggle state
        CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:event.keyCode];
        NSInteger virtualCode = [theEmulator.keyboardLayout virtualCodeForInputMethod:input];
        
        if (virtualCode != CMUnknownVirtualCode)
        {
            if (!inputEventGetState(virtualCode))
                inputEventSet(virtualCode);
            else
                inputEventUnset(virtualCode);
        }
    }
    
    if (event.keyCode == CMKeyLeftCommand || event.keyCode == CMKeyRightCommand)
    {
        // If Command is toggled while another key is down, releasing the
        // other key no longer generates a keyUp event, and the virtual key
        // 'sticks'. Release all virtual keys if Command is pressed.
        
        [self releaseAllKeys];
    }
}

#pragma mark - Public methods

- (void)releaseAllKeys
{
    inputEventReset();
}

- (BOOL)areAnyKeysDown
{
    for (int virtualKey = 0; virtualKey < EC_KEYCOUNT; virtualKey++)
        if (inputEventGetState(virtualKey))
            return YES;
    
    return NO;
}

- (void)resetState
{
    [self releaseAllKeys];
}

- (void)setEmulatorHasFocus:(BOOL)focus
{
    if (!focus)
    {
#ifdef DEBUG
        NSLog(@"CMCocoaKeyboard: -Focus");
#endif
        // Emulator has lost focus - release all virtual keys
        [self resetState];
    }
    else
    {
#ifdef DEBUG
        NSLog(@"CMCocoaKeyboard: +Focus");
#endif
    }
}

- (NSString *)inputNameForVirtualCode:(NSUInteger)virtualCode
                           shiftState:(NSInteger)shiftState
                             layoutId:(NSInteger)layoutId
{
    // Check the list of static keys
    NSString *staticKeyLabel = [staticLayout objectForKey:CMIntAsNumber(virtualCode)];
    if (staticKeyLabel)
        return staticKeyLabel;
    
    // Check the typewriter keys
    NSMutableDictionary *layout = [typewriterLayouts objectForKey:CMIntAsNumber(layoutId)];
    if (layout)
    {
        CMMsxKeyInfo *keyInfo = [layout objectForKey:CMIntAsNumber(virtualCode)];
        if (keyInfo)
        {
            if (shiftState == CMKeyShiftStateNormal)
                return keyInfo.defaultStateLabel;
            else if (shiftState == CMKeyShiftStateShifted)
                return keyInfo.shiftedStateLabel;
        }
    }
    
    return nil;
}

+ (NSInteger)compareKeysByOrderOfAppearance:(NSNumber *)one
                                 keyCodeTwo:(NSNumber *)two
{
    NSInteger index1 = [orderOfAppearance indexOfObject:one];
    NSInteger index2 = [orderOfAppearance indexOfObject:two];
    
    if (index1 < index2)
        return NSOrderedAscending;
    else if (index1 > index2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (NSInteger)categoryForVirtualCode:(NSUInteger)virtualCode
{
    switch (virtualCode)
    {
        case EC_RBRACK:
        case EC_1:
        case EC_2:
        case EC_3:
        case EC_4:
        case EC_5:
        case EC_6:
        case EC_7:
        case EC_8:
        case EC_9:
        case EC_0:
        case EC_NEG:
        case EC_CIRCFLX:
            return CMKeyCategoryTypewriterRowOne;
        case EC_Q:
        case EC_W:
        case EC_E:
        case EC_R:
        case EC_T:
        case EC_Y:
        case EC_U:
        case EC_I:
        case EC_O:
        case EC_P:
        case EC_AT:
        case EC_LBRACK:
            return CMKeyCategoryTypewriterRowTwo;
        case EC_A:
        case EC_S:
        case EC_D:
        case EC_F:
        case EC_G:
        case EC_H:
        case EC_J:
        case EC_K:
        case EC_L:
        case EC_SEMICOL:
        case EC_COLON:
        case EC_BKSLASH:
            return CMKeyCategoryTypewriterRowThree;
        case EC_Z:
        case EC_X:
        case EC_C:
        case EC_V:
        case EC_B:
        case EC_N:
        case EC_M:
        case EC_COMMA:
        case EC_PERIOD:
        case EC_DIV:
        case EC_UNDSCRE:
            return CMKeyCategoryTypewriterRowFour;
        case EC_LSHIFT:
        case EC_RSHIFT:
        case EC_CTRL:
        case EC_GRAPH:
        case EC_CODE:
        case EC_CAPS:
            return CMKeyCategoryModifier;
        case EC_LEFT:
        case EC_UP:
        case EC_RIGHT:
        case EC_DOWN:
            return CMKeyCategoryDirectional;
        case EC_F1:
        case EC_F2:
        case EC_F3:
        case EC_F4:
        case EC_F5:
            return CMKeyCategoryFunction;
        case EC_NUMMUL:
        case EC_NUMADD:
        case EC_NUMDIV:
        case EC_NUMSUB:
        case EC_NUMPER:
        case EC_NUMCOM:
        case EC_NUM0:
        case EC_NUM1:
        case EC_NUM2:
        case EC_NUM3:
        case EC_NUM4:
        case EC_NUM5:
        case EC_NUM6:
        case EC_NUM7:
        case EC_NUM8:
        case EC_NUM9:
            return CMKeyCategoryNumericPad;
        case EC_ESC:
        case EC_TAB:
        case EC_STOP:
        case EC_CLS:
        case EC_SELECT:
        case EC_INS:
        case EC_DEL:
        case EC_BKSPACE:
        case EC_RETURN:
        case EC_SPACE:
        case EC_PRINT:
        case EC_PAUSE:
        case EC_TORIKE:
        case EC_JIKKOU:
            return CMKeyCategorySpecial;
        case EC_JOY1_UP:
        case EC_JOY1_DOWN:
        case EC_JOY1_LEFT:
        case EC_JOY1_RIGHT:
        case EC_JOY2_UP:
        case EC_JOY2_DOWN:
        case EC_JOY2_LEFT:
        case EC_JOY2_RIGHT:
            return CMKeyCategoryJoyDirections;
        case EC_JOY1_BUTTON1:
        case EC_JOY1_BUTTON2:
        case EC_JOY2_BUTTON1:
        case EC_JOY2_BUTTON2:
            return CMKeyCategoryJoyButtons;
        default:
            return 0;
    }
}

- (NSString *)nameForCategory:(NSInteger)category
{
    switch (category)
    {
        case CMKeyCategoryModifier:
            return CMLoc(@"KeyCategoryModifier");
        case CMKeyCategoryDirectional:
            return CMLoc(@"KeyCategoryDirectional");
        case CMKeyCategoryFunction:
            return CMLoc(@"KeyCategoryFunction");
        case CMKeyCategoryTypewriterRowOne:
            return CMLoc(@"KeyCategoryTypewriterRowOne");
        case CMKeyCategoryTypewriterRowTwo:
            return CMLoc(@"KeyCategoryTypewriterRowTwo");
        case CMKeyCategoryTypewriterRowThree:
            return CMLoc(@"KeyCategoryTypewriterRowThree");
        case CMKeyCategoryTypewriterRowFour:
            return CMLoc(@"KeyCategoryTypewriterRowFour");
        case CMKeyCategoryNumericPad:
            return CMLoc(@"KeyCategoryNumericPad");
        case CMKeyCategorySpecial:
            return CMLoc(@"KeyCategorySpecial");
        case CMKeyCategoryJoyButtons:
            return CMLoc(@"KeyCategoryJoystickButtons");
        case CMKeyCategoryJoyDirections:
            return CMLoc(@"KeyCategoryJoystickDirectional");
    }
    
    return nil;
}

#pragma mark - Private methods

- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown
{
    CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:keyCode];
    
    [theEmulator.inputDeviceLayouts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMInputDeviceLayout *layout = obj;
        NSInteger virtualCode = [layout virtualCodeForInputMethod:input];
        
        if (virtualCode != CMUnknownVirtualCode)
        {
            if (isDown)
            {
                if (!inputEventGetState(virtualCode))
                    inputEventSet(virtualCode);
            }
            else
            {
                if (inputEventGetState(virtualCode))
                    inputEventUnset(virtualCode);
            }
        }
    }];
}

- (void)updateKeyboardState
{
    // FIXME: this is where we need to actually update the matrix
}

#pragma mark - BlueMSX Callbacks

extern CMEmulatorController *theEmulator;

void archPollInput()
{
    @autoreleasepool
    {
        [theEmulator.keyboard updateKeyboardState];
    }
}

void archKeyboardSetSelectedKey(int keyCode) {}

@end
