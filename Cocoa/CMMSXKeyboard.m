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
#import "CMMSXKeyboard.h"

#include "InputEvent.h"

#pragma mark - CMKeyboardKey

@interface CMKeyboardKey : NSObject
{
    NSInteger _virtualCode;
    NSString *_label;
}

@property (nonatomic, assign) NSInteger virtualCode;
@property (nonatomic, retain) NSString *label;

- (NSString *)presentationLabelForState:(CMMSXKeyState)keyState;

@end

@implementation CMKeyboardKey

@synthesize virtualCode = _virtualCode;
@synthesize label = _label;

- (NSString *)presentationLabelForState:(CMMSXKeyState)keyState
{
    return [self label];
}

- (void)dealloc
{
    [self setLabel:nil];
    
    [super dealloc];
}

@end

@interface CMTypewriterKey : CMKeyboardKey
{
    NSString *_defaultStateChar;
    NSString *_shiftedStateChar;
}

@property (nonatomic, retain) NSString *defaultStateChar;
@property (nonatomic, retain) NSString *shiftedStateChar;

@end

@implementation CMTypewriterKey

@synthesize defaultStateChar = _defaultStateChar;
@synthesize shiftedStateChar = _shiftedStateChar;

- (NSString *)presentationLabelForState:(CMMSXKeyState)keyState
{
    // Explicit labels take precedence
    if ([self label])
        return [self label];
    
    if (keyState == CMMSXKeyStateDefault)
        return [self defaultStateChar];
    else if (keyState == CMMSXKeyStateShift)
        return [self shiftedStateChar];
    
    return nil;
}

- (void)dealloc
{
    [self setDefaultStateChar:nil];
    [self setShiftedStateChar:nil];
    
    [super dealloc];
}

@end

#pragma mark - CMKeyCombination

@implementation CMMSXKeyCombination

@synthesize virtualCode = _virtualCode;
@synthesize stateFlags = _stateFlags;

- (id)initWithVirtualCode:(NSInteger)virtualCode
               stateFlags:(CMMSXKeyState)stateFlags
{
    if ((self = [super init]))
    {
        _virtualCode = virtualCode;
        _stateFlags = stateFlags;
    }
    
    return self;
}

+ (CMMSXKeyCombination *)combinationWithVirtualCode:(NSInteger)virtualCode
                                         stateFlags:(CMMSXKeyState)stateFlags
{
    CMMSXKeyCombination *keyCombination = [[CMMSXKeyCombination alloc] initWithVirtualCode:virtualCode
                                                                                stateFlags:stateFlags];
    
    return [keyCombination autorelease];
}

@end

#pragma mark - CMKeyboardLayout

@interface CMMSXKeyboard ()

- (CMTypewriterKey *)mapTypewriterKeyWithCode:(NSInteger)virtualCode
                             defaultStateChar:(NSString *)defaultStateChar
                             shiftedStateChar:(NSString *)shiftedStateChar;
- (CMTypewriterKey *)mapTypewriterKeyWithCode:(NSInteger)virtualCode
                                 anyStateChar:(NSString *)anyStateChar
                                        label:(NSString *)label;
- (CMKeyboardKey *)mapKeyWithCode:(NSInteger)virtualCode
                            label:(NSString *)label;
- (void)unmapVirtualCode:(NSInteger)virtualCode;

+ (CMMSXKeyboard *)commonKeyboard;
+ (CMMSXKeyboard *)arabicKeyboard;
+ (CMMSXKeyboard *)europeanKeyboard;
+ (CMMSXKeyboard *)brazilianKeyboard;
+ (CMMSXKeyboard *)estonianKeyboard;
+ (CMMSXKeyboard *)frenchKeyboard;
+ (CMMSXKeyboard *)germanKeyboard;
+ (CMMSXKeyboard *)japaneseKeyboard;
+ (CMMSXKeyboard *)koreanKeyboard;
+ (CMMSXKeyboard *)russianKeyboard;
+ (CMMSXKeyboard *)spanishKeyboard;
+ (CMMSXKeyboard *)swedishKeyboard;

@end

@implementation CMMSXKeyboard

static NSDictionary *machineToLayoutMap;
static NSDictionary *layoutToKeyboardMap;

