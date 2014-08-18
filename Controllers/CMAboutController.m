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
#import "CMAboutController.h"

@implementation CMWhitePanelView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
}

@end

@implementation CMInvisibleScrollView

- (void)tile
{
    [[self contentView] setFrame:[self bounds]];
    
    [[self verticalScroller] setFrame:NSZeroRect];
}

@end

@interface CMAboutController ()

- (void)startScrollingAnimation;
- (void)stopScrollingAnimation;

- (void)restartScrolling;
- (void)continueScrolling;

- (void)setScrollAmount:(CGFloat)newAmount;
- (void)scrollOneUnit;

@end

@implementation CMAboutController

@synthesize scrollingStartTime = _scrollingStartTime;
@synthesize actualScrollingText = _actualScrollingText;

#define BLANK_LINE_COUNT 16

#define	PRESCROLL_DELAY_SECONDS	4.00	// time before animation starts
#define	SCROLL_DELAY_SECONDS    0.05	// time between animation frames
#define SCROLL_AMOUNT_PIXELS    1.00	// amount to scroll in each animation frame

- (id)init
{
    if ((self = [super initWithWindowNibName:@"About"]))
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewBoundsDidChangeNotification
                                                  object:[textScrollView contentView]];
    
    [self setScrollingStartTime:nil];
    [self setActualScrollingText:nil];
    
    [scrollingTimer release];
    [scrollingTextTemplate release];
    [scrollingTextLeadIn release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AboutContent"
                                                     ofType:@"rtf"
                                                inDirectory:@"Documents"];
    scrollingTextTemplate = [[NSMutableAttributedString alloc] initWithPath:path
                                                         documentAttributes:NULL];
    
    scrollingTextLeadIn = [[NSMutableAttributedString alloc] init];
    
    NSAttributedString *newline = [[[NSAttributedString alloc] initWithString:@"\n"] autorelease];
    for (NSInteger i = 0; i < BLANK_LINE_COUNT; i++)
        [scrollingTextLeadIn appendAttributedString:newline];
    
    [self restartScrolling];
    
    [scrollingTextView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boundsDidChange:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:[textScrollView contentView]];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    versionNumberField.stringValue = [NSString stringWithFormat:CMLoc(@"Version %@", @""),
                                 version];
    
    NSString *appName = [[NSProcessInfo processInfo] processName];
    
    appNameField.stringValue = appName;
}

#pragma mark - Private methods

- (void)scrollOneUnit
{
    if ([[NSDate date] isLessThan:[self scrollingStartTime]])
        return;
    
    float currentScrollAmount = [textScrollView documentVisibleRect].origin.y;
    [self setScrollAmount:(currentScrollAmount + SCROLL_AMOUNT_PIXELS)];
}

- (void)setScrollAmount:(CGFloat)newAmount
{
    isAutoScrolling = YES;
    
    [[textScrollView documentView] scrollPoint:NSMakePoint(0.0, newAmount)];
    
    CGFloat contentHeight = [[textScrollView documentView] bounds].size.height;
    CGFloat contentPosition = newAmount + [textScrollView bounds].size.height;
    
    if (contentPosition >= contentHeight)
        [self continueScrolling];
    
    // Find where the scrollview’s bounds are, then convert to panel’s coordinates
    NSRect scrollViewFrame = [[[self window] contentView] convertRect:[textScrollView bounds]
                                                             fromView:textScrollView];
    
    // Redraw everything which overlaps it.
    [[[self window] contentView] setNeedsDisplayInRect:scrollViewFrame];
    
    isAutoScrolling = NO;
}

- (void)startScrollingAnimation
{
    if (scrollingTimer)
        return;
    
    scrollingTimer = [[NSTimer scheduledTimerWithTimeInterval:SCROLL_DELAY_SECONDS
                                                       target:self
                                                     selector:@selector(scrollOneUnit)
                                                     userInfo:nil
                                                      repeats:YES] retain];
}

- (void)stopScrollingAnimation
{
    [scrollingTimer invalidate];
    [scrollingTimer release];
    
    scrollingTimer = nil;
}

- (void)restartScrolling
{
    [self setActualScrollingText:[[scrollingTextTemplate mutableCopy] autorelease]];
    [[self actualScrollingText] appendAttributedString:scrollingTextLeadIn];
    
    [[scrollingTextView textStorage] setAttributedString:[self actualScrollingText]];
    
    [self setScrollAmount:0];
    [self setScrollingStartTime:[NSDate dateWithTimeInterval:PRESCROLL_DELAY_SECONDS
                                                   sinceDate:[NSDate date]]];
}

- (void)continueScrolling
{
    [self setActualScrollingText:[[scrollingTextLeadIn mutableCopy] autorelease]];
    [[self actualScrollingText] appendAttributedString:scrollingTextTemplate];
    [[self actualScrollingText] appendAttributedString:scrollingTextLeadIn];
    
    [[scrollingTextView textStorage] setAttributedString:[self actualScrollingText]];
    
    [self setScrollAmount:0];
}

#pragma mark - Notifications

- (void)boundsDidChange:(NSNotification *)notification
{
    if (!isAutoScrolling)
        [self setScrollingStartTime:[NSDate dateWithTimeInterval:PRESCROLL_DELAY_SECONDS
                                                       sinceDate:[NSDate date]]];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self startScrollingAnimation];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [self stopScrollingAnimation];
}

#pragma mark - NSWindowController

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    
    [self restartScrolling];
}

#pragma mark - Actions

- (void)showLicense:(id)sender
{
    NSString *documentPath = [[NSBundle mainBundle] pathForResource:@"LICENSE"
                                                             ofType:@""
                                                        inDirectory:@"Documents"];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:documentPath]];
}

- (void)showAuthors:(id)sender
{
    NSString *documentPath = [[NSBundle mainBundle] pathForResource:@"AUTHORS"
                                                             ofType:@""
                                                        inDirectory:@"Documents"];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:documentPath]];
}

@end
