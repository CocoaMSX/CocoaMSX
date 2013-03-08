/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2013 Akop Karapetyan
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

#define CMAutoPressHoldTimeSeconds    0.04
#define CMAutoPressReleaseTimeSeconds 0.03
#define CMAutoPressTotalTimeSeconds \
    (CMAutoPressHoldTimeSeconds + CMAutoPressReleaseTimeSeconds)

#define CMMakeMsxKeyInfo(d, s) \
    [CMMsxKeyInfo keyInfoWithDefaultStateLabel:d shiftedStateLabel:s]

@interface CMMsxKeyInfo : NSObject
{
    NSString *_defaultStateLabel;
    NSString *_shiftedStateLabel;
}

@property (nonatomic, copy) NSString *defaultStateLabel;
@property (nonatomic, copy) NSString *shiftedStateLabel;

@end

@implementation CMMsxKeyInfo

@synthesize defaultStateLabel = _defaultStateLabel;
@synthesize shiftedStateLabel = _shiftedStateLabel;

+ (CMMsxKeyInfo *)keyInfoWithDefaultStateLabel:(NSString *)defaultStateLabel
                             shiftedStateLabel:(NSString *)shiftedStateLabel
{
    CMMsxKeyInfo *info = [[CMMsxKeyInfo alloc] init];
    
    info.defaultStateLabel = defaultStateLabel;
    info.shiftedStateLabel = shiftedStateLabel;
    
    return [info autorelease];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NSString class]])
    {
        if ([_defaultStateLabel isEqualToString:object])
            return YES;
        if ([_shiftedStateLabel isEqualToString:object])
            return YES;
    }
    
    return [super isEqual:object];
}

- (void)dealloc
{
    self.defaultStateLabel = nil;
    self.shiftedStateLabel = nil;
    
    [super dealloc];
}

@end

//#define DEBUG_KEY_STATE

#pragma mark - CMCocoaKeyboard

static NSArray *orderOfAppearance = nil;
static NSDictionary *staticLayout = nil;
static NSMutableDictionary *typewriterLayouts = nil;
static NSDictionary *machineLayoutMap = nil;

@interface CMCocoaKeyboard ()

- (void)updateKeyboardState;
- (void)handleKeyEvent:(NSInteger)keyCode
                isDown:(BOOL)isDown;

@end

@implementation CMCocoaKeyboard

