//
//  TuneInstallReceipt.m
//  Tune
//
//  Created by John Bender on 3/24/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneInstallReceipt.h"

@implementation TuneInstallReceipt

+ (NSData *)installReceipt {
    
#if TESTING
    return [@"fakeReceiptDataString" dataUsingEncoding:NSUTF8StringEncoding];
#else

    NSURL *appStoreReceiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData  = [NSData dataWithContentsOfURL:appStoreReceiptURL];
    
    return receiptData;
#endif
}

@end
