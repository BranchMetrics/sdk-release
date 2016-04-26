//
//  TuneSkyhookObserver.m
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneSkyhookObserver.h"

#import "TuneSkyhookPayload.h"

#import <objc/message.h>

@implementation TuneSkyhookObserver

- (id)initWithObserver:(id)observer selector:(SEL)selector sender:(id)sender priority:(int)priority {
    self = [self init];
    
    if (self) {
        _observer = observer;
        _selector = selector;
        _sender = sender;
        _priority = priority;
    }
    
    return self;
}

- (void)sendPayload:(TuneSkyhookPayload *)payload {
    // If the observer has turned to nil, don't do anything.
    if (!self.observer) return;
    
    // Can't use performSelector here because it gives a warning
    // http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
    
    // objc_msgSend(self.observer, self.selector, payload); -- old way was causing crashes on a 5s device
    
    //
    // https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaTouch64BitGuide/ConvertingYourAppto64-Bit/ConvertingYourAppto64-Bit.html#//apple_ref/doc/uid/TP40013501-CH3-SW26
    //
    // TODO: Look into this warning..
    int (*action)(id, SEL, TuneSkyhookPayload *) = (int (*)(id, SEL, TuneSkyhookPayload *)) objc_msgSend;
    action(self.observer, self.selector, payload);
}

- (BOOL)matchesSender:(id)sender {
    // TODO: If an observer is set on a sender that has since been deallocated, that might result in
    // self.sender being set to nil, which means that it will start matching *all* skyhooks for that
    // hook, even though it was originally supposed to be for a specific object.
    //
    // Instead of checking for nil here, we should probably have a separate BOOL property that indicates
    // whether the observer should match *any* sender or a specific one.
    return self.sender == nil || self.sender == sender;
}

- (BOOL)isStillValid {
    return self.observer != nil;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"Skyhook Observer -- observer obj: %@, selector: %@, sender: %@, priority: %d", self.observer, NSStringFromSelector(self.selector), self.sender, self.priority];
}

@end
