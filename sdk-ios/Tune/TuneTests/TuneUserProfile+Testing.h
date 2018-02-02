//
//  TuneUserProfile+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneUserProfile.h"

@interface TuneUserProfile (Testing)

- (void)storeProfileKey:(NSString *)key value:(id)value;
- (void)initiateSession:(TuneSkyhookPayload *)payload;
- (NSSet *)getCustomProfileVariables;

@end