+ (void)initialize
{
    machineLayoutMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                        [NSArray arrayWithObjects:
                         @"MSX - Al Alamiah AX-150",
                         @"MSX - Al Alamiah AX-170",
                         @"MSX - Perfect 1",
                         @"MSX - Spectravideo SVI-738 Arabic",
                         @"MSX2 - Al Alamiah AX-350II",
                         @"MSX2 - Al Alamiah AX-370", nil], @CMKeyLayoutArabic,
                        [NSArray arrayWithObjects:
                         @"MSX - Gradiente Expert 1.1",
                         @"MSX - Gradiente Expert 1.3",
                         @"MSX - Gradiente Expert DDPlus",
                         @"MSX - Gradiente Expert Plus",
                         @"MSX2 - Gradiente Expert 2.0",
                         @"MSX2+ - Brazilian",
                         @"MSX2+ - Ciel Expert 3 IDE",
                         @"MSX2+ - Ciel Expert 3 Turbo",
                         @"MSX2+ - Gradiente Expert AC88+",
                         @"MSX2+ - Gradiente Expert DDX+",
                         // Different layout
                         @"MSX - Gradiente Expert 1.0",
                         @"MSX - Sharp Epcom HotBit 1.1",
                         @"MSX - Sharp Epcom HotBit 1.2",
                         @"MSX - Sharp Epcom HotBit 1.3b",
                         @"MSX - Sharp Epcom HotBit 1.3p",
                         @"MSX2 - Sharp Epcom HotBit 2.0", nil], @CMKeyLayoutBrazilian,
                        [NSArray arrayWithObjects:
                         @"MSX - Yamaha YIS503IIR Estonian",
                         @"MSX2 - Yamaha YIS503IIIR Estonian",
                         @"MSX2 - Yamaha YIS805-128R2 Estonian", nil], @CMKeyLayoutEstonian,
                        [NSArray arrayWithObjects:
                         @"MSX - Daewoo DPC-200E",
                         @"MSX - Fenner DPC-200",
                         @"MSX - Fenner FPC-500",
                         @"MSX - Fenner SPC-800",
                         @"MSX - Frael Bruc 100-1",
                         @"MSX - Goldstar FC-200",
                         @"MSX - Philips NMS-801",
                         @"MSX - Philips VG-8000",
                         @"MSX - Philips VG-8010",
                         @"MSX - Philips VG-8020-00",
                         @"MSX - Philips VG-8020-20",
                         @"MSX - Spectravideo SVI-728",
                         @"MSX - Spectravideo SVI-738",
                         @"MSX - Spectravideo SVI-738 Henrik Gilvad",
                         @"MSX - Toshiba HX-10",
                         @"MSX - Toshiba HX-20I",
                         @"MSX - Toshiba HX-21I",
                         @"MSX - Toshiba HX-22I",
                         @"MSX - Yamaha CX5M-1",
                         @"MSX - Yamaha CX5M-2",
                         @"MSX - Yamaha CX5MII",
                         @"MSX - Yamaha CX5MII-128",
                         @"MSX - Yamaha YIS303",
                         @"MSX - Yamaha YIS503",
                         @"MSX - Yamaha YIS503II",
                         @"MSX - Yamaha YIS503M",
                         @"MSX - Yashica YC-64",
                         @"MSX2 - Fenner FPC-900",
                         @"MSX2 - Philips NMS-8220",
                         @"MSX2 - Philips NMS-8245",
                         @"MSX2 - Philips NMS-8250",
                         @"MSX2 - Philips NMS-8255",
                         @"MSX2 - Philips NMS-8260+",
                         @"MSX2 - Philips NMS-8280",
                         @"MSX2 - Philips PTC MSX PC",
                         @"MSX2 - Philips VG-8235",
                         @"MSX2 - Philips VG-8240",
                         @"MSX2 - Spectravideo SVI-738-2 CUC",
                         @"MSX2 - Spectravideo SVI-738-2 JP Grobler",
                         @"MSX2 - Toshiba FS-TM1",
                         @"MSX2 - Toshiba HX-23I",
                         @"MSX2 - Toshiba HX-34I",
                         @"MSX2+ - European",
                         @"MSX2+ - Spectravideo SVI-738-2+",
                         @"MSXturboR - European",
                         // Different layout
                         @"MSX - Canon V-20E",
                         @"MSX - JVC HC-7GB",
                         @"MSX - Mitsubishi ML-F48",
                         @"MSX - Mitsubishi ML-F80",
                         @"MSX - Mitsubishi ML-FX1",
                         @"MSX - Pioneer PX-7UK",
                         @"MSX - Sanyo MPC-100",
                         @"MSX - Sanyo PHC-28S",
                         @"MSX - Sanyo Wavy MPC-10",
                         @"MSX - Sony HB-10P",
                         @"MSX - Sony HB-55P",
                         @"MSX - Sony HB-75P",
                         @"MSX - Sony HB-101P",
                         @"MSX - Sony HB-201P",
                         @"MSX - Sony HB-501P",
                         @"MSX - Yamaha YIS503F",
                         @"MSX2 - Philips VG-8230",
                         @"MSX2 - Sony HB-F9P",
                         @"MSX2 - Sony HB-F500P",
                         @"MSX2 - Sony HB-F700P",
                         @"MSX2 - Sony HB-G900AP",
                         @"MSX2 - Sony HB-G900P", nil], @CMKeyLayoutEuropean,
                        [NSArray arrayWithObjects:
                         @"MSX - Canon V-20F",
                         @"MSX - Olympia PHC-2",
                         @"MSX - Olympia PHC-28",
                         @"MSX - Philips VG-8010F",
                         @"MSX - Philips VG-8020F",
                         @"MSX - Sanyo PHC-28L",
                         @"MSX - Toshiba HX-10F",
                         @"MSX - Yeno DPC-64",
                         @"MSX - Yeno MX64",
                         @"MSX2 - Philips NMS-8245F",
                         @"MSX2 - Philips NMS-8250F",
                         @"MSX2 - Philips NMS-8255F",
                         @"MSX2 - Philips NMS-8280F",
                         @"MSX2 - Philips VG-8235F",
                         @"MSX2 - Sony HB-F500F",
                         @"MSX2 - Sony HB-F700F",
                         @"MSX2+ - French", nil], @CMKeyLayoutFrench,
                        [NSArray arrayWithObjects:
                         @"MSX - Canon V-20G",
                         @"MSX - Panasonic CF-2700G",
                         @"MSX - Sanyo MPC-64",
                         @"MSX - Sony HB-55D",
                         @"MSX - Sony HB-75D",
                         @"MSX2 - Philips NMS-8280G",
                         @"MSX2 - Sony HB-F700D", nil], @CMKeyLayoutGerman,
                        [NSArray arrayWithObjects:
                         @"MSX - Canon V-8",
                         @"MSX - Canon V-10",
                         @"MSX - Canon V-20",
                         @"MSX - Casio PV-7",
                         @"MSX - Casio PV-16",
                         @"MSX - Fujitsu FM-X",
                         @"MSX - Mitsubishi ML-F110",
                         @"MSX - Mitsubishi ML-F120",
                         @"MSX - National CF-1200",
                         @"MSX - National CF-2000",
                         @"MSX - National CF-2700",
                         @"MSX - National CF-3000",
                         @"MSX - National CF-3300",
                         @"MSX - National FS-1300",
                         @"MSX - National FS-4000",
                         @"MSX - Pioneer PX-7",
                         @"MSX - Pioneer PX-V60",
                         @"MSX - Sony HB-10",
                         @"MSX - Sony HB-201",
                         @"MSX - Sony HB-501",
                         @"MSX - Sony HB-701FD",
                         @"MSX - Toshiba HX-10D",
                         @"MSX - Toshiba HX-10S",
                         @"MSX - Toshiba HX-20",
                         @"MSX - Toshiba HX-21",
                         @"MSX - Toshiba HX-22",
                         @"MSX - Yamaha CX5F-1",
                         @"MSX - Yamaha CX5F-2",
                         @"MSX2 - Canon V-25",
                         @"MSX2 - Canon V-30",
                         @"MSX2 - Canon V-30F",
                         @"MSX2 - Kawai KMC-5000",
                         @"MSX2 - Mitsubishi ML-G10",
                         @"MSX2 - Mitsubishi ML-G30 Model 1",
                         @"MSX2 - Mitsubishi ML-G30 Model 2",
                         @"MSX2 - National FS-4500",
                         @"MSX2 - National FS-4600",
                         @"MSX2 - National FS-4700",
                         @"MSX2 - National FS-5000",
                         @"MSX2 - National FS-5500F1",
                         @"MSX2 - National FS-5500F2",
                         @"MSX2 - Panasonic FS-A1",
                         @"MSX2 - Panasonic FS-A1F",
                         @"MSX2 - Panasonic FS-A1FM",
                         @"MSX2 - Panasonic FS-A1MK2",
                         @"MSX2 - Philips NMS-8250J",
                         @"MSX2 - Philips VG-8230J",
                         @"MSX2 - Sanyo Wavy MPC-25FD",
                         @"MSX2 - Sanyo Wavy MPC-27",
                         @"MSX2 - Sanyo Wavy PHC-23",
                         @"MSX2 - Sanyo Wavy PHC-55FD2",
                         @"MSX2 - Sanyo Wavy PHC-77",
                         @"MSX2 - Sony HB-F1",
                         @"MSX2 - Sony HB-F1II",
                         @"MSX2 - Sony HB-F1XD",
                         @"MSX2 - Sony HB-F1XDMK2",
                         @"MSX2 - Sony HB-F5",
                         @"MSX2 - Sony HB-F500",
                         @"MSX2 - Sony HB-F750+",
                         @"MSX2 - Sony HB-F900",
                         @"MSX2 - Toshiba HX-23",
                         @"MSX2 - Toshiba HX-23F",
                         @"MSX2 - Toshiba HX-33",
                         @"MSX2 - Toshiba HX-34",
                         @"MSX2 - Victor HC-90",
                         @"MSX2 - Victor HC-95",
                         @"MSX2 - Victor HC-95A",
                         @"MSX2 - Yamaha CX7_128",
                         @"MSX2 - Yamaha CX7M_128",
                         @"MSX2+ - MSXPLAYer 2003",
                         @"MSX2+ - Panasonic FS-A1FX",
                         @"MSX2+ - Panasonic FS-A1WSX",
                         @"MSX2+ - Panasonic FS-A1WX",
                         @"MSX2+ - Sanyo Wavy PHC-35J",
                         @"MSX2+ - Sanyo Wavy PHC-70FD1",
                         @"MSX2+ - Sanyo Wavy PHC-70FD2",
                         @"MSX2+ - Sony HB-F1XDJ",
                         @"MSX2+ - Sony HB-F1XV",
                         @"MSXturboR - Panasonic FS-A1GT",
                         @"MSXturboR - Panasonic FS-A1ST", nil], @CMKeyLayoutJapanese,
                        [NSArray arrayWithObjects:
                         @"MSX - Daewoo DPC-100",
                         @"MSX - Daewoo DPC-180",
                         @"MSX - Daewoo DPC-200",
                         @"MSX - Daewoo Zemmix CPC-50",
                         @"MSX - Daewoo Zemmix CPC-51",
                         @"MSX - Samsung SPC-800",
                         @"MSX2 - Daewoo CPC-300",
                         @"MSX2 - Daewoo CPC-300E",
                         @"MSX2 - Daewoo CPC-330K",
                         @"MSX2 - Daewoo CPC-400",
                         @"MSX2 - Daewoo CPC-400S",
                         @"MSX2 - Daewoo Zemmix CPC-61",
                         @"MSX2 - Daewoo Zemmix CPG-120", nil], @CMKeyLayoutKorean,
                        [NSArray arrayWithObjects:
                         @"MSX - Yamaha YIS503IIR",
                         @"MSX2 - Sanyo MPC-2300",
                         @"MSX2 - Sony HB-F9P Russian",
                         @"MSX2 - Yamaha YIS503IIIR",
                         @"MSX2 - Yamaha YIS805-128R2", nil], @CMKeyLayoutRussian,
                        [NSArray arrayWithObjects:
                         @"MSX - Canon V-20S",
                         @"MSX - Sony HB-20P",
                         @"MSX - Talent DPC-200",
                         @"MSX - Talent DPC-200A",
                         @"MSX - Toshiba HX-10SA",
                         @"MSX2 - Mitsubishi ML-G1",
                         @"MSX2 - Mitsubishi ML-G3",
                         @"MSX2 - Sony HB-F9S",
                         @"MSX2 - Sony HB-F700S",
                         @"MSX2 - Spectravideo SVI-738-2 LC Grosso",
                         @"MSX2 - Talent TPC-310",
                         @"MSX2 - Talent TPP-311",
                         @"MSX2 - Talent TPS-312",
                         @"MSX2+ - Sony HB-F9S+", nil], @CMKeyLayoutSpanish,
                        [NSArray arrayWithObjects:
                         @"MSX - Spectravideo SVI-738 Swedish",
                         @"MSX - Spectravideo SVI-838",
                         @"MSX2 - Spectravideo SVI-838-2", nil], @CMKeyLayoutSwedish,
                        nil];
    
    orderOfAppearance = [[NSArray alloc] initWithObjects:
                         @EC_RBRACK,
                         @EC_1,
                         @EC_2,
                         @EC_3,
                         @EC_4,
                         @EC_5,
                         @EC_6,
                         @EC_7,
                         @EC_8,
                         @EC_9,
                         @EC_0,
                         @EC_NEG,
                         @EC_CIRCFLX,
                         @EC_Q,
                         @EC_W,
                         @EC_E,
                         @EC_R,
                         @EC_T,
                         @EC_Y,
                         @EC_U,
                         @EC_I,
                         @EC_O,
                         @EC_P,
                         @EC_A,
                         @EC_LBRACK,
                         @EC_A,
                         @EC_S,
                         @EC_D,
                         @EC_F,
                         @EC_G,
                         @EC_H,
                         @EC_J,
                         @EC_K,
                         @EC_L,
                         @EC_SEMICOL,
                         @EC_COLON,
                         @EC_BKSLASH,
                         @EC_Z,
                         @EC_X,
                         @EC_C,
                         @EC_V,
                         @EC_B,
                         @EC_N,
                         @EC_M,
                         @EC_COMMA,
                         @EC_PERIOD,
                         @EC_DIV,
                         @EC_UNDSCRE,
                         @EC_LSHIFT,
                         @EC_RSHIFT,
                         @EC_CTRL,
                         @EC_GRAPH,
                         @EC_CODE,
                         @EC_CAPS,
                         @EC_LEFT,
                         @EC_UP,
                         @EC_RIGHT,
                         @EC_DOWN,
                         @EC_F1,
                         @EC_F2,
                         @EC_F3,
                         @EC_F4,
                         @EC_F5,
                         @EC_NUM0,
                         @EC_NUM1,
                         @EC_NUM2,
                         @EC_NUM3,
                         @EC_NUM4,
                         @EC_NUM5,
                         @EC_NUM6,
                         @EC_NUM7,
                         @EC_NUM8,
                         @EC_NUM9,
                         @EC_NUMDIV,
                         @EC_NUMMUL,
                         @EC_NUMSUB,
                         @EC_NUMADD,
                         @EC_NUMPER,
                         @EC_NUMCOM,
                         @EC_ESC,
                         @EC_TAB,
                         @EC_STOP,
                         @EC_CLS,
                         @EC_SELECT,
                         @EC_INS,
                         @EC_DEL,
                         @EC_BKSPACE,
                         @EC_RETURN,
                         @EC_SPACE,
                         @EC_PRINT,
                         @EC_PAUSE,
                         @EC_TORIKE,
                         @EC_JIKKOU,
                         @EC_JOY1_UP,
                         @EC_JOY1_DOWN,
                         @EC_JOY1_LEFT,
                         @EC_JOY1_RIGHT,
                         @EC_JOY2_UP,
                         @EC_JOY2_DOWN,
                         @EC_JOY2_LEFT,
                         @EC_JOY2_RIGHT,
                         @EC_JOY1_BUTTON1,
                         @EC_JOY1_BUTTON2,
                         @EC_JOY2_BUTTON1,
                         @EC_JOY2_BUTTON2,
                         
                         nil];
    
    staticLayout = [[NSDictionary alloc] initWithObjectsAndKeys:
                    CMLoc(@"KeyLeftShift"),  @EC_LSHIFT,
                    CMLoc(@"KeyRightShift"), @EC_RSHIFT,
                    CMLoc(@"KeyCtrl"),       @EC_CTRL,
                    CMLoc(@"KeyGraph"),      @EC_GRAPH,
                    CMLoc(@"KeyCode"),       @EC_CODE,
                    CMLoc(@"KeyTorike"),     @EC_TORIKE,
                    CMLoc(@"KeyJikkou"),     @EC_JIKKOU,
                    CMLoc(@"KeyCapsLock"),   @EC_CAPS,
                    
                    CMLoc(@"KeyCursorLeft"),  @EC_LEFT,
                    CMLoc(@"KeyCursorUp"),    @EC_UP,
                    CMLoc(@"KeyCursorRight"), @EC_RIGHT,
                    CMLoc(@"KeyCursorDown"),  @EC_DOWN,
                    
                    @"F1", @EC_F1,
                    @"F2", @EC_F2,
                    @"F3", @EC_F3,
                    @"F4", @EC_F4,
                    @"F5", @EC_F5,
                    
                    @"*", @EC_NUMMUL,
                    @"+", @EC_NUMADD,
                    @"/", @EC_NUMDIV,
                    @"-", @EC_NUMSUB,
                    @".", @EC_NUMPER,
                    @",", @EC_NUMCOM,
                    @"0", @EC_NUM0,
                    @"1", @EC_NUM1,
                    @"2", @EC_NUM2,
                    @"3", @EC_NUM3,
                    @"4", @EC_NUM4,
                    @"5", @EC_NUM5,
                    @"6", @EC_NUM6,
                    @"7", @EC_NUM7,
                    @"8", @EC_NUM8,
                    @"9", @EC_NUM9,
                    
                    CMLoc(@"KeyEscape"),    @EC_ESC,
                    CMLoc(@"KeyTab"),       @EC_TAB,
                    CMLoc(@"KeyStop"),      @EC_STOP,
                    CMLoc(@"KeyCls"),       @EC_CLS,
                    CMLoc(@"KeySelect"),    @EC_SELECT,
                    CMLoc(@"KeyInsert"),    @EC_INS,
                    CMLoc(@"KeyDelete"),    @EC_DEL,
                    CMLoc(@"KeyBackspace"), @EC_BKSPACE,
                    CMLoc(@"KeyReturn"),    @EC_RETURN,
                    CMLoc(@"KeySpace"),     @EC_SPACE,
                    CMLoc(@"KeyPrint"),     @EC_PRINT,
                    CMLoc(@"KeyPause"),     @EC_PAUSE,
                    
                    CMLoc(@"JoyButtonOne"), @EC_JOY1_BUTTON1,
                    CMLoc(@"JoyButtonTwo"), @EC_JOY1_BUTTON2,
                    CMLoc(@"JoyUp"),        @EC_JOY1_UP,
                    CMLoc(@"JoyDown"),      @EC_JOY1_DOWN,
                    CMLoc(@"JoyLeft"),      @EC_JOY1_LEFT,
                    CMLoc(@"JoyRight"),     @EC_JOY1_RIGHT,
                    
                    CMLoc(@"JoyButtonOne"), @EC_JOY2_BUTTON1,
                    CMLoc(@"JoyButtonTwo"), @EC_JOY2_BUTTON2,
                    CMLoc(@"JoyUp"),        @EC_JOY2_UP,
                    CMLoc(@"JoyDown"),      @EC_JOY2_DOWN,
                    CMLoc(@"JoyLeft"),      @EC_JOY2_LEFT,
                    CMLoc(@"JoyRight"),     @EC_JOY2_RIGHT,
                    
                    nil];
    
    NSMutableDictionary *euroLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       CMMakeMsxKeyInfo(@"`", @"~"), @EC_RBRACK,
                                       CMMakeMsxKeyInfo(@"1", @"!"), @EC_1,
                                       CMMakeMsxKeyInfo(@"2", @"@"), @EC_2,
                                       CMMakeMsxKeyInfo(@"3", @"#"), @EC_3,
                                       CMMakeMsxKeyInfo(@"4", @"$"), @EC_4,
                                       CMMakeMsxKeyInfo(@"5", @"%"), @EC_5,
                                       CMMakeMsxKeyInfo(@"6", @"^"), @EC_6,
                                       CMMakeMsxKeyInfo(@"7", @"&"), @EC_7,
                                       CMMakeMsxKeyInfo(@"8", @"*"), @EC_8,
                                       CMMakeMsxKeyInfo(@"9", @"("), @EC_9,
                                       CMMakeMsxKeyInfo(@"0", @")"), @EC_0,
                                       CMMakeMsxKeyInfo(@"-", @"_"), @EC_NEG,
                                       CMMakeMsxKeyInfo(@"=", @"+"), @EC_CIRCFLX,
                                       
                                       CMMakeMsxKeyInfo(@"q", @"Q"), @EC_Q,
                                       CMMakeMsxKeyInfo(@"w", @"W"), @EC_W,
                                       CMMakeMsxKeyInfo(@"e", @"E"), @EC_E,
                                       CMMakeMsxKeyInfo(@"r", @"R"), @EC_R,
                                       CMMakeMsxKeyInfo(@"t", @"T"), @EC_T,
                                       CMMakeMsxKeyInfo(@"y", @"Y"), @EC_Y,
                                       CMMakeMsxKeyInfo(@"u", @"U"), @EC_U,
                                       CMMakeMsxKeyInfo(@"i", @"I"), @EC_I,
                                       CMMakeMsxKeyInfo(@"o", @"O"), @EC_O,
                                       CMMakeMsxKeyInfo(@"p", @"P"), @EC_P,
                                       CMMakeMsxKeyInfo(@"[", @"{"), @EC_AT,
                                       CMMakeMsxKeyInfo(@"]", @"}"), @EC_LBRACK,
                                       
                                       CMMakeMsxKeyInfo(@"a", @"A"), @EC_A,
                                       CMMakeMsxKeyInfo(@"s", @"S"), @EC_S,
                                       CMMakeMsxKeyInfo(@"d", @"D"), @EC_D,
                                       CMMakeMsxKeyInfo(@"f", @"F"), @EC_F,
                                       CMMakeMsxKeyInfo(@"g", @"G"), @EC_G,
                                       CMMakeMsxKeyInfo(@"h", @"H"), @EC_H,
                                       CMMakeMsxKeyInfo(@"j", @"J"), @EC_J,
                                       CMMakeMsxKeyInfo(@"k", @"K"), @EC_K,
                                       CMMakeMsxKeyInfo(@"l", @"L"), @EC_L,
                                       CMMakeMsxKeyInfo(@";", @":"), @EC_SEMICOL,
                                       CMMakeMsxKeyInfo(@"'", @"\""), @EC_COLON,
                                       CMMakeMsxKeyInfo(@"\\", @"|"), @EC_BKSLASH,
                                       
                                       CMMakeMsxKeyInfo(@"z", @"Z"), @EC_Z,
                                       CMMakeMsxKeyInfo(@"x", @"X"), @EC_X,
                                       CMMakeMsxKeyInfo(@"c", @"C"), @EC_C,
                                       CMMakeMsxKeyInfo(@"v", @"V"), @EC_V,
                                       CMMakeMsxKeyInfo(@"b", @"B"), @EC_B,
                                       CMMakeMsxKeyInfo(@"n", @"N"), @EC_N,
                                       CMMakeMsxKeyInfo(@"m", @"M"), @EC_M,
                                       CMMakeMsxKeyInfo(@",", @"<"), @EC_COMMA,
                                       CMMakeMsxKeyInfo(@".", @">"), @EC_PERIOD,
                                       CMMakeMsxKeyInfo(@"/", @"?"), @EC_DIV,
                                       CMMakeMsxKeyInfo(@"`", @"'"), @EC_UNDSCRE,
                                       
                                       nil];
    
    NSMutableDictionary *brazilianLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            CMMakeMsxKeyInfo(@"ç", @"Ç"), @EC_RBRACK,
                                            CMMakeMsxKeyInfo(@"1", @"!"), @EC_1,
                                            CMMakeMsxKeyInfo(@"2", @"\""), @EC_2,
                                            CMMakeMsxKeyInfo(@"3", @"#"), @EC_3,
                                            CMMakeMsxKeyInfo(@"4", @"$"), @EC_4,
                                            CMMakeMsxKeyInfo(@"5", @"%"), @EC_5,
                                            CMMakeMsxKeyInfo(@"6", @"^"), @EC_6,
                                            CMMakeMsxKeyInfo(@"7", @"&"), @EC_7,
                                            CMMakeMsxKeyInfo(@"8", @"'"), @EC_8,
                                            CMMakeMsxKeyInfo(@"9", @"("), @EC_9,
                                            CMMakeMsxKeyInfo(@"0", @")"), @EC_0,
                                            CMMakeMsxKeyInfo(@"-", @"_"), @EC_NEG,
                                            CMMakeMsxKeyInfo(@"=", @"+"), @EC_CIRCFLX,
                                            
                                            CMMakeMsxKeyInfo(@"q", @"Q"), @EC_Q,
                                            CMMakeMsxKeyInfo(@"w", @"W"), @EC_W,
                                            CMMakeMsxKeyInfo(@"e", @"E"), @EC_E,
                                            CMMakeMsxKeyInfo(@"r", @"R"), @EC_R,
                                            CMMakeMsxKeyInfo(@"t", @"T"), @EC_T,
                                            CMMakeMsxKeyInfo(@"y", @"Y"), @EC_Y,
                                            CMMakeMsxKeyInfo(@"u", @"U"), @EC_U,
                                            CMMakeMsxKeyInfo(@"i", @"I"), @EC_I,
                                            CMMakeMsxKeyInfo(@"o", @"O"), @EC_O,
                                            CMMakeMsxKeyInfo(@"p", @"P"), @EC_P,
                                            CMMakeMsxKeyInfo(@"'", @"`"), @EC_AT,
                                            CMMakeMsxKeyInfo(@"[", @"]"), @EC_LBRACK,
                                            
                                            CMMakeMsxKeyInfo(@"a", @"A"), @EC_A,
                                            CMMakeMsxKeyInfo(@"s", @"S"), @EC_S,
                                            CMMakeMsxKeyInfo(@"d", @"D"), @EC_D,
                                            CMMakeMsxKeyInfo(@"f", @"F"), @EC_F,
                                            CMMakeMsxKeyInfo(@"g", @"G"), @EC_G,
                                            CMMakeMsxKeyInfo(@"h", @"H"), @EC_H,
                                            CMMakeMsxKeyInfo(@"j", @"J"), @EC_J,
                                            CMMakeMsxKeyInfo(@"k", @"K"), @EC_K,
                                            CMMakeMsxKeyInfo(@"l", @"L"), @EC_L,
                                            CMMakeMsxKeyInfo(@"~", @"^"), @EC_SEMICOL,
                                            CMMakeMsxKeyInfo(@"*", @"@"), @EC_COLON,
                                            CMMakeMsxKeyInfo(@"{", @"}"), @EC_BKSLASH,
                                            
                                            CMMakeMsxKeyInfo(@"z", @"Z"), @EC_Z,
                                            CMMakeMsxKeyInfo(@"x", @"X"), @EC_X,
                                            CMMakeMsxKeyInfo(@"c", @"C"), @EC_C,
                                            CMMakeMsxKeyInfo(@"v", @"V"), @EC_V,
                                            CMMakeMsxKeyInfo(@"b", @"B"), @EC_B,
                                            CMMakeMsxKeyInfo(@"n", @"N"), @EC_N,
                                            CMMakeMsxKeyInfo(@"m", @"M"), @EC_M,
                                            CMMakeMsxKeyInfo(@",", @"<"), @EC_COMMA,
                                            CMMakeMsxKeyInfo(@".", @">"), @EC_PERIOD,
                                            CMMakeMsxKeyInfo(@";", @":"), @EC_DIV,
                                            CMMakeMsxKeyInfo(@"/", @"?"), @EC_UNDSCRE,
                                            
                                            nil];
    
    NSMutableDictionary *estonianLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           CMMakeMsxKeyInfo(@"^", @"~"), @EC_RBRACK,
                                           CMMakeMsxKeyInfo(@"1", @"!"), @EC_1,
                                           CMMakeMsxKeyInfo(@"2", @"\""), @EC_2,
                                           CMMakeMsxKeyInfo(@"3", @"#"), @EC_3,
                                           CMMakeMsxKeyInfo(@"4", @"$"), @EC_4,
                                           CMMakeMsxKeyInfo(@"5", @"%"), @EC_5,
                                           CMMakeMsxKeyInfo(@"6", @"&"), @EC_6,
                                           CMMakeMsxKeyInfo(@"7", @"/"), @EC_7,
                                           CMMakeMsxKeyInfo(@"8", @"("), @EC_8,
                                           CMMakeMsxKeyInfo(@"9", @")"), @EC_9,
                                           CMMakeMsxKeyInfo(@"0", @"="), @EC_0,
                                           CMMakeMsxKeyInfo(@"+", @"?"), @EC_NEG,
                                           CMMakeMsxKeyInfo(@"'", @"`"), @EC_CIRCFLX,
                                           
                                           CMMakeMsxKeyInfo(@"q", @"Q"), @EC_Q,
                                           CMMakeMsxKeyInfo(@"w", @"W"), @EC_W,
                                           CMMakeMsxKeyInfo(@"e", @"E"), @EC_E,
                                           CMMakeMsxKeyInfo(@"r", @"R"), @EC_R,
                                           CMMakeMsxKeyInfo(@"t", @"T"), @EC_T,
                                           CMMakeMsxKeyInfo(@"y", @"Y"), @EC_Y,
                                           CMMakeMsxKeyInfo(@"u", @"U"), @EC_U,
                                           CMMakeMsxKeyInfo(@"i", @"I"), @EC_I,
                                           CMMakeMsxKeyInfo(@"o", @"O"), @EC_O,
                                           CMMakeMsxKeyInfo(@"p", @"P"), @EC_P,
                                           CMMakeMsxKeyInfo(@"[", @"{"), @EC_AT,
                                           CMMakeMsxKeyInfo(@"]", @"}"), @EC_LBRACK,
                                           
                                           CMMakeMsxKeyInfo(@"a", @"A"), @EC_A,
                                           CMMakeMsxKeyInfo(@"s", @"S"), @EC_S,
                                           CMMakeMsxKeyInfo(@"d", @"D"), @EC_D,
                                           CMMakeMsxKeyInfo(@"f", @"F"), @EC_F,
                                           CMMakeMsxKeyInfo(@"g", @"G"), @EC_G,
                                           CMMakeMsxKeyInfo(@"h", @"H"), @EC_H,
                                           CMMakeMsxKeyInfo(@"j", @"J"), @EC_J,
                                           CMMakeMsxKeyInfo(@"k", @"K"), @EC_K,
                                           CMMakeMsxKeyInfo(@"l", @"L"), @EC_L,
                                           CMMakeMsxKeyInfo(@"\\", @"|"), @EC_SEMICOL,
                                           CMMakeMsxKeyInfo(@"<", @">"), @EC_COLON,
                                           CMMakeMsxKeyInfo(@"'", @"*"), @EC_BKSLASH,
                                           
                                           CMMakeMsxKeyInfo(@"z", @"Z"), @EC_Z,
                                           CMMakeMsxKeyInfo(@"x", @"X"), @EC_X,
                                           CMMakeMsxKeyInfo(@"c", @"C"), @EC_C,
                                           CMMakeMsxKeyInfo(@"v", @"V"), @EC_V,
                                           CMMakeMsxKeyInfo(@"b", @"B"), @EC_B,
                                           CMMakeMsxKeyInfo(@"n", @"N"), @EC_N,
                                           CMMakeMsxKeyInfo(@"m", @"M"), @EC_M,
                                           CMMakeMsxKeyInfo(@",", @";"), @EC_COMMA,
                                           CMMakeMsxKeyInfo(@".", @":"), @EC_PERIOD,
                                           CMMakeMsxKeyInfo(@"-", @"_"), @EC_DIV,
                                           CMMakeMsxKeyInfo(@" ", @" "), @EC_UNDSCRE, // None
                                           
                                           nil];
    
    NSMutableDictionary *frenchLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         CMMakeMsxKeyInfo(@"#", @"£"), @EC_RBRACK,
                                         CMMakeMsxKeyInfo(@"&", @"1"), @EC_1,
                                         CMMakeMsxKeyInfo(@"é", @"2"), @EC_2,
                                         CMMakeMsxKeyInfo(@"\"", @"3"), @EC_3,
                                         CMMakeMsxKeyInfo(@"'", @"4"), @EC_4,
                                         CMMakeMsxKeyInfo(@"(", @"5"), @EC_5,
                                         CMMakeMsxKeyInfo(@"§", @"6"), @EC_6,
                                         CMMakeMsxKeyInfo(@"è", @"7"), @EC_7,
                                         CMMakeMsxKeyInfo(@"!", @"8"), @EC_8,
                                         CMMakeMsxKeyInfo(@"ç", @"9"), @EC_9,
                                         CMMakeMsxKeyInfo(@"à", @"0"), @EC_0,
                                         CMMakeMsxKeyInfo(@")", @"º"), @EC_NEG,
                                         CMMakeMsxKeyInfo(@"-", @"_"), @EC_CIRCFLX,
                                         
                                         CMMakeMsxKeyInfo(@"a", @"A"), @EC_Q,
                                         CMMakeMsxKeyInfo(@"z", @"Z"), @EC_W,
                                         CMMakeMsxKeyInfo(@"e", @"E"), @EC_E,
                                         CMMakeMsxKeyInfo(@"r", @"R"), @EC_R,
                                         CMMakeMsxKeyInfo(@"t", @"T"), @EC_T,
                                         CMMakeMsxKeyInfo(@"y", @"Y"), @EC_Y,
                                         CMMakeMsxKeyInfo(@"u", @"U"), @EC_U,
                                         CMMakeMsxKeyInfo(@"i", @"I"), @EC_I,
                                         CMMakeMsxKeyInfo(@"o", @"O"), @EC_O,
                                         CMMakeMsxKeyInfo(@"p", @"P"), @EC_P,
                                         CMMakeMsxKeyInfo(@"`", @"'"), @EC_AT,
                                         CMMakeMsxKeyInfo(@"$", @"*"), @EC_LBRACK,
                                         
                                         CMMakeMsxKeyInfo(@"q", @"Q"), @EC_A,
                                         CMMakeMsxKeyInfo(@"s", @"S"), @EC_S,
                                         CMMakeMsxKeyInfo(@"d", @"D"), @EC_D,
                                         CMMakeMsxKeyInfo(@"f", @"F"), @EC_F,
                                         CMMakeMsxKeyInfo(@"g", @"G"), @EC_G,
                                         CMMakeMsxKeyInfo(@"h", @"H"), @EC_H,
                                         CMMakeMsxKeyInfo(@"j", @"J"), @EC_J,
                                         CMMakeMsxKeyInfo(@"k", @"K"), @EC_K,
                                         CMMakeMsxKeyInfo(@"l", @"L"), @EC_L,
                                         CMMakeMsxKeyInfo(@"m", @"M"), @EC_SEMICOL,
                                         CMMakeMsxKeyInfo(@"ù", @"%"), @EC_COLON,
                                         CMMakeMsxKeyInfo(@"<", @">"), @EC_BKSLASH,
                                         
                                         CMMakeMsxKeyInfo(@"w", @"W"), @EC_Z,
                                         CMMakeMsxKeyInfo(@"x", @"X"), @EC_X,
                                         CMMakeMsxKeyInfo(@"c", @"C"), @EC_C,
                                         CMMakeMsxKeyInfo(@"v", @"V"), @EC_V,
                                         CMMakeMsxKeyInfo(@"b", @"B"), @EC_B,
                                         CMMakeMsxKeyInfo(@"n", @"N"), @EC_N,
                                         CMMakeMsxKeyInfo(@",", @"?"), @EC_M,
                                         CMMakeMsxKeyInfo(@";", @"."), @EC_COMMA,
                                         CMMakeMsxKeyInfo(@":", @"/"), @EC_PERIOD,
                                         CMMakeMsxKeyInfo(@"=", @"+"), @EC_DIV,
                                         CMMakeMsxKeyInfo(@" ", @" "), @EC_UNDSCRE, // None
                                         
                                         nil];
    
    NSMutableDictionary *germanLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         CMMakeMsxKeyInfo(@"#", @"^"), @EC_RBRACK,
                                         CMMakeMsxKeyInfo(@"1", @"!"), @EC_1,
                                         CMMakeMsxKeyInfo(@"2", @"\""), @EC_2,
                                         CMMakeMsxKeyInfo(@"3", @"§"), @EC_3,
                                         CMMakeMsxKeyInfo(@"4", @"$"), @EC_4,
                                         CMMakeMsxKeyInfo(@"5", @"%"), @EC_5,
                                         CMMakeMsxKeyInfo(@"6", @"&"), @EC_6,
                                         CMMakeMsxKeyInfo(@"7", @"/"), @EC_7,
                                         CMMakeMsxKeyInfo(@"8", @"("), @EC_8,
                                         CMMakeMsxKeyInfo(@"9", @")"), @EC_9,
                                         CMMakeMsxKeyInfo(@"0", @"="), @EC_0,
                                         CMMakeMsxKeyInfo(@"ß", @"?"), @EC_NEG,
                                         CMMakeMsxKeyInfo(@"'", @"`"), @EC_CIRCFLX,
                                         
                                         CMMakeMsxKeyInfo(@"q", @"Q"), @EC_Q,
                                         CMMakeMsxKeyInfo(@"w", @"W"), @EC_W,
                                         CMMakeMsxKeyInfo(@"e", @"E"), @EC_E,
                                         CMMakeMsxKeyInfo(@"r", @"R"), @EC_R,
                                         CMMakeMsxKeyInfo(@"t", @"T"), @EC_T,
                                         CMMakeMsxKeyInfo(@"z", @"Z"), @EC_Y,
                                         CMMakeMsxKeyInfo(@"u", @"U"), @EC_U,
                                         CMMakeMsxKeyInfo(@"i", @"I"), @EC_I,
                                         CMMakeMsxKeyInfo(@"o", @"O"), @EC_O,
                                         CMMakeMsxKeyInfo(@"p", @"P"), @EC_P,
                                         CMMakeMsxKeyInfo(@"ü", @"Ü"), @EC_AT,
                                         CMMakeMsxKeyInfo(@"+", @"*"), @EC_LBRACK,
                                         
                                         CMMakeMsxKeyInfo(@"a", @"A"), @EC_A,
                                         CMMakeMsxKeyInfo(@"s", @"S"), @EC_S,
                                         CMMakeMsxKeyInfo(@"d", @"D"), @EC_D,
                                         CMMakeMsxKeyInfo(@"f", @"F"), @EC_F,
                                         CMMakeMsxKeyInfo(@"g", @"G"), @EC_G,
                                         CMMakeMsxKeyInfo(@"h", @"H"), @EC_H,
                                         CMMakeMsxKeyInfo(@"j", @"J"), @EC_J,
                                         CMMakeMsxKeyInfo(@"k", @"K"), @EC_K,
                                         CMMakeMsxKeyInfo(@"l", @"L"), @EC_L,
                                         CMMakeMsxKeyInfo(@"ö", @"Ö"), @EC_SEMICOL,
                                         CMMakeMsxKeyInfo(@"ä", @"Ä"), @EC_COLON,
                                         CMMakeMsxKeyInfo(@"<", @">"), @EC_BKSLASH,
                                         
                                         CMMakeMsxKeyInfo(@"y", @"Y"), @EC_Z,
                                         CMMakeMsxKeyInfo(@"x", @"X"), @EC_X,
                                         CMMakeMsxKeyInfo(@"c", @"C"), @EC_C,
                                         CMMakeMsxKeyInfo(@"v", @"V"), @EC_V,
                                         CMMakeMsxKeyInfo(@"b", @"B"), @EC_B,
                                         CMMakeMsxKeyInfo(@"n", @"N"), @EC_N,
                                         CMMakeMsxKeyInfo(@"m", @"M"), @EC_M,
                                         CMMakeMsxKeyInfo(@",", @";"), @EC_COMMA,
                                         CMMakeMsxKeyInfo(@".", @":"), @EC_PERIOD,
                                         CMMakeMsxKeyInfo(@"-", @"_"), @EC_DIV,
                                         CMMakeMsxKeyInfo(@" ", @" "), @EC_UNDSCRE, // None
                                         
                                         nil];
    
    NSMutableDictionary *japaneseLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           CMMakeMsxKeyInfo(@"]", @"}"), @EC_RBRACK,
                                           CMMakeMsxKeyInfo(@"1", @"!"), @EC_1,
                                           CMMakeMsxKeyInfo(@"2", @"\""), @EC_2,
                                           CMMakeMsxKeyInfo(@"3", @"#"), @EC_3,
                                           CMMakeMsxKeyInfo(@"4", @"$"), @EC_4,
                                           CMMakeMsxKeyInfo(@"5", @"%"), @EC_5,
                                           CMMakeMsxKeyInfo(@"6", @"&"), @EC_6,
                                           CMMakeMsxKeyInfo(@"7", @"'"), @EC_7,
                                           CMMakeMsxKeyInfo(@"8", @"("), @EC_8,
                                           CMMakeMsxKeyInfo(@"9", @")"), @EC_9,
                                           CMMakeMsxKeyInfo(@"0", @" "), @EC_0,
                                           CMMakeMsxKeyInfo(@"-", @"="), @EC_NEG,
                                           CMMakeMsxKeyInfo(@"^", @"~"), @EC_CIRCFLX,
                                           
                                           CMMakeMsxKeyInfo(@"q", @"Q"), @EC_Q,
                                           CMMakeMsxKeyInfo(@"w", @"W"), @EC_W,
                                           CMMakeMsxKeyInfo(@"e", @"E"), @EC_E,
                                           CMMakeMsxKeyInfo(@"r", @"R"), @EC_R,
                                           CMMakeMsxKeyInfo(@"t", @"T"), @EC_T,
                                           CMMakeMsxKeyInfo(@"y", @"Y"), @EC_Y,
                                           CMMakeMsxKeyInfo(@"u", @"U"), @EC_U,
                                           CMMakeMsxKeyInfo(@"i", @"I"), @EC_I,
                                           CMMakeMsxKeyInfo(@"o", @"O"), @EC_O,
                                           CMMakeMsxKeyInfo(@"p", @"P"), @EC_P,
                                           CMMakeMsxKeyInfo(@"@", @"`"), @EC_AT,
                                           CMMakeMsxKeyInfo(@"[", @"{"), @EC_LBRACK,
                                           
                                           CMMakeMsxKeyInfo(@"a", @"A"), @EC_A,
                                           CMMakeMsxKeyInfo(@"s", @"S"), @EC_S,
                                           CMMakeMsxKeyInfo(@"d", @"D"), @EC_D,
                                           CMMakeMsxKeyInfo(@"f", @"F"), @EC_F,
                                           CMMakeMsxKeyInfo(@"g", @"G"), @EC_G,
                                           CMMakeMsxKeyInfo(@"h", @"H"), @EC_H,
                                           CMMakeMsxKeyInfo(@"j", @"J"), @EC_J,
                                           CMMakeMsxKeyInfo(@"k", @"K"), @EC_K,
                                           CMMakeMsxKeyInfo(@"l", @"L"), @EC_L,
                                           CMMakeMsxKeyInfo(@";", @"+"), @EC_SEMICOL,
                                           CMMakeMsxKeyInfo(@":", @"*"), @EC_COLON,
                                           CMMakeMsxKeyInfo(@"¥", @"|"), @EC_BKSLASH,
                                           
                                           CMMakeMsxKeyInfo(@"z", @"Z"), @EC_Z,
                                           CMMakeMsxKeyInfo(@"x", @"X"), @EC_X,
                                           CMMakeMsxKeyInfo(@"c", @"C"), @EC_C,
                                           CMMakeMsxKeyInfo(@"v", @"V"), @EC_V,
                                           CMMakeMsxKeyInfo(@"b", @"B"), @EC_B,
                                           CMMakeMsxKeyInfo(@"n", @"N"), @EC_N,
                                           CMMakeMsxKeyInfo(@"m", @"M"), @EC_M,
                                           CMMakeMsxKeyInfo(@",", @"<"), @EC_COMMA,
                                           CMMakeMsxKeyInfo(@".", @">"), @EC_PERIOD,
                                           CMMakeMsxKeyInfo(@"/", @"?"), @EC_DIV,
                                           CMMakeMsxKeyInfo(@" ", @"_"), @EC_UNDSCRE,
                                           
                                           nil];
    
    // Korean is the same as Japanese, except for the currency symbol
    
    NSMutableDictionary *koreanLayout = [[japaneseLayout mutableCopy] autorelease];
    [koreanLayout setObject:CMMakeMsxKeyInfo(@"￦", @"|") forKey:@EC_BKSLASH];
    
    NSMutableDictionary *russianLayout = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          CMMakeMsxKeyInfo(@">", @"."), @EC_RBRACK,
                                          CMMakeMsxKeyInfo(@"+", @";"), @EC_1,
                                          CMMakeMsxKeyInfo(@"!", @"1"), @EC_2,
                                          CMMakeMsxKeyInfo(@"\"", @"2"), @EC_3,
                                          CMMakeMsxKeyInfo(@"#", @"3"), @EC_4,
                                          CMMakeMsxKeyInfo(@"Ȣ", @"4"), @EC_5,
                                          CMMakeMsxKeyInfo(@"%", @"5"), @EC_6,
                                          CMMakeMsxKeyInfo(@"&", @"6"), @EC_7,
                                          CMMakeMsxKeyInfo(@"'", @"7"), @EC_8,
                                          CMMakeMsxKeyInfo(@"(", @"8"), @EC_9,
                                          CMMakeMsxKeyInfo(@")", @"9"), @EC_0,
                                          CMMakeMsxKeyInfo(@"$", @"0"), @EC_NEG,
                                          CMMakeMsxKeyInfo(@"=", @"_"), @EC_CIRCFLX,
                                          
                                          CMMakeMsxKeyInfo(@"j", @"J"), @EC_Q,
                                          CMMakeMsxKeyInfo(@"c", @"C"), @EC_W,
                                          CMMakeMsxKeyInfo(@"u", @"U"), @EC_E,
                                          CMMakeMsxKeyInfo(@"k", @"K"), @EC_R,
                                          CMMakeMsxKeyInfo(@"e", @"E"), @EC_T,
                                          CMMakeMsxKeyInfo(@"n", @"N"), @EC_Y,
                                          CMMakeMsxKeyInfo(@"g", @"G"), @EC_U,
                                          CMMakeMsxKeyInfo(@"[", @"{"), @EC_I,
                                          CMMakeMsxKeyInfo(@"]", @"}"), @EC_O,
                                          CMMakeMsxKeyInfo(@"z", @"Z"), @EC_P,
                                          CMMakeMsxKeyInfo(@"h", @"H"), @EC_AT,
                                          CMMakeMsxKeyInfo(@"*", @":"), @EC_LBRACK,
                                          
                                          CMMakeMsxKeyInfo(@"f", @"F"), @EC_A,
                                          CMMakeMsxKeyInfo(@"y", @"Y"), @EC_S,
                                          CMMakeMsxKeyInfo(@"w", @"W"), @EC_D,
                                          CMMakeMsxKeyInfo(@"a", @"A"), @EC_F,
                                          CMMakeMsxKeyInfo(@"p", @"P"), @EC_G,
                                          CMMakeMsxKeyInfo(@"r", @"R"), @EC_H,
                                          CMMakeMsxKeyInfo(@"o", @"O"), @EC_J,
                                          CMMakeMsxKeyInfo(@"l", @"L"), @EC_K,
                                          CMMakeMsxKeyInfo(@"d", @"D"), @EC_L,
                                          CMMakeMsxKeyInfo(@"v", @"V"), @EC_SEMICOL,
                                          CMMakeMsxKeyInfo(@"\\", @"\\"), @EC_COLON,
                                          CMMakeMsxKeyInfo(@"-", @"^"), @EC_BKSLASH,
                                          
                                          CMMakeMsxKeyInfo(@"q", @"Q"), @EC_Z,
                                          CMMakeMsxKeyInfo(@"|", @"~"), @EC_X,
                                          CMMakeMsxKeyInfo(@"s", @"S"), @EC_C,
                                          CMMakeMsxKeyInfo(@"m", @"M"), @EC_V,
                                          CMMakeMsxKeyInfo(@"i", @"I"), @EC_B,
                                          CMMakeMsxKeyInfo(@"t", @"T"), @EC_N,
                                          CMMakeMsxKeyInfo(@"x", @"X"), @EC_M,
                                          CMMakeMsxKeyInfo(@"b", @"B"), @EC_COMMA,
                                          CMMakeMsxKeyInfo(@"@", @" "), @EC_PERIOD,
                                          CMMakeMsxKeyInfo(@"<", @","), @EC_DIV,
                                          CMMakeMsxKeyInfo(@"?", @"/"), @EC_UNDSCRE,
                                          
                                          nil];
    
    // Spanish is mostly the same as European
    
    NSMutableDictionary *spanishLayout = [[euroLayout mutableCopy] autorelease];
    [spanishLayout setObject:CMMakeMsxKeyInfo(@";", @":") forKey:@EC_RBRACK];
    [spanishLayout setObject:CMMakeMsxKeyInfo(@"ñ", @"Ñ") forKey:@EC_SEMICOL];
    [spanishLayout setObject:CMMakeMsxKeyInfo(@"'", @"~") forKey:@EC_SEMICOL];
    
    // Swedish is mostly the same as German
    
    NSMutableDictionary *swedishLayout = [[germanLayout mutableCopy] autorelease];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"'", @"*") forKey:@EC_RBRACK];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"3", @"#") forKey:@EC_3];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"+", @"?") forKey:@EC_NEG];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"é", @"É") forKey:@EC_CIRCFLX];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"y", @"Y") forKey:@EC_Y];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"å", @"Å") forKey:@EC_AT];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"ü", @"Ü") forKey:@EC_LBRACK];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"z", @"Z") forKey:@EC_Z];
    [swedishLayout setObject:CMMakeMsxKeyInfo(@"'", @"`") forKey:@EC_UNDSCRE];
    
    typewriterLayouts = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         euroLayout, @CMKeyLayoutArabic,
                         brazilianLayout, @CMKeyLayoutBrazilian,
                         estonianLayout, @CMKeyLayoutEstonian,
                         frenchLayout, @CMKeyLayoutFrench,
                         germanLayout, @CMKeyLayoutGerman,
                         euroLayout, @CMKeyLayoutEuropean,
                         japaneseLayout, @CMKeyLayoutJapanese,
                         koreanLayout, @CMKeyLayoutKorean,
                         russianLayout, @CMKeyLayoutRussian,
                         spanishLayout, @CMKeyLayoutSpanish,
                         swedishLayout, @CMKeyLayoutSwedish,
                         nil];
}

