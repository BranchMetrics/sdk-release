//
//  TuneSessionManager+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneSessionManager.h"

@interface TuneSessionManager (Testing)

@property (readonly) BOOL sessionStarted;
@property (readonly) NSDate *sessionStartTime;
@property (readonly) NSString *sessionId;

@end