+ (void)initialize
{
    NSNumber *arabicLayout = @(CMMSXKeyboardArabic);
    NSNumber *brazilianLayout = @(CMMSXKeyboardBrazilian);
    NSNumber *estonianLayout = @(CMMSXKeyboardEstonian);
    NSNumber *europeanLayout = @(CMMSXKeyboardEuropean);
    NSNumber *frenchLayout = @(CMMSXKeyboardFrench);
    NSNumber *germanLayout = @(CMMSXKeyboardGerman);
    NSNumber *japaneseLayout = @(CMMSXKeyboardJapanese);
    NSNumber *koreanLayout = @(CMMSXKeyboardKorean);
    NSNumber *russianLayout = @(CMMSXKeyboardRussian);
    NSNumber *spanishLayout = @(CMMSXKeyboardSpanish);
    NSNumber *swedishLayout = @(CMMSXKeyboardSwedish);
    
    layoutToKeyboardMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [self arabicKeyboard],    arabicLayout,
                           [self brazilianKeyboard], brazilianLayout,
                           [self estonianKeyboard],  estonianLayout,
                           [self europeanKeyboard],  europeanLayout,
                           [self frenchKeyboard],    frenchLayout,
                           [self germanKeyboard],    germanLayout,
                           [self japaneseKeyboard],  japaneseLayout,
                           [self koreanKeyboard],    koreanLayout,
                           [self russianKeyboard],   russianLayout,
                           [self spanishKeyboard],   spanishLayout,
                           [self swedishKeyboard],   swedishLayout,
                           
                           nil];
    
    machineToLayoutMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                          arabicLayout, @"MSX - Al Alamiah AX-150",
                          arabicLayout, @"MSX - Al Alamiah AX-170",
                          arabicLayout, @"MSX - Perfect 1",
                          arabicLayout, @"MSX - Spectravideo SVI-738 Arabic",
                          arabicLayout, @"MSX2 - Al Alamiah AX-350II",
                          arabicLayout, @"MSX2 - Al Alamiah AX-370",
                          
                          brazilianLayout, @"MSX - Gradiente Expert 1.1",
                          brazilianLayout, @"MSX - Gradiente Expert 1.3",
                          brazilianLayout, @"MSX - Gradiente Expert DDPlus",
                          brazilianLayout, @"MSX - Gradiente Expert Plus",
                          brazilianLayout, @"MSX2 - Gradiente Expert 2.0",
                          brazilianLayout, @"MSX2+ - Brazilian",
                          brazilianLayout, @"MSX2+ - Ciel Expert 3 IDE",
                          brazilianLayout, @"MSX2+ - Ciel Expert 3 Turbo",
                          brazilianLayout, @"MSX2+ - Gradiente Expert AC88+",
                          brazilianLayout, @"MSX2+ - Gradiente Expert DDX+",
                          // Different layout
                          brazilianLayout, @"MSX - Gradiente Expert 1.0",
                          brazilianLayout, @"MSX - Sharp Epcom HotBit 1.1",
                          brazilianLayout, @"MSX - Sharp Epcom HotBit 1.2",
                          brazilianLayout, @"MSX - Sharp Epcom HotBit 1.3b",
                          brazilianLayout, @"MSX - Sharp Epcom HotBit 1.3p",
                          brazilianLayout, @"MSX2 - Sharp Epcom HotBit 2.0",
                          
                          estonianLayout, @"MSX - Yamaha YIS503IIR Estonian",
                          estonianLayout, @"MSX2 - Yamaha YIS503IIIR Estonian",
                          estonianLayout, @"MSX2 - Yamaha YIS805-128R2 Estonian",
                          
                          europeanLayout, @"MSX - Daewoo DPC-200E",
                          europeanLayout, @"MSX - Fenner DPC-200",
                          europeanLayout, @"MSX - Fenner FPC-500",
                          europeanLayout, @"MSX - Fenner SPC-800",
                          europeanLayout, @"MSX - Frael Bruc 100-1",
                          europeanLayout, @"MSX - Goldstar FC-200",
                          europeanLayout, @"MSX - Philips NMS-801",
                          europeanLayout, @"MSX - Philips VG-8000",
                          europeanLayout, @"MSX - Philips VG-8010",
                          europeanLayout, @"MSX - Philips VG-8020-00",
                          europeanLayout, @"MSX - Philips VG-8020-20",
                          europeanLayout, @"MSX - Spectravideo SVI-728",
                          europeanLayout, @"MSX - Spectravideo SVI-738",
                          europeanLayout, @"MSX - Spectravideo SVI-738 Henrik Gilvad",
                          europeanLayout, @"MSX - Toshiba HX-10",
                          europeanLayout, @"MSX - Toshiba HX-20I",
                          europeanLayout, @"MSX - Toshiba HX-21I",
                          europeanLayout, @"MSX - Toshiba HX-22I",
                          europeanLayout, @"MSX - Yamaha CX5M-1",
                          europeanLayout, @"MSX - Yamaha CX5M-2",
                          europeanLayout, @"MSX - Yamaha CX5MII",
                          europeanLayout, @"MSX - Yamaha CX5MII-128",
                          europeanLayout, @"MSX - Yamaha YIS303",
                          europeanLayout, @"MSX - Yamaha YIS503",
                          europeanLayout, @"MSX - Yamaha YIS503II",
                          europeanLayout, @"MSX - Yamaha YIS503M",
                          europeanLayout, @"MSX - Yashica YC-64",
                          europeanLayout, @"MSX2 - Fenner FPC-900",
                          europeanLayout, @"MSX2 - Philips NMS-8220",
                          europeanLayout, @"MSX2 - Philips NMS-8245",
                          europeanLayout, @"MSX2 - Philips NMS-8250",
                          europeanLayout, @"MSX2 - Philips NMS-8255",
                          europeanLayout, @"MSX2 - Philips NMS-8260+",
                          europeanLayout, @"MSX2 - Philips NMS-8280",
                          europeanLayout, @"MSX2 - Philips PTC MSX PC",
                          europeanLayout, @"MSX2 - Philips VG-8235",
                          europeanLayout, @"MSX2 - Philips VG-8240",
                          europeanLayout, @"MSX2 - Spectravideo SVI-738-2 CUC",
                          europeanLayout, @"MSX2 - Spectravideo SVI-738-2 JP Grobler",
                          europeanLayout, @"MSX2 - Toshiba FS-TM1",
                          europeanLayout, @"MSX2 - Toshiba HX-23I",
                          europeanLayout, @"MSX2 - Toshiba HX-34I",
                          europeanLayout, @"MSX2+ - European",
                          europeanLayout, @"MSX2+ - Spectravideo SVI-738-2+",
                          europeanLayout, @"MSXturboR - European",
                          // Different layout
                          europeanLayout, @"MSX - Canon V-20E",
                          europeanLayout, @"MSX - JVC HC-7GB",
                          europeanLayout, @"MSX - Mitsubishi ML-F48",
                          europeanLayout, @"MSX - Mitsubishi ML-F80",
                          europeanLayout, @"MSX - Mitsubishi ML-FX1",
                          europeanLayout, @"MSX - Pioneer PX-7UK",
                          europeanLayout, @"MSX - Sanyo MPC-100",
                          europeanLayout, @"MSX - Sanyo PHC-28S",
                          europeanLayout, @"MSX - Sanyo Wavy MPC-10",
                          europeanLayout, @"MSX - Sony HB-10P",
                          europeanLayout, @"MSX - Sony HB-55P",
                          europeanLayout, @"MSX - Sony HB-75P",
                          europeanLayout, @"MSX - Sony HB-101P",
                          europeanLayout, @"MSX - Sony HB-201P",
                          europeanLayout, @"MSX - Sony HB-501P",
                          europeanLayout, @"MSX - Yamaha YIS503F",
                          europeanLayout, @"MSX2 - Philips VG-8230",
                          europeanLayout, @"MSX2 - Sony HB-F9P",
                          europeanLayout, @"MSX2 - Sony HB-F500P",
                          europeanLayout, @"MSX2 - Sony HB-F700P",
                          europeanLayout, @"MSX2 - Sony HB-G900AP",
                          europeanLayout, @"MSX2 - Sony HB-G900P",
                          
                          frenchLayout, @"MSX - Canon V-20F",
                          frenchLayout, @"MSX - Olympia PHC-2",
                          frenchLayout, @"MSX - Olympia PHC-28",
                          frenchLayout, @"MSX - Philips VG-8010F",
                          frenchLayout, @"MSX - Philips VG-8020F",
                          frenchLayout, @"MSX - Sanyo PHC-28L",
                          frenchLayout, @"MSX - Toshiba HX-10F",
                          frenchLayout, @"MSX - Yeno DPC-64",
                          frenchLayout, @"MSX - Yeno MX64",
                          frenchLayout, @"MSX2 - Philips NMS-8245F",
                          frenchLayout, @"MSX2 - Philips NMS-8250F",
                          frenchLayout, @"MSX2 - Philips NMS-8255F",
                          frenchLayout, @"MSX2 - Philips NMS-8280F",
                          frenchLayout, @"MSX2 - Philips VG-8235F",
                          frenchLayout, @"MSX2 - Sony HB-F500F",
                          frenchLayout, @"MSX2 - Sony HB-F700F",
                          frenchLayout, @"MSX2+ - French",
                          
                          germanLayout, @"MSX - Canon V-20G",
                          germanLayout, @"MSX - Panasonic CF-2700G",
                          germanLayout, @"MSX - Sanyo MPC-64",
                          germanLayout, @"MSX - Sony HB-55D",
                          germanLayout, @"MSX - Sony HB-75D",
                          germanLayout, @"MSX2 - Philips NMS-8280G",
                          germanLayout, @"MSX2 - Sony HB-F700D",
                          
                          japaneseLayout, @"MSX - Canon V-8",
                          japaneseLayout, @"MSX - Canon V-10",
                          japaneseLayout, @"MSX - Canon V-20",
                          japaneseLayout, @"MSX - Casio PV-7",
                          japaneseLayout, @"MSX - Casio PV-16",
                          japaneseLayout, @"MSX - Fujitsu FM-X",
                          japaneseLayout, @"MSX - Mitsubishi ML-F110",
                          japaneseLayout, @"MSX - Mitsubishi ML-F120",
                          japaneseLayout, @"MSX - National CF-1200",
                          japaneseLayout, @"MSX - National CF-2000",
                          japaneseLayout, @"MSX - National CF-2700",
                          japaneseLayout, @"MSX - National CF-3000",
                          japaneseLayout, @"MSX - National CF-3300",
                          japaneseLayout, @"MSX - National FS-1300",
                          japaneseLayout, @"MSX - National FS-4000",
                          japaneseLayout, @"MSX - Pioneer PX-7",
                          japaneseLayout, @"MSX - Pioneer PX-V60",
                          japaneseLayout, @"MSX - Sony HB-10",
                          japaneseLayout, @"MSX - Sony HB-201",
                          japaneseLayout, @"MSX - Sony HB-501",
                          japaneseLayout, @"MSX - Sony HB-701FD",
                          japaneseLayout, @"MSX - Toshiba HX-10D",
                          japaneseLayout, @"MSX - Toshiba HX-10S",
                          japaneseLayout, @"MSX - Toshiba HX-20",
                          japaneseLayout, @"MSX - Toshiba HX-21",
                          japaneseLayout, @"MSX - Toshiba HX-22",
                          japaneseLayout, @"MSX - Yamaha CX5F-1",
                          japaneseLayout, @"MSX - Yamaha CX5F-2",
                          japaneseLayout, @"MSX2 - Canon V-25",
                          japaneseLayout, @"MSX2 - Canon V-30",
                          japaneseLayout, @"MSX2 - Canon V-30F",
                          japaneseLayout, @"MSX2 - Kawai KMC-5000",
                          japaneseLayout, @"MSX2 - Mitsubishi ML-G10",
                          japaneseLayout, @"MSX2 - Mitsubishi ML-G30 Model 1",
                          japaneseLayout, @"MSX2 - Mitsubishi ML-G30 Model 2",
                          japaneseLayout, @"MSX2 - National FS-4500",
                          japaneseLayout, @"MSX2 - National FS-4600",
                          japaneseLayout, @"MSX2 - National FS-4700",
                          japaneseLayout, @"MSX2 - National FS-5000",
                          japaneseLayout, @"MSX2 - National FS-5500F1",
                          japaneseLayout, @"MSX2 - National FS-5500F2",
                          japaneseLayout, @"MSX2 - Panasonic FS-A1",
                          japaneseLayout, @"MSX2 - Panasonic FS-A1F",
                          japaneseLayout, @"MSX2 - Panasonic FS-A1FM",
                          japaneseLayout, @"MSX2 - Panasonic FS-A1MK2",
                          japaneseLayout, @"MSX2 - Philips NMS-8250J",
                          japaneseLayout, @"MSX2 - Philips VG-8230J",
                          japaneseLayout, @"MSX2 - Sanyo Wavy MPC-25FD",
                          japaneseLayout, @"MSX2 - Sanyo Wavy MPC-27",
                          japaneseLayout, @"MSX2 - Sanyo Wavy PHC-23",
                          japaneseLayout, @"MSX2 - Sanyo Wavy PHC-55FD2",
                          japaneseLayout, @"MSX2 - Sanyo Wavy PHC-77",
                          japaneseLayout, @"MSX2 - Sony HB-F1",
                          japaneseLayout, @"MSX2 - Sony HB-F1II",
                          japaneseLayout, @"MSX2 - Sony HB-F1XD",
                          japaneseLayout, @"MSX2 - Sony HB-F1XDMK2",
                          japaneseLayout, @"MSX2 - Sony HB-F5",
                          japaneseLayout, @"MSX2 - Sony HB-F500",
                          japaneseLayout, @"MSX2 - Sony HB-F750+",
                          japaneseLayout, @"MSX2 - Sony HB-F900",
                          japaneseLayout, @"MSX2 - Toshiba HX-23",
                          japaneseLayout, @"MSX2 - Toshiba HX-23F",
                          japaneseLayout, @"MSX2 - Toshiba HX-33",
                          japaneseLayout, @"MSX2 - Toshiba HX-34",
                          japaneseLayout, @"MSX2 - Victor HC-90",
                          japaneseLayout, @"MSX2 - Victor HC-95",
                          japaneseLayout, @"MSX2 - Victor HC-95A",
                          japaneseLayout, @"MSX2 - Yamaha CX7_128",
                          japaneseLayout, @"MSX2 - Yamaha CX7M_128",
                          japaneseLayout, @"MSX2+ - MSXPLAYer 2003",
                          japaneseLayout, @"MSX2+ - Panasonic FS-A1FX",
                          japaneseLayout, @"MSX2+ - Panasonic FS-A1WSX",
                          japaneseLayout, @"MSX2+ - Panasonic FS-A1WX",
                          japaneseLayout, @"MSX2+ - Sanyo Wavy PHC-35J",
                          japaneseLayout, @"MSX2+ - Sanyo Wavy PHC-70FD1",
                          japaneseLayout, @"MSX2+ - Sanyo Wavy PHC-70FD2",
                          japaneseLayout, @"MSX2+ - Sony HB-F1XDJ",
                          japaneseLayout, @"MSX2+ - Sony HB-F1XV",
                          japaneseLayout, @"MSXturboR - Panasonic FS-A1GT",
                          japaneseLayout, @"MSXturboR - Panasonic FS-A1ST",
                          
                          koreanLayout, @"MSX - Daewoo DPC-100",
                          koreanLayout, @"MSX - Daewoo DPC-180",
                          koreanLayout, @"MSX - Daewoo DPC-200",
                          koreanLayout, @"MSX - Daewoo Zemmix CPC-50",
                          koreanLayout, @"MSX - Daewoo Zemmix CPC-51",
                          koreanLayout, @"MSX - Samsung SPC-800",
                          koreanLayout, @"MSX2 - Daewoo CPC-300",
                          koreanLayout, @"MSX2 - Daewoo CPC-300E",
                          koreanLayout, @"MSX2 - Daewoo CPC-330K",
                          koreanLayout, @"MSX2 - Daewoo CPC-400",
                          koreanLayout, @"MSX2 - Daewoo CPC-400S",
                          koreanLayout, @"MSX2 - Daewoo Zemmix CPC-61",
                          koreanLayout, @"MSX2 - Daewoo Zemmix CPG-120",
                          
                          russianLayout, @"MSX - Yamaha YIS503IIR",
                          russianLayout, @"MSX2 - Sanyo MPC-2300",
                          russianLayout, @"MSX2 - Sony HB-F9P Russian",
                          russianLayout, @"MSX2 - Yamaha YIS503IIIR",
                          russianLayout, @"MSX2 - Yamaha YIS805-128R2",
                          
                          spanishLayout, @"MSX - Canon V-20S",
                          spanishLayout, @"MSX - Sony HB-20P",
                          spanishLayout, @"MSX - Talent DPC-200",
                          spanishLayout, @"MSX - Talent DPC-200A",
                          spanishLayout, @"MSX - Toshiba HX-10SA",
                          spanishLayout, @"MSX2 - Mitsubishi ML-G1",
                          spanishLayout, @"MSX2 - Mitsubishi ML-G3",
                          spanishLayout, @"MSX2 - Sony HB-F9S",
                          spanishLayout, @"MSX2 - Sony HB-F700S",
                          spanishLayout, @"MSX2 - Spectravideo SVI-738-2 LC Grosso",
                          spanishLayout, @"MSX2 - Talent TPC-310",
                          spanishLayout, @"MSX2 - Talent TPP-311",
                          spanishLayout, @"MSX2 - Talent TPS-312",
                          spanishLayout, @"MSX2+ - Sony HB-F9S+",
                          
                          swedishLayout, @"MSX - Spectravideo SVI-738 Swedish",
                          swedishLayout, @"MSX - Spectravideo SVI-838",
                          swedishLayout, @"MSX2 - Spectravideo SVI-838-2",
                          
                          nil];
}

