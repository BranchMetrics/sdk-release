//
//  SimpleObserver.h
//  ARUXFLIP
//
//  Created by Kyle Slattery on 12/5/13.
//
//

#import <Foundation/Foundation.h>

@class TuneSkyhookPayload;

@interface SimpleObserver : NSObject

@property (nonatomic) int skyhookPostCount;
@property (nonatomic, readonly) TuneSkyhookPayload* lastPayload;

- (void)skyhookPosted:(TuneSkyhookPayload *)payload;

@end
