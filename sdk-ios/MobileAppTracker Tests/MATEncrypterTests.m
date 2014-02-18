//
//  MATEncrypterTests.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 1/30/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATEncrypter.h"

@interface MATEncrypterTests : XCTestCase

@end

@implementation MATEncrypterTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testEncryptNonASCII
{
    NSString *encryptedStr = nil;
    NSData *decryptedData = nil;
    NSString *decryptedStr = nil;
    NSString *expectedOutput = nil;
    
    NSString *inputStr = nil;
    NSString *key = @"12345678901234567890123456789012";
    
    inputStr = @"&app_name=돔스돔타돔돔&revenue=0.12&ios_ifa=12345678-1234-1234-1234-123456789012";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"&revenue=0.12&ios_ifa=12345678-1234-1234-1234-123456789012&app_name=돔스돔타돔돔";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"&revenue=0.12&ios_ifa=12345678-1234-1234-1234-123456789012&app_name=someappname";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);

    inputStr = @"돔스돔타돔돔";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"돔스돔타";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"1234567890돔스돔타돔돔123456789012345678901234567890";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"1234567890x123456789012345678901234567890";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"1234567890돔123456789012345678901234567890";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"돔1234";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"돔12";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"돔";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"abc";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = @"";
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = inputStr;
    XCTAssertTrue([inputStr isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
    
    inputStr = nil;
    encryptedStr = [MATEncrypter encryptString:inputStr withKey:key];
    decryptedData = [MATEncrypterTests decodeHexData:[MATEncrypterTests aesDecrypt:key data:[MATEncrypterTests decodeHexData:[encryptedStr dataUsingEncoding:NSUTF8StringEncoding]]]];
    decryptedStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expectedOutput = @"";
    XCTAssertTrue([expectedOutput isEqualToString:decryptedStr], @"Encryption failed: expected = %@, actual = %@", expectedOutput, decryptedStr);
}

int char2hex(unsigned char c) {
    switch (c) {
        case '0' ... '9':
            return c - '0';
        case 'a' ... 'f':
            return c - 'a' + 10;
        case 'A' ... 'F':
            return c - 'A' + 10;
        default:
            return 0xFF;
    }
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

+ (NSData *)aesDecrypt:(NSString *)mykey data:(NSData *)str
{
	const void * iv = nil;
	int keyLength = [mykey length];
	if(keyLength != kCCKeySizeAES128 && keyLength != kCCKeySizeAES192 && keyLength != kCCKeySizeAES256)
	{
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
									 (iv == nil ? kCCOptionECBMode | kCCOptionPKCS7Padding : kCCOptionPKCS7Padding),
									 keyBytes,
									 keyLength,
									 iv,
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
