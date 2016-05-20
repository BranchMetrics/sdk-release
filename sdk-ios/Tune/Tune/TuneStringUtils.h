//
//  TuneStringUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/27/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneStringUtils : NSObject

/**
 Mongo keys can't contain "$" or "." so this function will remove those characters
 */
+ (NSString *)scrubNameForMongo:(NSString *)name;

/**
 * Checks that the given string is not blank.
 *
 * [TuneStringUtils isBlank:nil]          => true
 * [TuneStringUtils isBlank:@""]          => true
 * [TuneStringUtils isBlank:@"   "]       => true
 * [TuneStringUtils isBlank:@"shred"]     => false
 * [TuneStringUtils isBlank:@"  shred  "] => false
 */
+ (BOOL)isBlank:(NSString *)string;

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
 Humanize a string by removing components after a double colon, decamelcasing the string and removing
 any instances of the word controller.
 
 @param string The NSString you would like to make human-readable.
 
 @returns NSString* The newly humanized string.
 */
+ (NSString*)humanizeString:(NSString*)string;

/**
 Convert a string from CamelCase to underscore notation by preceding all capital letters with an underscore
 and decapitalizing them.  Assumes that the string does not start with a capital letter.
 
 @param string The CamelCased NSString you would like to express in underscore notation.
 
 @returns NSString* The newly underscored string.
 */
+ (NSString *)fromCamelCaseToUnderscore:(NSString *)string;

/**
 Strip all non-alphanumeric characters from a string (save for the underscore and dash)
 
 @param string The string from which special characters should be stripped.
 
 @returns NSString* The newly underscored string.
 */
+ (NSString *)stripSpecialCharacters:(NSString *)string;

/**
 Converts given hex-encoded String to regular String
 
 @param string The string to convert from hex
 
 @returns NSString* hex-decoded string
 */
+ (NSString *)stringFromHexString:(NSString *)string;


@end