- (id)init
{
    if ((self = [super init]))
    {
        keyLock = [[NSObject alloc] init];
        keysToPasteLock = [[NSObject alloc] init];
        
        keysDown = [[NSMutableSet alloc] init];
        keysToPaste = [[NSMutableArray alloc] init];
        
        virtualCodeOfPressedKey = CMKeyNoCode;
        keyPressTime = 0;
        
        [self resetState];
    }
    
    return self;
}

- (void)dealloc
{
    [keysDown release];
    [keysToPaste release];
    
    [keyLock release];
    [keysToPasteLock release];
    
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
    if (([event modifierFlags] & NSCommandKeyMask) != 0)
        return;
    
    [self handleKeyEvent:[event keyCode] isDown:YES];
}

- (void)keyUp:(NSEvent*)event
{
    if ([event isARepeat])
        return;
    
#ifdef DEBUG_KEY_STATE
    NSLog(@"keyUp: %i", [event keyCode]);
#endif
    
    [self handleKeyEvent:[event keyCode] isDown:NO];
}

- (void)flagsChanged:(NSEvent *)event
{
#ifdef DEBUG_KEY_STATE
    NSLog(@"flagsChanged: %1$x; flags: %2$ld (0x%2$lx)",
          event.keyCode, event.modifierFlags);
#endif
    
    if ([event keyCode] == CMKeyLeftShift)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftShiftKeyMask) == CMLeftShiftKeyMask)];
    else if ([event keyCode] == CMKeyRightShift)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightShiftKeyMask) == CMRightShiftKeyMask)];
    else if ([event keyCode] == CMKeyLeftAlt)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftAltKeyMask) == CMLeftAltKeyMask)];
    else if ([event keyCode] == CMKeyRightAlt)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightAltKeyMask) == CMRightAltKeyMask)];
    else if ([event keyCode] == CMKeyLeftControl)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftControlKeyMask) == CMLeftControlKeyMask)];
    else if ([event keyCode] == CMKeyRightControl)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightControlKeyMask) == CMRightControlKeyMask)];
    else if ([event keyCode] == CMKeyLeftCommand)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMLeftCommandKeyMask) == CMLeftCommandKeyMask)];
    else if ([event keyCode] == CMKeyRightCommand)
        [self handleKeyEvent:[event keyCode]
                      isDown:(([event modifierFlags] & CMRightCommandKeyMask) == CMRightCommandKeyMask)];
    else if ([event keyCode] == CMKeyCapsLock)
    {
        // FIXME: caps lock state is broken
        // Caps Lock has no up/down - just toggle state
        
        CMKeyboardInput *input = [CMKeyboardInput keyboardInputWithKeyCode:[event keyCode]];
        NSInteger virtualCode = [[theEmulator keyboardLayout] virtualCodeForInputMethod:input];
        
        if (virtualCode != CMUnknownVirtualCode)
        {
            NSNumber *virtualCodeObject = @(virtualCode);
            
            @synchronized (keyLock)
            {
                if ([keysDown containsObject:virtualCodeObject])
                    [keysDown removeObject:virtualCodeObject];
                else
                    [keysDown addObject:virtualCodeObject];
            }
        }
    }
    
    if ([event keyCode] == CMKeyLeftCommand || [event keyCode] == CMKeyRightCommand)
    {
        // If Command is toggled while another key is down, releasing the
        // other key no longer generates a keyUp event, and the virtual key
        // 'sticks'. Release all virtual keys if Command is pressed.
        
        [self releaseAllKeys];
    }
}

