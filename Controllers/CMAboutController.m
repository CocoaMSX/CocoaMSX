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
#import "CMAboutController.h"

@implementation CMWhitePanelView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
}

@end

@interface CMAboutController ()

- (void)initializeScrollingText;
- (void)startScrollingAnimation;
- (void)stopScrollingAnimation;

@end

@implementation CMAboutController

@synthesize scrollingStartTime = _scrollingStartTime;

#define BLANK_LINE_COUNT 15

#define	PRESCROLL_DELAY_SECONDS	4.00	// time before animation starts
#define	SCROLL_DELAY_SECONDS	0.05	// time between animation frames
#define SCROLL_AMOUNT_PIXELS	1.00	// amount to scroll in each animation frame

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
    
    [scrollingTimer release];
    [_scrollingStartTime release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    [scrollingTextView setPostsBoundsChangedNotifications:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boundsDidChange:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:[textScrollView contentView]];
    
    [self initializeScrollingText];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    versionNumberField.stringValue = [NSString stringWithFormat:CMLoc(@"VersionAbout"),
                                 version];
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:bundlePath];
    
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

- (void)setScrollAmount:(float)newAmount
{
    isAutoScrolling = YES;
    
    [[textScrollView documentView] scrollPoint:NSMakePoint(0.0, newAmount)];
    
    NSRect scrollViewFrame;
    
    // Find where the scrollview’s bounds are, then convert to panel’s coordinates
    scrollViewFrame = [textScrollView bounds];
    scrollViewFrame = [[[self window] contentView] convertRect:scrollViewFrame
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

- (void)initializeScrollingText
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Documents/AboutContent"
                                                     ofType:@"rtf"];
    NSMutableAttributedString *content = [[[NSMutableAttributedString alloc] initWithPath:path
                                                                       documentAttributes:NULL] autorelease];
    
    NSAttributedString *newline = [[[NSAttributedString alloc] initWithString:@"\n"] autorelease];
    for (NSInteger i = 0; i < BLANK_LINE_COUNT; i++)
        [content appendAttributedString:newline];
    
    [[scrollingTextView textStorage] setAttributedString:content];
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

#pragma mark - Actions

- (void)showLicense:(id)sender
{
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *documentPath = [resourcePath stringByAppendingPathComponent:@"Documents/LICENSE"];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:documentPath]];
}

- (void)showAuthors:(id)sender
{
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *documentPath = [resourcePath stringByAppendingPathComponent:@"Documents/AUTHORS"];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:documentPath]];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    
    [self setScrollAmount:0];
    [self setScrollingStartTime:[NSDate dateWithTimeInterval:PRESCROLL_DELAY_SECONDS
                                                   sinceDate:[NSDate date]]];
}

@end
