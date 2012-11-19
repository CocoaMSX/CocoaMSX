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

@property (nonatomic, copy) NSString *label;
@property (nonatomic, assign) NSPoint location;
@property (nonatomic, assign) NSSize size;

@end

@implementation CMMsxKeyDefinition

+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label
                                    location:(NSPoint)location
                                        size:(NSSize)size
{
    CMMsxKeyDefinition *def = [[CMMsxKeyDefinition alloc] init];
    if (def)
    {
        def.label = label;
        def.location = location;
        def.size = size;
    }
    
    return def;
}

+ (CMMsxKeyDefinition *)keyDefinitionLabeled:(NSString *)label
{
    return [CMMsxKeyDefinition keyDefinitionLabeled:label
                                           location:NSZeroPoint
                                               size:NSZeroSize];
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
    
    if (layout == CMMsxKeyboardEuropean)
    {
        definitions = [[NSMutableArray alloc] init];
        
        __block CMMsxKeyDefinition *kd;
        __block NSInteger x;
        NSInteger y;
        NSArray *labels;
        NSArray *keySequence;
        
        // Digits
        
        x = standardLeftMost;
        y = 245;
        labels = [NSArray arrayWithObjects:@"ESC",
                  @"1", @"2", @"3", @"4", @"5", @"6", @"7",
                  @"8", @"9", @"0", @"-", @"=", @"\\", @"BS", nil];
        
        [labels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            kd = [CMMsxKeyDefinition keyDefinitionLabeled:(NSString *)obj
                                                 location:NSMakePoint(x, y)
                                                     size:NSMakeSize(standardWidth, standardHeight)];
            
            x += kd.size.width + standardMargin;
            
            [definitions addObject:kd];
        }];
        
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
        
        button.title = kd.label;
        button.frame = NSMakeRect(kd.location.x, kd.location.y, kd.size.width, kd.size.height);
        
        [button setButtonType:NSMomentaryPushInButton];
        button.bezelStyle = NSThickerSquareBezelStyle;
        button.autoresizesSubviews = YES;
        button.font = [NSFont systemFontOfSize:11];
        
        [self addSubview:button];
    }];
}

@end
