//
//  MATEncrypter.m
//  MobileAppTrackeriOS
//
//  Created by Vu Tran on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MATEncrypter.h"

@interface MATEncrypter()

+ (NSMutableString *)hexEncode:(NSMutableString *)str;
+ (NSData *)aesEncryptData:(NSData *)data withKey:(NSMutableString *)mykey;

@end


@implementation MATEncrypter


+(NSMutableString *)encryptString:(NSMutableString *)str withKey:(NSString *)key
{    
	NSString *encodedInput = [self hexEncode:str];
    NSData *inputData = [encodedInput dataUsingEncoding:NSUTF8StringEncoding];
    
	NSData * outputData = [self aesEncryptData:inputData withKey:[NSMutableString stringWithString:key]];
	unsigned char outputstring[[outputData length] + 1];
    
	[outputData getBytes:outputstring];
	NSMutableString *hexret = [NSMutableString stringWithCapacity:(([outputData length] * 2) + 1)];
    
	for(int i = 0; i < [outputData length]; i++)
    {
		[hexret appendFormat:@"%02X", outputstring[i]];
    }
	
	return hexret;
}


+ (NSData *)aesEncryptData:(NSData *)data withKey:(NSMutableString *)mykey
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
	size_t encryptedLength = [data length] + kCCBlockSizeAES128;
	char encryptedBytes[encryptedLength +1];
	
    CCCryptorStatus result = CCCrypt(kCCEncrypt, 
									 kCCAlgorithmAES128 , 
									 (iv == nil ? kCCOptionECBMode | kCCOptionPKCS7Padding : kCCOptionPKCS7Padding),        
									 keyBytes, 
									 keyLength, 
									 iv,
									 [data bytes],
									 [data length],
									 encryptedBytes, 
									 encryptedLength,
									 &numBytesEncrypted);
	
    
	if(result == kCCSuccess)
		return [NSData dataWithBytes:encryptedBytes length:numBytesEncrypted];
    
	return nil;
}

+ (NSMutableString *)hexEncode:(NSMutableString *)str
{
	NSMutableString *hexret = [NSMutableString string];
	unsigned char outputstring[[str length]+1];
	
	strncpy((char *)outputstring, [str UTF8String], [str length]);
	
	for(int i = 0; i < [str length]; i++)
		[hexret appendFormat:@"%02X", outputstring[i]];	
	
	//NSLog(@"hex encode %@ %@",str,hexret);
	return hexret;
}



@end
