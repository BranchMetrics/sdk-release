//
//  TuneLog.m
//  Tune
//
//  Created by Jennifer Owens on 6/27/18.
//  Copyright © 2018 Tune. All rights reserved.
//

#import "TuneLog.h"

@implementation TuneLog

+ (instancetype)shared {
    static TuneLog *tuneLog;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tuneLog = [TuneLog new];
    });
    
    return tuneLog;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.verbose = NO;
    }
    
    return self;
}

- (void)logError:(NSString *)message {
    TuneLogBlock temp = self.logBlock;
    if (temp && message) {
        temp(message);
    }
}

- (void)logVerbose:(NSString *)message {
    TuneLogBlock temp = self.logBlock;
    if (temp && self.verbose && message) {
        temp(message);
    }
}

@end
