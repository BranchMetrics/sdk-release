//
//  JSONUtils.m
//  TestHTTP
//
//  Created by Michael Raber on 6/6/10.
//  Copyright 2010 TUNE. All rights reserved.
//

#import "TuneJSONUtils.h"
#import "TuneSBJSON.h"
#import "TuneSBJsonWriter.h"

@implementation TuneJSONUtils

+ (NSString *)createPrettyJSONFromDictionary:(NSDictionary *)dict {
    TuneSBJsonWriter *jsonWriter = [TuneSBJsonWriter new];
    [jsonWriter setHumanReadable:YES];
    [jsonWriter setSortKeys:YES];
    jsonWriter.secretTMAFormatDepth = @(4);
    NSString *jsonString = [jsonWriter stringWithObject:dict];
    
    return jsonString;
}

+ (NSString *)createPrettyJSONFromDictionary:(NSDictionary *)dict withSecretTMADepth:(NSNumber *)depth {
    TuneSBJsonWriter *jsonWriter = [TuneSBJsonWriter new];
    [jsonWriter setHumanReadable:YES];
    [jsonWriter setSortKeys:YES];
    jsonWriter.secretTMAFormatDepth = depth;
    NSString *jsonString = [jsonWriter stringWithObject:dict];
    
    return jsonString;
}

+ (NSString *)createJSONStringFromDictionary:(NSDictionary *)dict{
  TuneSBJsonWriter *jsonWriter = [TuneSBJsonWriter new];
    
  NSString *jsonString = [jsonWriter stringWithObject:dict];
  return jsonString;
}

+ (NSDictionary *)createDictionaryFromJSONString:(NSString *)json{
  TuneSBJSON *jsonParser = [TuneSBJSON new];
	
  id jsonData = [jsonParser objectWithString:json];
	
  NSDictionary *jsonDict = (NSDictionary *)jsonData;
	
  return jsonDict;
}

+ (NSArray *)createArrayFromJSONString:(NSString *)json{
    TuneSBJSON *jsonParser = [TuneSBJSON new];
	
    id jsonData = [jsonParser objectWithString:json];
	
    NSArray *jsonDict = (NSArray *)jsonData;
	
    return jsonDict;
}

+ (NSString *)createJSONStringFromArray:(NSArray *)array{
    TuneSBJsonWriter *jsonWriter = [TuneSBJsonWriter new];
    
    NSString *jsonString = [jsonWriter stringWithObject:array];
    
    return jsonString;
}

@end