#pragma mark - Public methods

- (BOOL)pasteText:(NSString *)text
      keyLayoutId:(NSInteger)keyLayoutId
{
    NSMutableDictionary *keyLayout = [typewriterLayouts objectForKey:@(keyLayoutId)];
    if (!keyLayout)
        return NO; // Invalid key layout
    
#ifdef DEBUG
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
#endif
    
    NSMutableArray *textAsMsxCodes = [NSMutableArray array];
    for (int i = 0, n = [text length]; i < n; i++)
    {
        NSString *character = [text substringWithRange:NSMakeRange(i, 1)];
        
        [keyLayout enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
        {
            if ([obj isEqual:character])
            {
                [textAsMsxCodes addObject:key];
                *stop = YES;
            }
        }];
    }
    
#ifdef DEBUG
    NSLog(@"Pasting %ld keys", [textAsMsxCodes count]);
#endif
    
    @synchronized(keysToPasteLock)
    {
        [keysToPaste addObjectsFromArray:textAsMsxCodes];
    }
    
#ifdef DEBUG
    NSLog(@"pasteText: Took %.02fms",
          [NSDate timeIntervalSinceReferenceDate] - startTime);
#endif
    
    return YES;
}

- (void)releaseAllKeys
{
    // Release the keys currently held
    @synchronized (keyLock)
    {
        [keysDown removeAllObjects];
    }
    
    // Clear the paste queue
    @synchronized (keysToPasteLock)
    {
        [keysToPaste removeAllObjects];
    }
    
    // Clear currently held keys
    virtualCodeOfPressedKey = CMKeyNoCode;
    keyPressTime = 0;
}

