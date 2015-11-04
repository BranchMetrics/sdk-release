//
//  TuneEncrypter.h
//  TuneEncrypter
//
//  Created by Tune on 1/23/12.
//  Copyright (c) 2012 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

/*!
 An Encryptor Class that provides string encryption methods and is used by
 Tune.
 */

@interface TuneEncrypter : NSObject

/*!
 Encrypts the input string using the specified key.
 @param str The string to be encrypted.
 @param key The key used to encrypt the string.
 */
+ (NSString *)encryptString:(NSString *)str withKey:(NSString *)key;

@end