- (id)init
{
    if ((self = [super init]))
    {
        virtualCodeToKeyInfoMap = [[NSMutableDictionary alloc] init];
        characterToVirtualCodeMap = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [virtualCodeToKeyInfoMap release];
    [characterToVirtualCodeMap release];
    
    [super dealloc];
}

+ (CMMSXKeyboardLayout)layoutOfMachineWithIdentifier:(NSString *)machineId
{
    NSNumber *layoutId = [machineToLayoutMap objectForKey:machineId];
    if (!layoutId)
        return CMMSXKeyboardUnknown;
    
    return [layoutId integerValue];
}

- (CMTypewriterKey *)mapTypewriterKeyWithCode:(NSInteger)virtualCode
                             defaultStateChar:(NSString *)defaultStateChar
                             shiftedStateChar:(NSString *)shiftedStateChar
{
    CMTypewriterKey *key = [[[CMTypewriterKey alloc] init] autorelease];
    
    [key setVirtualCode:virtualCode];
    [key setDefaultStateChar:defaultStateChar];
    [key setShiftedStateChar:shiftedStateChar];
    
    [virtualCodeToKeyInfoMap setObject:key forKey:@(virtualCode)];
    
    if (defaultStateChar)
        [characterToVirtualCodeMap setObject:key forKey:defaultStateChar];
    if (shiftedStateChar && ![shiftedStateChar isEqual:defaultStateChar])
        [characterToVirtualCodeMap setObject:key forKey:shiftedStateChar];
    
    return key;
}

- (CMTypewriterKey *)mapTypewriterKeyWithCode:(NSInteger)virtualCode
                                 anyStateChar:(NSString *)anyStateChar
                                        label:(NSString *)label
{
    CMTypewriterKey *key = [self mapTypewriterKeyWithCode:virtualCode
                                         defaultStateChar:anyStateChar
                                         shiftedStateChar:anyStateChar];
    
    [key setLabel:label];
    
    return key;
}

- (CMKeyboardKey *)mapKeyWithCode:(NSInteger)virtualCode
                            label:(NSString *)label
{
    CMKeyboardKey *key = [[[CMKeyboardKey alloc] init] autorelease];
    
    [key setVirtualCode:virtualCode];
    [key setLabel:label];
    
    [virtualCodeToKeyInfoMap setObject:key forKey:@(virtualCode)];
    
    return key;
}

- (void)unmapVirtualCode:(NSInteger)virtualCode
{
    CMKeyboardKey *key = [virtualCodeToKeyInfoMap objectForKey:@(virtualCode)];
    if (key)
    {
        if ([key isKindOfClass:[CMTypewriterKey class]])
        {
            CMTypewriterKey *typewriterKey = (CMTypewriterKey *)key;
            
            if ([typewriterKey defaultStateChar])
                [characterToVirtualCodeMap removeObjectForKey:[typewriterKey defaultStateChar]];
            if ([typewriterKey shiftedStateChar])
                [characterToVirtualCodeMap removeObjectForKey:[typewriterKey shiftedStateChar]];
        }
        
        [virtualCodeToKeyInfoMap removeObjectForKey:@(virtualCode)];
    }
}

- (NSString *)presentationLabelForVirtualCode:(NSInteger)keyCode
                                     keyState:(CMMSXKeyState)keyState
{
    CMKeyboardKey *key = [virtualCodeToKeyInfoMap objectForKey:@(keyCode)];
    return [key presentationLabelForState:keyState];
}

- (CMMSXKeyCombination *)keyCombinationForCharacter:(NSString *)character
{
    CMTypewriterKey *typewriterKey = [characterToVirtualCodeMap objectForKey:character];
    
    if (typewriterKey)
    {
        if ([character isEqual:[typewriterKey defaultStateChar]])
            return [CMMSXKeyCombination combinationWithVirtualCode:[typewriterKey virtualCode]
                                                        stateFlags:CMMSXKeyStateDefault];
        else if ([character isEqual:[typewriterKey shiftedStateChar]])
            return [CMMSXKeyCombination combinationWithVirtualCode:[typewriterKey virtualCode]
                                                        stateFlags:CMMSXKeyStateShift];
    }
    
    return nil;
}

- (NSInteger)virtualCodeForCharacter:(NSString *)character
{
    CMTypewriterKey *typewriterKey = [characterToVirtualCodeMap objectForKey:character];
    if (!typewriterKey)
        return EC_NONE;
    
    return [typewriterKey virtualCode];
}

+ (CMMSXKeyboard *)keyboardWithLayout:(CMMSXKeyboardLayout)layout
{
    return [layoutToKeyboardMap objectForKey:@(layout)];
}

+ (CMMSXKeyboard *)commonKeyboard
{
    CMMSXKeyboard *layout = [[self alloc] init];
    
    [layout mapTypewriterKeyWithCode:EC_SPACE  anyStateChar:@" "  label:CMLoc(@"KeySpace")];
    [layout mapTypewriterKeyWithCode:EC_RETURN anyStateChar:@"\n" label:CMLoc(@"KeyReturn")];
    [layout mapTypewriterKeyWithCode:EC_TAB    anyStateChar:@"\t" label:CMLoc(@"KeyTab")];
    
    [layout mapKeyWithCode:EC_F1 label:@"F1"];
    [layout mapKeyWithCode:EC_F2 label:@"F2"];
    [layout mapKeyWithCode:EC_F3 label:@"F3"];
    [layout mapKeyWithCode:EC_F4 label:@"F4"];
    [layout mapKeyWithCode:EC_F5 label:@"F5"];
    
    [layout mapKeyWithCode:EC_ESC     label:@"KeyEscape"];
    [layout mapKeyWithCode:EC_STOP    label:@"KeyStop"];
    [layout mapKeyWithCode:EC_CLS     label:@"KeyCls"];
    [layout mapKeyWithCode:EC_SELECT  label:@"KeySelect"];
    [layout mapKeyWithCode:EC_INS     label:@"KeyInsert"];
    [layout mapKeyWithCode:EC_DEL     label:@"KeyDelete"];
    [layout mapKeyWithCode:EC_BKSPACE label:@"KeyBackspace"];
    [layout mapKeyWithCode:EC_PRINT   label:@"KeyPrint"];
    [layout mapKeyWithCode:EC_PAUSE   label:@"KeyPause"];
    
    [layout mapKeyWithCode:EC_LEFT  label:@"KeyCursorLeft"];
    [layout mapKeyWithCode:EC_UP    label:@"KeyCursorUp"];
    [layout mapKeyWithCode:EC_RIGHT label:@"KeyCursorRight"];
    [layout mapKeyWithCode:EC_DOWN  label:@"KeyCursorDown"];
    
    [layout mapTypewriterKeyWithCode:EC_NUMMUL anyStateChar:@"*" label:@"*"];
    [layout mapTypewriterKeyWithCode:EC_NUMADD anyStateChar:@"+" label:@"+"];
    [layout mapTypewriterKeyWithCode:EC_NUMDIV anyStateChar:@"/" label:@"/"];
    [layout mapTypewriterKeyWithCode:EC_NUMSUB anyStateChar:@"-" label:@"-"];
    [layout mapTypewriterKeyWithCode:EC_NUMPER anyStateChar:@"." label:@"."];
    [layout mapTypewriterKeyWithCode:EC_NUMCOM anyStateChar:@"," label:@","];
    [layout mapTypewriterKeyWithCode:EC_NUM0   anyStateChar:@"0" label:@"0"];
    [layout mapTypewriterKeyWithCode:EC_NUM1   anyStateChar:@"1" label:@"1"];
    [layout mapTypewriterKeyWithCode:EC_NUM2   anyStateChar:@"2" label:@"2"];
    [layout mapTypewriterKeyWithCode:EC_NUM3   anyStateChar:@"3" label:@"3"];
    [layout mapTypewriterKeyWithCode:EC_NUM4   anyStateChar:@"4" label:@"4"];
    [layout mapTypewriterKeyWithCode:EC_NUM5   anyStateChar:@"5" label:@"5"];
    [layout mapTypewriterKeyWithCode:EC_NUM6   anyStateChar:@"6" label:@"6"];
    [layout mapTypewriterKeyWithCode:EC_NUM7   anyStateChar:@"7" label:@"7"];
    [layout mapTypewriterKeyWithCode:EC_NUM8   anyStateChar:@"8" label:@"8"];
    [layout mapTypewriterKeyWithCode:EC_NUM9   anyStateChar:@"9" label:@"9"];
    
    [layout mapKeyWithCode:EC_LSHIFT label:@"KeyLeftShift"];
    [layout mapKeyWithCode:EC_RSHIFT label:@"KeyRightShift"];
    [layout mapKeyWithCode:EC_CTRL   label:@"KeyCtrl"];
    [layout mapKeyWithCode:EC_GRAPH  label:@"KeyGraph"];
    [layout mapKeyWithCode:EC_CODE   label:@"KeyCode"];
    [layout mapKeyWithCode:EC_CAPS   label:@"KeyCapsLock"];
    
    return [layout autorelease];
}

+ (CMMSXKeyboard *)europeanKeyboard
{
    CMMSXKeyboard *layout = [self commonKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@"`" shiftedStateChar:@"~"];
    [layout mapTypewriterKeyWithCode:EC_1       defaultStateChar:@"1" shiftedStateChar:@"!"];
    [layout mapTypewriterKeyWithCode:EC_2       defaultStateChar:@"2" shiftedStateChar:@"@"];
    [layout mapTypewriterKeyWithCode:EC_3       defaultStateChar:@"3" shiftedStateChar:@"#"];
    [layout mapTypewriterKeyWithCode:EC_4       defaultStateChar:@"4" shiftedStateChar:@"$"];
    [layout mapTypewriterKeyWithCode:EC_5       defaultStateChar:@"5" shiftedStateChar:@"%"];
    [layout mapTypewriterKeyWithCode:EC_6       defaultStateChar:@"6" shiftedStateChar:@"^"];
    [layout mapTypewriterKeyWithCode:EC_7       defaultStateChar:@"7" shiftedStateChar:@"&"];
    [layout mapTypewriterKeyWithCode:EC_8       defaultStateChar:@"8" shiftedStateChar:@"*"];
    [layout mapTypewriterKeyWithCode:EC_9       defaultStateChar:@"9" shiftedStateChar:@"("];
    [layout mapTypewriterKeyWithCode:EC_0       defaultStateChar:@"0" shiftedStateChar:@")"];
    [layout mapTypewriterKeyWithCode:EC_NEG     defaultStateChar:@"-" shiftedStateChar:@"_"];
    [layout mapTypewriterKeyWithCode:EC_CIRCFLX defaultStateChar:@"=" shiftedStateChar:@"+"];
    
    [layout mapTypewriterKeyWithCode:EC_Q      defaultStateChar:@"q" shiftedStateChar:@"Q"];
    [layout mapTypewriterKeyWithCode:EC_W      defaultStateChar:@"w" shiftedStateChar:@"W"];
    [layout mapTypewriterKeyWithCode:EC_E      defaultStateChar:@"e" shiftedStateChar:@"E"];
    [layout mapTypewriterKeyWithCode:EC_R      defaultStateChar:@"r" shiftedStateChar:@"R"];
    [layout mapTypewriterKeyWithCode:EC_T      defaultStateChar:@"t" shiftedStateChar:@"T"];
    [layout mapTypewriterKeyWithCode:EC_Y      defaultStateChar:@"y" shiftedStateChar:@"Y"];
    [layout mapTypewriterKeyWithCode:EC_U      defaultStateChar:@"u" shiftedStateChar:@"U"];
    [layout mapTypewriterKeyWithCode:EC_I      defaultStateChar:@"i" shiftedStateChar:@"I"];
    [layout mapTypewriterKeyWithCode:EC_O      defaultStateChar:@"o" shiftedStateChar:@"O"];
    [layout mapTypewriterKeyWithCode:EC_P      defaultStateChar:@"p" shiftedStateChar:@"P"];
    [layout mapTypewriterKeyWithCode:EC_AT     defaultStateChar:@"[" shiftedStateChar:@"{"];
    [layout mapTypewriterKeyWithCode:EC_LBRACK defaultStateChar:@"]" shiftedStateChar:@"}"];
    
    [layout mapTypewriterKeyWithCode:EC_A       defaultStateChar:@"a"  shiftedStateChar:@"A"];
    [layout mapTypewriterKeyWithCode:EC_S       defaultStateChar:@"s"  shiftedStateChar:@"S"];
    [layout mapTypewriterKeyWithCode:EC_D       defaultStateChar:@"d"  shiftedStateChar:@"D"];
    [layout mapTypewriterKeyWithCode:EC_F       defaultStateChar:@"f"  shiftedStateChar:@"F"];
    [layout mapTypewriterKeyWithCode:EC_G       defaultStateChar:@"g"  shiftedStateChar:@"G"];
    [layout mapTypewriterKeyWithCode:EC_H       defaultStateChar:@"h"  shiftedStateChar:@"H"];
    [layout mapTypewriterKeyWithCode:EC_J       defaultStateChar:@"j"  shiftedStateChar:@"J"];
    [layout mapTypewriterKeyWithCode:EC_K       defaultStateChar:@"k"  shiftedStateChar:@"K"];
    [layout mapTypewriterKeyWithCode:EC_L       defaultStateChar:@"l"  shiftedStateChar:@"L"];
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@";"  shiftedStateChar:@":"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@"'"  shiftedStateChar:@"\""];
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"\\" shiftedStateChar:@"|"];
    
    [layout mapTypewriterKeyWithCode:EC_Z       defaultStateChar:@"z" shiftedStateChar:@"Z"];
    [layout mapTypewriterKeyWithCode:EC_X       defaultStateChar:@"x" shiftedStateChar:@"X"];
    [layout mapTypewriterKeyWithCode:EC_C       defaultStateChar:@"c" shiftedStateChar:@"C"];
    [layout mapTypewriterKeyWithCode:EC_V       defaultStateChar:@"v" shiftedStateChar:@"V"];
    [layout mapTypewriterKeyWithCode:EC_B       defaultStateChar:@"b" shiftedStateChar:@"B"];
    [layout mapTypewriterKeyWithCode:EC_N       defaultStateChar:@"n" shiftedStateChar:@"N"];
    [layout mapTypewriterKeyWithCode:EC_M       defaultStateChar:@"m" shiftedStateChar:@"M"];
    [layout mapTypewriterKeyWithCode:EC_COMMA   defaultStateChar:@"," shiftedStateChar:@"<"];
    [layout mapTypewriterKeyWithCode:EC_PERIOD  defaultStateChar:@"." shiftedStateChar:@">"];
    [layout mapTypewriterKeyWithCode:EC_DIV     defaultStateChar:@"/" shiftedStateChar:@"?"];
    [layout mapTypewriterKeyWithCode:EC_UNDSCRE defaultStateChar:@"`" shiftedStateChar:@"'"];
    
    return layout;
}

