//
//  CMBreakpoints.h
//  CocoaMSX
//
//  Created by Mario Smit on 22/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#ifndef CMBreakpoints_h
#define CMBreakpoints_h


@interface CMBreakpoints : NSObject
{
}
- (bool) setStepOverBreakpoint:(UInt8*)memory withPC:(UInt16)pc;
- (void) setBreakpoint:(UInt16) address;
- (void) clearRunToBreakpoint;
@end

#endif /* CMBreakpoints_h */
