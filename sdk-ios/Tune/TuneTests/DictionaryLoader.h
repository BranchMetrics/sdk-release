//
//  DictionaryLoader.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

@interface DictionaryLoader : NSObject

+ (NSDictionary*)dictionaryFromPListFileNamed:(NSString*)fileName;

+ (NSArray*)arrayFromPListFileNamed:(NSString*)fileName;

+ (NSDictionary *)dictionaryFromJSONFileNamed:(NSString *)fileName;

@end