+ (CMMSXKeyboard *)arabicKeyboard
{
    return [self europeanKeyboard];
}

+ (CMMSXKeyboard *)brazilianKeyboard
{
    // Start with the Euro. layout
    CMMSXKeyboard *layout = [self europeanKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@"ç" shiftedStateChar:@"Ç"];
    [layout mapTypewriterKeyWithCode:EC_2       defaultStateChar:@"2" shiftedStateChar:@"\""];
    [layout mapTypewriterKeyWithCode:EC_8       defaultStateChar:@"8" shiftedStateChar:@"'"];
    
    [layout mapTypewriterKeyWithCode:EC_AT     defaultStateChar:@"'" shiftedStateChar:@"`"];
    [layout mapTypewriterKeyWithCode:EC_LBRACK defaultStateChar:@"[" shiftedStateChar:@"]"];
    
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@"~" shiftedStateChar:@"^"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@"*" shiftedStateChar:@"@"];
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"{" shiftedStateChar:@"}"];
    
    [layout mapTypewriterKeyWithCode:EC_DIV     defaultStateChar:@";" shiftedStateChar:@":"];
    [layout mapTypewriterKeyWithCode:EC_UNDSCRE defaultStateChar:@"/" shiftedStateChar:@"?"];
    
    return layout;
}

