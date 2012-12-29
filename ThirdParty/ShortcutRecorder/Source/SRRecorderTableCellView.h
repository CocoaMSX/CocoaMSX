//
//  SRRecorderTableCellView.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors to this file:
//      Akop Karapetyan

#import <Cocoa/Cocoa.h>

#import "SRRecorderControl.h"

@interface SRRecorderTableCellView : NSTableCellView

@property (nonatomic, assign) IBOutlet SRRecorderControl *recorderControl;

@end
