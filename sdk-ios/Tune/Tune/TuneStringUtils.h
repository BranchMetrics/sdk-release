//
//  TuneStringUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/27/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneStringUtils : NSObject

/** Returns a URL encoded version of the given UTF-8 string.
 
 @param unencodedString The NSString you want to encode
 
 @returns The encoded string. If you pass nil, it will return nil.
 */
+ (NSString *)urlEncodeString:(NSString *)unencodedString;

/**
 Removes percent-encoding from given string.
 
 @param string encoded string
 
 @returns NSString* un-encoded string
 */
+ (NSString *)removePercentEncoding:(NSString *)string;

/**
 Adds percent-encoding to given string.
 
 @param string un-encoded string
 
 @returns NSString* encoded string
 */
+ (NSString *)addPercentEncoding:(NSString *)string;

/**
 Checks whether given string contains a given substring
 
 @param string The full string to search in
 
 @param subString The substring to check whether it exists in the full string
 
 @returns BOOL Whether full string contains substring or not
 */
+ (BOOL)string:(NSString *)string containsString:(NSString *)subString;

@end
