//
//  TunePointerSet.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePointerSet.h"

@interface  TunePointerSet ()

@property (strong, nonatomic) NSPointerArray *pointers;
//@property (atomic) id __weak *ios5views;
@property (atomic) NSInteger capacity;

@end

@implementation TunePointerSet

#pragma mark - Initialization
- (id)init {
    self = [super init];
    if (self) {
        self.pointers = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsWeakMemory];
//        if ([self isIOS5]) {
//            self.capacity = 0;
//            [self updateIOS5views];
//        }
    }
    return self;
}

#pragma mark - Manage collection
// add pointer at index 'count'
- (void)addPointer:(void *)pointer{
//    if ([self isIOS5]) {
//        [self addIOS5View:pointer];
//        return;
//    }
    if ([self indexOfPointer:pointer] == -1) {
        [self.pointers addPointer:pointer];
    }
}

- (int)indexOfPointer:(void *)pointer {
    
//    if ([self isIOS5]) { return [self indexOfIOS5View:pointer]; }
    
    for (int i = 0; i < [self.pointers count]; i++){
        if ([self.pointers pointerAtIndex: i] == pointer) return i;
    }
    return -1;
}

// remove pointer if it is in the set
- (void)removePointer:(void *)pointer{
    
//    if ([self isIOS5]) {
//        [self removeIOS5View:pointer];
//        return;
//    }
    
    int index = [self indexOfPointer:pointer];
    if (index != -1) {
        [self.pointers removePointerAtIndex:index];
    }
}

- (void *)pointerAtIndex:(NSUInteger)index{
//    if ([self isIOS5]) { return (__bridge void *)(self.ios5views[index]); }
    return [self.pointers pointerAtIndex:index];
}

// eliminate NULLs
- (void)compact{
    [self.pointers compact];
}

- (NSArray *)allObjects {
//    if ([self isIOS5]) { return [self ios5Objects]; }
    return [self.pointers allObjects];
}

- (NSUInteger) count
{
//    if ([self isIOS5]) { return self.capacity; }
    return [self.pointers count];
}

@end