+ (CMMSXKeyboard *)estonianKeyboard
{
    // Start with the Euro. layout
    CMMSXKeyboard *layout = [self europeanKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@"^" shiftedStateChar:@"~"];
    [layout mapTypewriterKeyWithCode:EC_2       defaultStateChar:@"2" shiftedStateChar:@"\""];
    [layout mapTypewriterKeyWithCode:EC_6       defaultStateChar:@"6" shiftedStateChar:@"&"];
    [layout mapTypewriterKeyWithCode:EC_7       defaultStateChar:@"7" shiftedStateChar:@"/"];
    [layout mapTypewriterKeyWithCode:EC_8       defaultStateChar:@"8" shiftedStateChar:@"("];
    [layout mapTypewriterKeyWithCode:EC_9       defaultStateChar:@"9" shiftedStateChar:@")"];
    [layout mapTypewriterKeyWithCode:EC_0       defaultStateChar:@"0" shiftedStateChar:@"="];
    [layout mapTypewriterKeyWithCode:EC_NEG     defaultStateChar:@"+" shiftedStateChar:@"?"];
    [layout mapTypewriterKeyWithCode:EC_CIRCFLX defaultStateChar:@"'" shiftedStateChar:@"`"];
    
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@"\\" shiftedStateChar:@"|"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@"<"  shiftedStateChar:@">"];
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"'"  shiftedStateChar:@"*"];
    
    [layout mapTypewriterKeyWithCode:EC_COMMA   defaultStateChar:@"," shiftedStateChar:@";"];
    [layout mapTypewriterKeyWithCode:EC_PERIOD  defaultStateChar:@"." shiftedStateChar:@":"];
    [layout mapTypewriterKeyWithCode:EC_DIV     defaultStateChar:@"-" shiftedStateChar:@"_"];
    
    [layout unmapVirtualCode:EC_UNDSCRE];
    
    return layout;
}

