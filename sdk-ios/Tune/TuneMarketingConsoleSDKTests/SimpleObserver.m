//
//  SimpleObserver.m
//  ARUXFLIP
//
//  Created by Kyle Slattery on 12/5/13.
//
//

#import "SimpleObserver.h"

@implementation SimpleObserver

- (id)init {
    self = [super init];
    
    if (self) {
        self.skyhookPostCount = 0;
    }
    
    return self;
}

- (void)skyhookPosted:(TuneSkyhookPayload *)payload {
    self.skyhookPostCount += 1;
    _lastPayload = payload;
}

@end
