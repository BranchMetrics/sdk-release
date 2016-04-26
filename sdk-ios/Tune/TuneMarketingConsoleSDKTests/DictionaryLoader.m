//
//  DictionaryLoader.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneJSONUtils.h"
#import "DictionaryLoader.h"

@implementation DictionaryLoader

+ (NSDictionary *)dictionaryFromPListFileNamed:(NSString *)fileName
{
    NSString *pathToDictionary = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"plist"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:pathToDictionary];
    return dictionary;
}
+ (NSArray *)arrayFromPListFileNamed:(NSString *)fileName
{
    NSString *pathToDictionary = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"plist"];
    NSArray *array = [[NSArray alloc] initWithContentsOfFile:pathToDictionary];
    return array;
}

+(NSDictionary *) dictionaryFromJSONFileNamed:(NSString *)fileName{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    
    NSString *playlistData = [NSString stringWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];
    
    NSDictionary *dict = [TuneJSONUtils createDictionaryFromJSONString:playlistData];
    
    return dict;
}

@end
