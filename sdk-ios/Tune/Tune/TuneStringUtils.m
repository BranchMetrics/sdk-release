//
//  TuneStringUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/27/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneStringUtils.h"
#import "TuneDateUtils.h"

static NSMutableCharacterSet *tune_urlEncodingAllowedCharacterSet;
static NSString *tune_ignoredCharacters = @"!*'\"();:@&=+$,/?%#[] \n";

@implementation TuneStringUtils

+ (void)initialize {
    tune_urlEncodingAllowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [tune_urlEncodingAllowedCharacterSet removeCharactersInString:tune_ignoredCharacters];
}

+ (NSString *)urlEncodeString:(NSString *)unEncodedString {
    if (unEncodedString == nil) return @"";
    
    NSString *encodedString = [unEncodedString stringByAddingPercentEncodingWithAllowedCharacters:tune_urlEncodingAllowedCharacterSet];
    return encodedString;
}

+ (NSString *)removePercentEncoding:(NSString *)string {
    if (string == nil) return nil;
    
    NSString *output = [string stringByRemovingPercentEncoding];
    return output;
}

+ (NSString *)addPercentEncoding:(NSString *)string {
    if (string == nil) return nil;
    
    NSString *output = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return output;
}

+ (BOOL)string:(NSString *)string containsString:(NSString *)subString {
    NSRange range = [string rangeOfString:subString];
    return range.location != NSNotFound;
}

@end
