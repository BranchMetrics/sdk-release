//
//  TunePointerSet.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: Lot's of iOS 5 centric logic in this class. Revisit that stuff after Wednesday.
// TODO: Is this class needed if we're not supporting iOS 5??
@interface TunePointerSet : NSObject

// Array like operations that slide or grow contents, including NULLs

- (void)addPointer:(void *)pointer;  // add pointer at index 'count'
- (void)removePointer:(void *)pointer;    // remove pointer
- (void)compact;   // eliminate NULLs
- (void *)pointerAtIndex:(NSUInteger)index;
- (NSUInteger)count;    // the number of elements in the array, including NULLs

- (NSArray *)allObjects; // returns all of the objects referenced by the pointers

//- (BOOL)isIOS5;

@end
