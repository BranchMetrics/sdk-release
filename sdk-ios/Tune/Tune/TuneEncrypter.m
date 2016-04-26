//
//  TuneEncrypter.m
//  Tune
//
//  Created by Vu Tran on 1/25/12.
//  Copyright (c) 2012 TUNE. All rights reserved.
//

#import "TuneEncrypter.h"
#import "TuneKeyStrings.h"

@interface TuneEncrypter()

+ (NSString *)hexEncode:(NSData *)str;
+ (NSData *)aesEncryptData:(NSData *)data withKey:(NSString *)mykey;

@end


@implementation TuneEncrypter


+ (NSString *)encryptString:(NSString *)str withKey:(NSString *)key
{
    NSString *output = nil;

    if(nil == str || (id)[NSNull null] == str)
    {
        output = TUNE_STRING_EMPTY;
    }
    else
    {
        // hex encode the input string
        NSString *encodedInput = [self hexEncode:[str dataUsingEncoding:NSUTF8StringEncoding]];
        
        // hex encoded input data
        NSData *inputData = [encodedInput dataUsingEncoding:NSUTF8StringEncoding];
        
        // encrypt the hex encoded input data
        NSData * outputData = [self aesEncryptData:inputData withKey:key];
        
        // hex encode the encrypted data
        output = [self hexEncode:outputData];
    }
    
    return output;
}


+ (NSData *)aesEncryptData:(NSData *)data withKey:(NSString *)mykey
{
    NSInteger keyLength = [mykey length];
    if(keyLength != kCCKeySizeAES128 && keyLength != kCCKeySizeAES192 && keyLength != kCCKeySizeAES256)
    {
        return nil;
    }
    
    char keyBytes[keyLength + 1];
    bzero(keyBytes, sizeof(keyBytes));
    [mykey getCString:keyBytes maxLength:sizeof(keyBytes) encoding:NSUTF8StringEncoding];
    
    size_t numBytesEncrypted = 0;
    size_t encryptedLength = [data length] + kCCBlockSizeAES128;
    char encryptedBytes[encryptedLength + 1];
    
    CCCryptorStatus result = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES128 ,
                                     kCCOptionECBMode | kCCOptionPKCS7Padding,
                                     keyBytes,
                                     keyLength,
                                     NULL,
                                     [data bytes],
                                     [data length],
                                     encryptedBytes,
                                     encryptedLength,
                                     &numBytesEncrypted);
    
    if(result == kCCSuccess)
        return [NSData dataWithBytes:encryptedBytes length:numBytesEncrypted];
    
    return nil;
}


+ (NSString *)hexEncode:(NSData *)data
{
    // extract bytes from NSData object
    NSUInteger dataLength = [data length];
    unsigned char dataBytes[dataLength + 1];
    [data getBytes:dataBytes length:dataLength];
    
    // create the hex encoded string
    NSMutableString *hexret = [NSMutableString string];
    for(int i = 0; i < dataLength; i++)
    {
        [hexret appendFormat:@"%02X", dataBytes[i]];
    }
    
    return [NSString stringWithString:hexret];
}


@end
