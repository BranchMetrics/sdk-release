//
//  TuneHttpResponse.m
//  Tune
//
//  Created by Kevin Jenkins on 4/11/13.
//
//

#import "TuneHttpResponse.h"

@implementation TuneHttpResponse

#pragma mark - Initialization
- (id)initWithURLResponse:(NSHTTPURLResponse*)response andError:(NSError*)error {
    self = [self init];
    if (self) {
        _urlResponse = response;
        _error = error;
    }
    return self;
}

#pragma mark - Convenience Methods
- (BOOL)wasSuccessful {
    return (self.error == nil && self.urlResponse.statusCode >= 200 && self.urlResponse.statusCode < 300);
}

- (BOOL)failed {
    return !self.wasSuccessful;
}

@end
