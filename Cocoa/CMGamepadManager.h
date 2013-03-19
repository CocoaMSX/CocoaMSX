//
//  CMGamepadManager.h
//  CocoaMSX
//
//  Created by Akop Karapetyan on 3/18/13.
//  Copyright (c) 2013 Akop Karapetyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>

#import "CMGamepad.h"

@interface CMGamepadManager : NSObject<CMGamepadDelegate>
{
    IOHIDManagerRef hidManager;
    NSMutableDictionary *gamepads;
    
    id _delegate;
}

@property (nonatomic, assign) id delegate;

@end