+ (CMMSXKeyboard *)frenchKeyboard
{
    // Start with the Euro. layout
    CMMSXKeyboard *layout = [self europeanKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@"#"  shiftedStateChar:@"£"];
    [layout mapTypewriterKeyWithCode:EC_1       defaultStateChar:@"&"  shiftedStateChar:@"1"];
    [layout mapTypewriterKeyWithCode:EC_2       defaultStateChar:@"é"  shiftedStateChar:@"2"];
    [layout mapTypewriterKeyWithCode:EC_3       defaultStateChar:@"\"" shiftedStateChar:@"3"];
    [layout mapTypewriterKeyWithCode:EC_4       defaultStateChar:@"'"  shiftedStateChar:@"4"];
    [layout mapTypewriterKeyWithCode:EC_5       defaultStateChar:@"("  shiftedStateChar:@"5"];
    [layout mapTypewriterKeyWithCode:EC_6       defaultStateChar:@"§"  shiftedStateChar:@"6"];
    [layout mapTypewriterKeyWithCode:EC_7       defaultStateChar:@"è"  shiftedStateChar:@"7"];
    [layout mapTypewriterKeyWithCode:EC_8       defaultStateChar:@"!"  shiftedStateChar:@"8"];
    [layout mapTypewriterKeyWithCode:EC_9       defaultStateChar:@"ç"  shiftedStateChar:@"9"];
    [layout mapTypewriterKeyWithCode:EC_0       defaultStateChar:@"à"  shiftedStateChar:@"0"];
    [layout mapTypewriterKeyWithCode:EC_NEG     defaultStateChar:@")"  shiftedStateChar:@"º"];
    [layout mapTypewriterKeyWithCode:EC_CIRCFLX defaultStateChar:@"-"  shiftedStateChar:@"_"];
    
    [layout mapTypewriterKeyWithCode:EC_Q      defaultStateChar:@"a" shiftedStateChar:@"A"];
    [layout mapTypewriterKeyWithCode:EC_W      defaultStateChar:@"z" shiftedStateChar:@"Z"];
    [layout mapTypewriterKeyWithCode:EC_AT     defaultStateChar:@"`" shiftedStateChar:@"'"];
    [layout mapTypewriterKeyWithCode:EC_LBRACK defaultStateChar:@"$" shiftedStateChar:@"*"];
    
    [layout mapTypewriterKeyWithCode:EC_A       defaultStateChar:@"q" shiftedStateChar:@"Q"];
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@"m" shiftedStateChar:@"M"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@"ù" shiftedStateChar:@"%"];
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"<" shiftedStateChar:@">"];
    
    [layout mapTypewriterKeyWithCode:EC_Z       defaultStateChar:@"w" shiftedStateChar:@"W"];
    [layout mapTypewriterKeyWithCode:EC_M       defaultStateChar:@"," shiftedStateChar:@"?"];
    [layout mapTypewriterKeyWithCode:EC_COMMA   defaultStateChar:@";" shiftedStateChar:@"."];
    [layout mapTypewriterKeyWithCode:EC_PERIOD  defaultStateChar:@":" shiftedStateChar:@"/"];
    [layout mapTypewriterKeyWithCode:EC_DIV     defaultStateChar:@"=" shiftedStateChar:@"+"];
    
    [layout unmapVirtualCode:EC_UNDSCRE];
    
    return layout;
}

