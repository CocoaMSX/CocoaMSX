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
{
    SRRecorderControl *_recorderControl;
}

@property (nonatomic, assign) SRRecorderControl *recorderControl;

@end
