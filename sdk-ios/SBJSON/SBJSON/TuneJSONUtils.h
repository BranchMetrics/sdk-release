//
//  JSONUtils.h
//  TestHTTP
//
//  Created by Michael Raber on 6/6/10.
//  Copyright 2010 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TuneJSONUtils : NSObject {

}

+ (NSString *)createPrettyJSONFromDictionary:(NSDictionary *)dict;
+ (NSString *)createPrettyJSONFromDictionary:(NSDictionary *)dict withSecretTMADepth:(NSNumber *)depth;
+ (NSString *)createJSONStringFromDictionary:(NSDictionary *)dict;
+ (NSDictionary *)createDictionaryFromJSONString:(NSString *)json;
+ (NSArray *)createArrayFromJSONString:(NSString *)json;

//+ (NSString *)createJSONStringFromMutableArray:(NSMutableArray *)array;
+ (NSString *)createJSONStringFromArray:(NSArray *)array;
@end
