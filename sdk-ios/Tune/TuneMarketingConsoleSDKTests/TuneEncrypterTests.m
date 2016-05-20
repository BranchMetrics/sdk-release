//
//  TuneEncrypterTests.m
//  Tune
//
//  Created by Harshal Ogale on 1/30/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TuneEncrypter.h"
#import "TuneEvent+Internal.h"
#import "TuneKeyStrings.h"
#import "TuneTracker.h"

@interface TuneEncrypterTests : XCTestCase

@end

@implementation TuneEncrypterTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
}

- (void)tearDown {
    [super tearDown];
}

- (void)testEncryptNonASCII {
    [self checkEncryption:@"&app_name=돔스돔타돔돔&revenue=0.12&ios_ifa=12345678-1234-1234-1234-123456789012"];
    
    [self checkEncryption:@"&revenue=0.12&ios_ifa=12345678-1234-1234-1234-123456789012&app_name=돔스돔타돔돔"];
    
    [self checkEncryption:@"&revenue=0.12&ios_ifa=12345678-1234-1234-1234-123456789012&app_name=someappname"];
    
    [self checkEncryption:@"돔스돔타돔돔"];
    
    [self checkEncryption:@"돔스돔타"];
    
    [self checkEncryption:@"1234567890돔스돔타돔돔123456789012345678901234567890"];
    
    [self checkEncryption:@"1234567890x123456789012345678901234567890"];
    
    [self checkEncryption:@"1234567890돔123456789012345678901234567890"];
    
    [self checkEncryption:@"돔1234"];
    
    [self checkEncryption:@"돔12"];
    
    [self checkEncryption:@"돔"];
    
    [self checkEncryption:@"abc"];
    
    [self checkEncryption:@"&debug=1&sdk_retry_attempt=0&app_name=MATCustom&app_version=1.0&country_code=US&currency_code=USD&device_brand=Apple&device_cpu_subtype=4&device_cpu_type=7&device_model=x86_64&level=0&quantity=0&rating=0&revenue=0&ios_purchase_status=-192837465&existing_user=0&gender=0&insdate=1441394881&ios_ad_tracking=1&ios_ifa=AA9A097A-4C24-44FF-A770-7ADC00DA2759&ios_ifv=6A142E73-2E52-4017-8A77-DE78E6969BEE&language=en&mat_id=307759F8-9CEB-4254-AFF0-A270D4347E89&os_jailbroke=0&os_version=8.4&screen_density=2&screen_size=320x480&system_date=1441394887&attr_set=1&publisher_id=123456789&publisher_sub_keyword=somekeyword1&publisher_sub2=pubsubvalue2&skip_dup=1&encrypted_request=1"];
    
    [self checkEncryption:TUNE_STRING_EMPTY];
    
    [self checkEncryption:nil expectedOutput:TUNE_STRING_EMPTY];
    
    [self checkEncryption:(id)[NSNull null] expectedOutput:TUNE_STRING_EMPTY];
}

- (void)checkEncryption:(NSString *)input {
    [self checkEncryption:input expectedOutput:input];
}

- (void)checkEncryption:(NSString *)input expectedOutput:(NSString *)expectedOutput {
    NSString *key = @"12345678901234567890123456789012";
    
    NSString *encryptedStr = [TuneEncrypter encryptString:input withKey:key];
    NSData *decryptedData = [TuneEncrypterTests decodeHexData:[TuneEncrypterTests aesDecrypt:key data:[TuneEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    NSString *decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
}

- (void)testNoEncryptTransaction {
    TuneTracker *tracker = [TuneTracker new];
    NSString *trackingLink, *encryptedParams;
    [tracker urlStringForEvent:[TuneEvent eventWithName:@"event1"]
                   trackingLink:&trackingLink
                  encryptParams:&encryptedParams];
    XCTAssertTrue( [trackingLink rangeOfString:@"&transaction_id="].location != NSNotFound, @"transaction_id not found in unencrypted params" );
}

+ (NSData *)decodeHexData:(NSData *)input {
    NSMutableData *resultData = [NSMutableData dataWithLength:([input length]) / 2];
    
    const unsigned char *hexBytes = [input bytes];
    unsigned char *resultBytes = [resultData mutableBytes];
    
    for(NSUInteger i = 0; i < [input length] / 2; i++) {
        resultBytes[i] = (char2hex(hexBytes[i + i]) << 4) | char2hex(hexBytes[i + i + 1]);
    }
    
    return resultData;
}

+ (NSData *)aesDecrypt:(NSString *)mykey data:(NSData *)str {
    long keyLength = [mykey length];
    if(keyLength != kCCKeySizeAES128 && keyLength != kCCKeySizeAES192 && keyLength != kCCKeySizeAES256) {
        return nil;
    }
    
    char keyBytes[keyLength + 1];
    bzero(keyBytes, sizeof(keyBytes));
    [mykey getCString:keyBytes maxLength:sizeof(keyBytes) encoding:NSUTF8StringEncoding];
    
    size_t numBytesEncrypted = 0;
    size_t encryptedLength = [str length] + kCCBlockSizeAES128;
    char encryptedBytes[encryptedLength +1];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES128 ,
                                     kCCOptionECBMode | kCCOptionPKCS7Padding,
                                     keyBytes,
                                     keyLength,
                                     NULL,
                                     [str bytes],
                                     [str length],
                                     encryptedBytes,
                                     encryptedLength,
                                     &numBytesEncrypted);
    
    
    if(result == kCCSuccess)
        return [NSData dataWithBytes:encryptedBytes length:numBytesEncrypted];
    
    return nil;
}

@end