- (BOOL)areAnyKeysDown
{
    @synchronized(keyLock)
    {
        return [keysDown count] > 0;
    }
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
        NSLog(@"CocoaKeyboard: -Focus");
#endif
        // Emulator has lost focus - release all virtual keys
        [self resetState];
    }
    else
    {
#ifdef DEBUG
        NSLog(@"CocoaKeyboard: +Focus");
#endif
    }
}

- (NSString *)inputNameForVirtualCode:(NSUInteger)virtualCode
                           shiftState:(NSInteger)shiftState
                             layoutId:(NSInteger)layoutId
{
    // Check the list of static keys
    NSString *staticKeyLabel = [staticLayout objectForKey:@(virtualCode)];
    if (staticKeyLabel)
        return staticKeyLabel;
    
    // Check the typewriter keys
    NSMutableDictionary *layout = [typewriterLayouts objectForKey:@(layoutId)];
    if (layout)
    {
        CMMsxKeyInfo *keyInfo = [layout objectForKey:@(virtualCode)];
        if (keyInfo)
        {
            if (shiftState == CMKeyShiftStateNormal)
                return [keyInfo defaultStateLabel];
            else if (shiftState == CMKeyShiftStateShifted)
                return [keyInfo shiftedStateLabel];
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

+ (NSInteger)layoutIdForMachineIdentifier:(NSString *)machineId
{
    __block NSInteger machineLayoutId = 0;
    
    [machineLayoutMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        NSNumber *layoutId = key;
        NSArray *machineIds = obj;
        
        [machineIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            if ([machineId isEqualToString:obj])
            {
                machineLayoutId = [layoutId integerValue];
                *stop = YES;
            }
        }];
        
        if (machineLayoutId != 0)
            *stop = YES;
    }];
    
    return (machineLayoutId == 0) ? CMKeyLayoutDefault : machineLayoutId;
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
    
    [[theEmulator inputDeviceLayouts] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMInputDeviceLayout *layout = obj;
        NSInteger virtualCode = [layout virtualCodeForInputMethod:input];
        
        if (virtualCode != CMUnknownVirtualCode)
        {
            @synchronized (keyLock)
            {
                if (isDown)
                    [keysDown addObject:@(virtualCode)];
                else
                    [keysDown removeObject:@(virtualCode)];
            }
        }
    }];
}

