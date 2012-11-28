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
#import "CMMsxKeyboardMatrix.h"

#pragma mark - CMMsxKeyDefinition

@interface CMMsxKeyDefinition : NSObject

+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label;
+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label
                                    location:(NSPoint)location
                                        size:(NSSize)size;
+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label
                                    location:(NSPoint)location
                                        size:(NSSize)size
                                    fontSize:(CGFloat)fontSize;

@property (nonatomic, copy) NSString *label;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) NSPoint location;
@property (nonatomic, assign) NSSize size;

@end

@implementation CMMsxKeyDefinition

+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label
                                    location:(NSPoint)location
                                        size:(NSSize)size
                                    fontSize:(CGFloat)fontSize
{
    CMMsxKeyDefinition *def = [[[CMMsxKeyDefinition alloc] init] autorelease];
    if (def)
    {
        def.label = label;
        def.location = location;
        def.size = size;
        def.fontSize = fontSize;
    }
    
    return def;
}

+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label
                                    location:(NSPoint)location
                                        size:(NSSize)size
{
    return [CMMsxKeyDefinition keyDefinitionLabeled:label
                                           location:location
                                               size:size
                                           fontSize:11];
}

+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label
{
    return [CMMsxKeyDefinition keyDefinitionLabeled:label
                                           location:NSZeroPoint
                                               size:NSZeroSize
                                           fontSize:11];
}

- (id)init
{
    if ((self = [super init]))
    {
        self.fontSize = 11;
        self.size = NSZeroSize;
        self.location = NSZeroPoint;
    }
    
    return self;
}

- (void)dealloc
{
    self.label = nil;
    
    [super dealloc];
}

@end

#pragma mark - CMMsxKeyboardMatrix

#define CMMsxKeyboardEuropean 1

@interface CMMsxKeyboardMatrix ()

+ (NSArray *)createKeyDefinitionsForLayout:(NSInteger)layout;
- (void)renderVisualKeyboardLayout:(NSInteger)layout;

@end

@implementation CMMsxKeyboardMatrix

#pragma mark - Initialization, Deallocation

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self renderVisualKeyboardLayout:CMMsxKeyboardEuropean];
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - Custom Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

#pragma mark - Keyboard Layouts