+ (CMMSXKeyboard *)germanKeyboard
{
    // Start with the Euro. layout
    CMMSXKeyboard *layout = [self europeanKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@"#" shiftedStateChar:@"^"];
    [layout mapTypewriterKeyWithCode:EC_2       defaultStateChar:@"2" shiftedStateChar:@"\""];
    [layout mapTypewriterKeyWithCode:EC_3       defaultStateChar:@"3" shiftedStateChar:@"§"];
    [layout mapTypewriterKeyWithCode:EC_6       defaultStateChar:@"6" shiftedStateChar:@"&"];
    [layout mapTypewriterKeyWithCode:EC_7       defaultStateChar:@"7" shiftedStateChar:@"/"];
    [layout mapTypewriterKeyWithCode:EC_8       defaultStateChar:@"8" shiftedStateChar:@"("];
    [layout mapTypewriterKeyWithCode:EC_9       defaultStateChar:@"9" shiftedStateChar:@")"];
    [layout mapTypewriterKeyWithCode:EC_0       defaultStateChar:@"0" shiftedStateChar:@"="];
    [layout mapTypewriterKeyWithCode:EC_NEG     defaultStateChar:@"ß" shiftedStateChar:@"?"];
    [layout mapTypewriterKeyWithCode:EC_CIRCFLX defaultStateChar:@"'" shiftedStateChar:@"`"];
    
    [layout mapTypewriterKeyWithCode:EC_Y      defaultStateChar:@"z" shiftedStateChar:@"Z"];
    [layout mapTypewriterKeyWithCode:EC_AT     defaultStateChar:@"ü" shiftedStateChar:@"Ü"];
    [layout mapTypewriterKeyWithCode:EC_LBRACK defaultStateChar:@"+" shiftedStateChar:@"*"];
    
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@"ö" shiftedStateChar:@"Ö"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@"ä" shiftedStateChar:@"Ä"];
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"<" shiftedStateChar:@">"];
    
    [layout mapTypewriterKeyWithCode:EC_Z       defaultStateChar:@"y" shiftedStateChar:@"Y"];
    [layout mapTypewriterKeyWithCode:EC_COMMA   defaultStateChar:@"," shiftedStateChar:@";"];
    [layout mapTypewriterKeyWithCode:EC_PERIOD  defaultStateChar:@"." shiftedStateChar:@":"];
    [layout mapTypewriterKeyWithCode:EC_DIV     defaultStateChar:@"-" shiftedStateChar:@"_"];
    
    [layout unmapVirtualCode:EC_UNDSCRE];
    
    return layout;
}

+ (CMMSXKeyboard *)japaneseKeyboard
{
    // Start with the Euro. layout
    CMMSXKeyboard *layout = [self europeanKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@"]" shiftedStateChar:@"}"];
    [layout mapTypewriterKeyWithCode:EC_2       defaultStateChar:@"2" shiftedStateChar:@"\""];
    [layout mapTypewriterKeyWithCode:EC_6       defaultStateChar:@"6" shiftedStateChar:@"&"];
    [layout mapTypewriterKeyWithCode:EC_7       defaultStateChar:@"7" shiftedStateChar:@"'"];
    [layout mapTypewriterKeyWithCode:EC_8       defaultStateChar:@"8" shiftedStateChar:@"("];
    [layout mapTypewriterKeyWithCode:EC_9       defaultStateChar:@"9" shiftedStateChar:@")"];
    [layout mapTypewriterKeyWithCode:EC_0       defaultStateChar:@"0" shiftedStateChar:nil];
    [layout mapTypewriterKeyWithCode:EC_NEG     defaultStateChar:@"-" shiftedStateChar:@"="];
    [layout mapTypewriterKeyWithCode:EC_CIRCFLX defaultStateChar:@"^" shiftedStateChar:@"~"];
    
    [layout mapTypewriterKeyWithCode:EC_AT     defaultStateChar:@"@" shiftedStateChar:@"`"];
    [layout mapTypewriterKeyWithCode:EC_LBRACK defaultStateChar:@"[" shiftedStateChar:@"{"];
    
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@";" shiftedStateChar:@"+"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@":" shiftedStateChar:@"*"];
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"¥" shiftedStateChar:@"|"];
    
    [layout mapTypewriterKeyWithCode:EC_COMMA   defaultStateChar:@"," shiftedStateChar:@"<"];
    [layout mapTypewriterKeyWithCode:EC_PERIOD  defaultStateChar:@"." shiftedStateChar:@">"];
    [layout mapTypewriterKeyWithCode:EC_DIV     defaultStateChar:@"/" shiftedStateChar:@"?"];
    [layout mapTypewriterKeyWithCode:EC_UNDSCRE defaultStateChar:nil  shiftedStateChar:@"_"];
    
    [layout mapKeyWithCode:EC_TORIKE label:@"KeyTorike"];
    [layout mapKeyWithCode:EC_JIKKOU label:@"KeyJikkou"];
    
    return layout;
}

+ (CMMSXKeyboard *)koreanKeyboard
{
    // Start with the Japanese layout
    CMMSXKeyboard *layout = [self japaneseKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"￦" shiftedStateChar:@"|"];
    
    [layout unmapVirtualCode:EC_TORIKE];
    [layout unmapVirtualCode:EC_JIKKOU];
    
    return layout;
}