- (void)updateKeyboardState
{
    // Reset the key matrix
    inputEventReset();
    
    // Create a copy for the keys currently down (so that we can enumerate them)
    NSArray *keysDownNow;
    @synchronized(keyLock)
    {
        keysDownNow = [keysDown allObjects];
    }
    
    // Update the matrix for the keys currently down
    [keysDownNow enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        inputEventSet([obj integerValue]);
    }];
    
    NSTimeInterval timeNow = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval autoKeyPressInterval = timeNow - keyPressTime;
    BOOL autoKeypressExpired = autoKeyPressInterval > CMAutoPressTotalTimeSeconds;
    
    // Check the paste queue, if there are no pending auto-keypresses
    if ([keysToPaste count] > 0 && autoKeypressExpired)
    {
        @synchronized(keysToPasteLock)
        {
            virtualCodeOfPressedKey = [[keysToPaste objectAtIndex:0] integerValue];
            [keysToPaste removeObjectAtIndex:0];
        }
        
        keyPressTime = timeNow;
        
        autoKeypressExpired = NO;
    }
    
    // Check for programmatically depressed keys
    if (virtualCodeOfPressedKey != CMKeyNoCode)
    {
        // A key is programmatically depressed
        if (autoKeypressExpired)
        {
            // Keypress has expired - release it
            virtualCodeOfPressedKey = CMKeyNoCode;
            keyPressTime = 0;
        }
        else if (autoKeyPressInterval < CMAutoPressHoldTimeSeconds)
        {
            // Simulate keypress, but only if we haven't passed the hold time
            // threshold
            inputEventSet(virtualCodeOfPressedKey);
        }
    }
}

#pragma mark - BlueMSX Callbacks

extern CMEmulatorController *theEmulator;

void archPollInput()
{
    @autoreleasepool
    {
        [[theEmulator keyboard] updateKeyboardState];
    }
}

void archKeyboardSetSelectedKey(int keyCode) {}

@end