+ (NSArray *)createKeyDefinitionsForLayout:(NSInteger)layout
{
    NSMutableArray *definitions = nil;
    
    const NSInteger standardLeftMost = 18;
    const NSInteger standardWidth = 40;
    const NSInteger standardHeight = 40;
    const NSInteger standardMargin = 4;
    NSInteger rightmostX;
    NSInteger digitsY;
    
    if (layout == CMMsxKeyboardEuropean)
    {
        definitions = [[NSMutableArray alloc] init];
        
        __block CMMsxKeyDefinition *kd;
        __block NSInteger x;
        __block NSInteger y;
        NSArray *keySequence;
        
        // Digits
        
        x = standardLeftMost;
        y = 245;
        digitsY = y;
        
        keySequence = [NSArray arrayWithObjects:
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"ESC"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"1"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"2"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"3"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"4"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"5"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"6"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"7"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"8"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"9"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"0"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"-"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"="],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"\\"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"BS"],
                       nil];
        
        [keySequence enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            kd = obj;
            
            kd.location = NSMakePoint(x, y);
            kd.size = NSMakeSize(standardWidth, standardHeight);
            
            x += kd.size.width + standardMargin;
            
            [definitions addObject:kd];
        }];
        
        rightmostX = x - standardMargin;
        
        // Alpha, first row
        
        x = standardLeftMost;
        y -= standardHeight + standardMargin;
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"TAB"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(55, standardHeight)];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        keySequence = [NSArray arrayWithObjects:
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"Q"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"W"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"E"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"R"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"T"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"Y"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"U"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"I"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"O"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"P"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"["],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"]"],
                       nil];
        
        [keySequence enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            kd = obj;
            
            kd.location = NSMakePoint(x, y);
            kd.size = NSMakeSize(standardWidth, standardHeight);
            
            x += kd.size.width + standardMargin;
            
            [definitions addObject:kd];
        }];
        
        // Alpha, second row
        
        x = standardLeftMost;
        y -= standardHeight + standardMargin;
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"CTRL"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(70, standardHeight)];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        keySequence = [NSArray arrayWithObjects:
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"A"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"S"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"D"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"F"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"G"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"H"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"J"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"K"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"L"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@";"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"'"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"`"],
                       nil];
        
        [keySequence enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            kd = obj;
            
            kd.location = NSMakePoint(x, y);
            kd.size = NSMakeSize(standardWidth, standardHeight);
            
            x += kd.size.width + standardMargin;
            
            [definitions addObject:kd];
        }];
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"RETURN"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(55, 84)];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        // Alpha, third row
        
        x = standardLeftMost;
        y -= standardHeight + standardMargin;
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"SHIFT"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(84, standardHeight)];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        keySequence = [NSArray arrayWithObjects:
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"Z"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"X"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"C"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"V"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"B"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"N"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"M"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@","],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"."],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"/"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@" "],
                       nil];
        
        [keySequence enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            kd = obj;
            
            kd.location = NSMakePoint(x, y);
            kd.size = NSMakeSize(standardWidth, standardHeight);
            
            x += kd.size.width + standardMargin;
            
            [definitions addObject:kd];
        }];
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"SHIFT"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(84, standardHeight)];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        // Spacebar et al.
        
        x = 106;
        y -= standardHeight + standardMargin;
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"CAPS"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(standardWidth, standardHeight)
                                             fontSize:8];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"GRAPH"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(standardWidth, standardHeight)
                                             fontSize:8];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@" " // Spacebar
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(348, standardHeight)];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"CODE"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(standardWidth, standardHeight)
                                             fontSize:8];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
        
        // Numpad
        
        keySequence = [NSArray arrayWithObjects:
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"7"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"8"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"9"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"/"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"4"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"5"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"6"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"*"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"1"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"2"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"3"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"-"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"0"],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"."],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@","],
                       [CMMsxKeyDefinition keyDefinitionLabeled:@"+"],
                       nil];
        
        NSInteger numpadLeft = rightmostX + standardWidth + standardMargin;
        
        [keySequence enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            kd = obj;
            
            x = numpadLeft + (idx % 4) * (standardWidth + standardMargin);
            y = digitsY - (idx / 4) * (standardHeight + standardMargin);
            
            kd.location = NSMakePoint(x, y);
            kd.size = NSMakeSize(standardWidth, standardHeight);
            
            [definitions addObject:kd];
        }];
        
        // Arrows
        
        x = numpadLeft + 24;
        NSInteger lrHeight = standardHeight * 2 + standardMargin;
        
        kd = [CMMsxKeyDefinition keyDefinitionLabeled:@"←"
                                             location:NSMakePoint(x, y)
                                                 size:NSMakeSize(standardWidth, lrHeight)];
        
        x += kd.size.width + standardMargin;
        
        [definitions addObject:kd];
    }
    
    return definitions;
}

- (void)renderVisualKeyboardLayout:(NSInteger)layout
{
    NSArray *keyDefs = [CMMsxKeyboardMatrix createKeyDefinitionsForLayout:layout];
    [keyDefs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CMMsxKeyDefinition *kd = obj;
        
        NSButton *button = [[[NSButton alloc] init] autorelease];
        [button setButtonType:NSMomentaryPushInButton];
        
        button.title = kd.label;
        button.frame = NSMakeRect(kd.location.x, kd.location.y, kd.size.width, kd.size.height);
        
        button.bezelStyle = NSThickerSquareBezelStyle;
        button.autoresizesSubviews = YES;
        button.font = [NSFont systemFontOfSize:kd.fontSize];
        
        [self addSubview:button];
    }];
}

@end
