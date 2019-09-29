//
//  CMDisassemble.h
//  CocoaMSX
//
//  Created by Mario Smit on 17/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#ifndef CMDisassemble_h
#define CMDisassemble_h

#import <Foundation/Foundation.h>

@interface CMDisassemble : NSObject
{
    int lineCurrent;
    unsigned long charStart;
    unsigned long charEnd;
}
@property unsigned long charStart;
@property unsigned long charEnd;
@property int lineCurrent;

- (NSMutableAttributedString*) updateContentWithMemory:(UInt8*)memory program_counter:(UInt16)pc;
- (const UInt8*) getMemory;
- (UInt16) getPC;
- (int) dasm:(const UInt8*)memory pc:(UInt16) PC dest:(char*)dest;
@end

#endif /* CMDisassemble_h */
