//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2011 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"

#include <IOKit/hidsystem/IOLLEvent.h>

//#define SRCommon_PotentiallyUsefulDebugInfo

#ifdef	SRCommon_PotentiallyUsefulDebugInfo
#warning 64BIT: Check formatting arguments
#define PUDNSLog(X,...)	NSLog(X,##__VA_ARGS__)
#else
#define PUDNSLog(X,...)	{ ; }
#endif

#pragma mark -
#pragma mark dummy class 

@implementation SRDummyClass @end

#pragma mark -

//---------------------------------------------------------- 
// SRStringForKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForKeyCode(NSInteger keyCode)
{
    static SRKeyCodeTransformer *keyCodeTransformer = nil;
    if ( !keyCodeTransformer )
        keyCodeTransformer = [[SRKeyCodeTransformer alloc] init];
    return [keyCodeTransformer transformedValue:[NSNumber numberWithShort:keyCode]];
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlags( NSUInteger flags )
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		( flags & controlKey ? [NSString stringWithFormat:@"%C", KeyboardControlGlyph] : @"" ),
		( flags & optionKey ? [NSString stringWithFormat:@"%C", KeyboardOptionGlyph] : @"" ),
		( flags & shiftKey ? [NSString stringWithFormat:@"%C", KeyboardShiftGlyph] : @"" ),
		( flags & cmdKey ? [NSString stringWithFormat:@"%C", KeyboardCommandGlyph] : @"" )];
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCarbonModifierFlags( flags ), 
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlags( NSUInteger flags )
{
    if ((flags & SRLeftShiftMask) == SRLeftShiftMask)
        return [NSString stringWithFormat:SRLoc(@"Left %C"), KeyboardShiftGlyph];
    if ((flags & SRRightShiftMask) == SRRightShiftMask)
        return [NSString stringWithFormat:SRLoc(@"Right %C"), KeyboardShiftGlyph];
    if ((flags & SRLeftControlKeyMask) == SRLeftControlKeyMask)
        return [NSString stringWithFormat:SRLoc(@"Left %C"), KeyboardControlGlyph];
    if ((flags & SRRightControlKeyMask) == SRRightControlKeyMask)
        return [NSString stringWithFormat:SRLoc(@"Right %C"), KeyboardControlGlyph];
    if ((flags & SRLeftAlternateMask) == SRLeftAlternateMask)
        return [NSString stringWithFormat:SRLoc(@"Left %C"), KeyboardOptionGlyph];
    if ((flags & SRRightAlternateMask) == SRRightAlternateMask)
        return [NSString stringWithFormat:SRLoc(@"Right %C"), KeyboardOptionGlyph];
    if ((flags & SRLeftCommandMask) == SRLeftCommandMask)
        return [NSString stringWithFormat:SRLoc(@"Left %C"), KeyboardCommandGlyph];
    if ((flags & SRRightCommandMask) == SRRightCommandMask)
        return [NSString stringWithFormat:SRLoc(@"Right %C"), KeyboardCommandGlyph];
    
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@%@",
        ( flags & NSAlphaShiftKeyMask ? SRLoc(@"Caps Lock") : @"" ),
        ( flags & NSControlKeyMask ? [NSString stringWithFormat:@"%C", KeyboardControlGlyph] : @"" ),
		( flags & NSAlternateKeyMask ? [NSString stringWithFormat:@"%C", KeyboardOptionGlyph] : @"" ),
		( flags & NSShiftKeyMask ? [NSString stringWithFormat:@"%C", KeyboardShiftGlyph] : @"" ),
		( flags & NSCommandKeyMask ? [NSString stringWithFormat:@"%C", KeyboardCommandGlyph] : @"" )];
	
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCocoaModifierFlags( flags ),
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRReadableStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCarbonModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		( flags & cmdKey ? SRLoc(@"Command + ") : @""),
		( flags & optionKey ? SRLoc(@"Option + ") : @""),
		( flags & controlKey ? SRLoc(@"Control + ") : @""),
		( flags & shiftKey ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;    
}

//---------------------------------------------------------- 
// SRReadableStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCocoaModifierFlagsAndKeyCode( NSUInteger flags, NSInteger keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		(flags & NSCommandKeyMask ? SRLoc(@"Command + ") : @""),
		(flags & NSAlternateKeyMask ? SRLoc(@"Option + ") : @""),
		(flags & NSControlKeyMask ? SRLoc(@"Control + ") : @""),
		(flags & NSShiftKeyMask ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;
}