+ (CMMSXKeyboard *)russianKeyboard
{
    CMMSXKeyboard *layout = [self commonKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@">"  shiftedStateChar:@"~"];
    [layout mapTypewriterKeyWithCode:EC_1       defaultStateChar:@"+"  shiftedStateChar:@"!"];
    [layout mapTypewriterKeyWithCode:EC_2       defaultStateChar:@"!"  shiftedStateChar:@"1"];
    [layout mapTypewriterKeyWithCode:EC_3       defaultStateChar:@"\"" shiftedStateChar:@"2"];
    [layout mapTypewriterKeyWithCode:EC_4       defaultStateChar:@"#"  shiftedStateChar:@"3"];
    [layout mapTypewriterKeyWithCode:EC_5       defaultStateChar:@"Ȣ"  shiftedStateChar:@"4"];
    [layout mapTypewriterKeyWithCode:EC_6       defaultStateChar:@"%"  shiftedStateChar:@"5"];
    [layout mapTypewriterKeyWithCode:EC_7       defaultStateChar:@"&"  shiftedStateChar:@"6"];
    [layout mapTypewriterKeyWithCode:EC_8       defaultStateChar:@"'"  shiftedStateChar:@"7"];
    [layout mapTypewriterKeyWithCode:EC_9       defaultStateChar:@"("  shiftedStateChar:@"8"];
    [layout mapTypewriterKeyWithCode:EC_0       defaultStateChar:@")"  shiftedStateChar:@"9"];
    [layout mapTypewriterKeyWithCode:EC_NEG     defaultStateChar:@"$"  shiftedStateChar:@"0"];
    [layout mapTypewriterKeyWithCode:EC_CIRCFLX defaultStateChar:@"="  shiftedStateChar:@"_"];
    
    [layout mapTypewriterKeyWithCode:EC_Q      defaultStateChar:@"j" shiftedStateChar:@"J"];
    [layout mapTypewriterKeyWithCode:EC_W      defaultStateChar:@"c" shiftedStateChar:@"C"];
    [layout mapTypewriterKeyWithCode:EC_E      defaultStateChar:@"u" shiftedStateChar:@"U"];
    [layout mapTypewriterKeyWithCode:EC_R      defaultStateChar:@"k" shiftedStateChar:@"K"];
    [layout mapTypewriterKeyWithCode:EC_T      defaultStateChar:@"e" shiftedStateChar:@"E"];
    [layout mapTypewriterKeyWithCode:EC_Y      defaultStateChar:@"n" shiftedStateChar:@"N"];
    [layout mapTypewriterKeyWithCode:EC_U      defaultStateChar:@"g" shiftedStateChar:@"G"];
    [layout mapTypewriterKeyWithCode:EC_I      defaultStateChar:@"[" shiftedStateChar:@"{"];
    [layout mapTypewriterKeyWithCode:EC_O      defaultStateChar:@"]" shiftedStateChar:@"}"];
    [layout mapTypewriterKeyWithCode:EC_P      defaultStateChar:@"z" shiftedStateChar:@"Z"];
    [layout mapTypewriterKeyWithCode:EC_AT     defaultStateChar:@"h" shiftedStateChar:@"H"];
    [layout mapTypewriterKeyWithCode:EC_LBRACK defaultStateChar:@"*" shiftedStateChar:@":"];
    
    [layout mapTypewriterKeyWithCode:EC_A       defaultStateChar:@"f"  shiftedStateChar:@"F"];
    [layout mapTypewriterKeyWithCode:EC_S       defaultStateChar:@"y"  shiftedStateChar:@"Y"];
    [layout mapTypewriterKeyWithCode:EC_D       defaultStateChar:@"w"  shiftedStateChar:@"W"];
    [layout mapTypewriterKeyWithCode:EC_F       defaultStateChar:@"a"  shiftedStateChar:@"A"];
    [layout mapTypewriterKeyWithCode:EC_G       defaultStateChar:@"p"  shiftedStateChar:@"P"];
    [layout mapTypewriterKeyWithCode:EC_H       defaultStateChar:@"r"  shiftedStateChar:@"R"];
    [layout mapTypewriterKeyWithCode:EC_J       defaultStateChar:@"o"  shiftedStateChar:@"O"];
    [layout mapTypewriterKeyWithCode:EC_K       defaultStateChar:@"l"  shiftedStateChar:@"L"];
    [layout mapTypewriterKeyWithCode:EC_L       defaultStateChar:@"d"  shiftedStateChar:@"D"];
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@"v"  shiftedStateChar:@"V"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@"\\" shiftedStateChar:@"\\"];
    [layout mapTypewriterKeyWithCode:EC_BKSLASH defaultStateChar:@"-"  shiftedStateChar:@"^"];
    
    [layout mapTypewriterKeyWithCode:EC_Z       defaultStateChar:@"q" shiftedStateChar:@"Q"];
    [layout mapTypewriterKeyWithCode:EC_X       defaultStateChar:@"|" shiftedStateChar:@"~"];
    [layout mapTypewriterKeyWithCode:EC_C       defaultStateChar:@"s" shiftedStateChar:@"S"];
    [layout mapTypewriterKeyWithCode:EC_V       defaultStateChar:@"m" shiftedStateChar:@"M"];
    [layout mapTypewriterKeyWithCode:EC_B       defaultStateChar:@"i" shiftedStateChar:@"I"];
    [layout mapTypewriterKeyWithCode:EC_N       defaultStateChar:@"t" shiftedStateChar:@"T"];
    [layout mapTypewriterKeyWithCode:EC_M       defaultStateChar:@"x" shiftedStateChar:@"X"];
    [layout mapTypewriterKeyWithCode:EC_COMMA   defaultStateChar:@"b" shiftedStateChar:@"B"];
    [layout mapTypewriterKeyWithCode:EC_PERIOD  defaultStateChar:@"@" shiftedStateChar:nil];
    [layout mapTypewriterKeyWithCode:EC_DIV     defaultStateChar:@"<" shiftedStateChar:@","];
    [layout mapTypewriterKeyWithCode:EC_UNDSCRE defaultStateChar:@"?" shiftedStateChar:@"/"];
    
    return layout;
}

+ (CMMSXKeyboard *)spanishKeyboard
{
    // Start with the Euro. layout
    CMMSXKeyboard *layout = [self europeanKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@";" shiftedStateChar:@":"];
    
    [layout mapTypewriterKeyWithCode:EC_SEMICOL defaultStateChar:@"ñ" shiftedStateChar:@"Ñ"];
    [layout mapTypewriterKeyWithCode:EC_COLON   defaultStateChar:@"'" shiftedStateChar:@"~"];
    
    return layout;
}

+ (CMMSXKeyboard *)swedishKeyboard
{
    // Start with the German layout
    CMMSXKeyboard *layout = [self germanKeyboard];
    
    [layout mapTypewriterKeyWithCode:EC_RBRACK  defaultStateChar:@"'" shiftedStateChar:@"*"];
    [layout mapTypewriterKeyWithCode:EC_3       defaultStateChar:@"3" shiftedStateChar:@"#"];
    [layout mapTypewriterKeyWithCode:EC_NEG     defaultStateChar:@"+" shiftedStateChar:@"?"];
    [layout mapTypewriterKeyWithCode:EC_CIRCFLX defaultStateChar:@"é" shiftedStateChar:@"É"];
    
    [layout mapTypewriterKeyWithCode:EC_Y      defaultStateChar:@"y" shiftedStateChar:@"Y"];
    [layout mapTypewriterKeyWithCode:EC_AT     defaultStateChar:@"å" shiftedStateChar:@"Å"];
    [layout mapTypewriterKeyWithCode:EC_LBRACK defaultStateChar:@"ü" shiftedStateChar:@"Ü"];
    
    [layout mapTypewriterKeyWithCode:EC_Z       defaultStateChar:@"z" shiftedStateChar:@"Z"];
    [layout mapTypewriterKeyWithCode:EC_UNDSCRE defaultStateChar:@"'" shiftedStateChar:@"`"];
    
    return layout;
}

@end