//---------------------------------------------------------- 
// SRCarbonToCocoaFlags()
//---------------------------------------------------------- 
NSUInteger SRCarbonToCocoaFlags( NSUInteger carbonFlags )
{
	NSUInteger cocoaFlags = ShortcutRecorderEmptyFlags;
	
	if (carbonFlags & cmdKey) cocoaFlags |= NSCommandKeyMask;
	if (carbonFlags & optionKey) cocoaFlags |= NSAlternateKeyMask;
	if (carbonFlags & controlKey) cocoaFlags |= NSControlKeyMask;
	if (carbonFlags & shiftKey) cocoaFlags |= NSShiftKeyMask;
	if (carbonFlags & NSFunctionKeyMask) cocoaFlags += NSFunctionKeyMask;
	
	return cocoaFlags;
}

//---------------------------------------------------------- 
// SRCocoaToCarbonFlags()
//---------------------------------------------------------- 
NSUInteger SRCocoaToCarbonFlags( NSUInteger cocoaFlags )
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	
	if (cocoaFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
	if (cocoaFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
	if (cocoaFlags & NSControlKeyMask) carbonFlags |= controlKey;
	if (cocoaFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
	if (cocoaFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}

//---------------------------------------------------------- 
// SRCharacterForKeyCodeAndCarbonFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCarbonFlags(NSInteger keyCode, NSUInteger carbonFlags) {
	return SRCharacterForKeyCodeAndCocoaFlags(keyCode, SRCarbonToCocoaFlags(carbonFlags));
}

//---------------------------------------------------------- 
// SRCharacterForKeyCodeAndCocoaFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCocoaFlags(NSInteger keyCode, NSUInteger cocoaFlags) {
	
	PUDNSLog(@"SRCharacterForKeyCodeAndCocoaFlags, keyCode: %hi, cocoaFlags: %u",
			 keyCode, cocoaFlags);
	
	// Fall back to string based on key code:
#define	FailWithNaiveString SRStringForKeyCode(keyCode)
	
	UInt32              deadKeyState;
    OSStatus err = noErr;
    CFLocaleRef locale = CFLocaleCopyCurrent();
	[(id)CFMakeCollectable(locale) autorelease]; // Autorelease here so that it gets released no matter what
	
	TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    if(!tisSource)
		return FailWithNaiveString;
	
	CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    if (!layoutData)
		return FailWithNaiveString;
	
	const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    if (!keyLayout)
		return FailWithNaiveString;
	
	EventModifiers modifiers = 0;
	if (cocoaFlags & NSAlternateKeyMask)	modifiers |= optionKey;
	if (cocoaFlags & NSShiftKeyMask)		modifiers |= shiftKey;
	UniCharCount maxStringLength = 4, actualStringLength;
	UniChar unicodeString[4];
	err = UCKeyTranslate( keyLayout, (UInt16)keyCode, kUCKeyActionDisplay, modifiers, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString );
	if(err != noErr)
		return FailWithNaiveString;

	CFStringRef temp = CFStringCreateWithCharacters(kCFAllocatorDefault, unicodeString, 1);
	CFMutableStringRef mutableTemp = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, temp);

	CFStringCapitalize(mutableTemp, locale);

	NSString *resultString = [NSString stringWithString:(NSString *)mutableTemp];

	if (temp) CFRelease(temp);
	if (mutableTemp) CFRelease(mutableTemp);

	PUDNSLog(@"character: -%@-", (NSString *)resultString);

	return resultString;
}

#pragma mark Animation Easing

#define CG_M_PI (CGFloat)M_PI
#define CG_M_PI_2 (CGFloat)M_PI_2

#ifdef __LP64__
#define CGSin(x) sin(x)
#else
#define CGSin(x) sinf(x)
#endif

// From: http://developer.apple.com/samplecode/AnimatedSlider/ as "easeFunction"
CGFloat SRAnimationEaseInOut(CGFloat t) {
	// This function implements a sinusoidal ease-in/ease-out for t = 0 to 1.0.  T is scaled to represent the interval of one full period of the sine function, and transposed to lie above the X axis.
	CGFloat x = (CGSin((t * CG_M_PI) - CG_M_PI_2) + 1.0f ) / 2.0f;
	//	NSLog(@"SRAnimationEaseInOut: %f. a: %f, b: %f, c: %f, d: %f, e: %f", t, (t * M_PI), ((t * M_PI) - M_PI_2), sin((t * M_PI) - M_PI_2), (sin((t * M_PI) - M_PI_2) + 1.0), x);
	return x;
} 


#pragma mark -
#pragma mark additions

@implementation NSAlert( SRAdditions )

//---------------------------------------------------------- 
// + alertWithNonRecoverableError:
//---------------------------------------------------------- 
+ (NSAlert *) alertWithNonRecoverableError:(NSError *)error;
{
	NSString *reason = [error localizedRecoverySuggestion];
    if (!reason)
        reason = @"";
    
	return [self alertWithMessageText:[error localizedDescription]
						defaultButton:[[error localizedRecoveryOptions] objectAtIndex:0U]
					  alternateButton:nil
						  otherButton:nil
			informativeTextWithFormat:reason];
}

@end
