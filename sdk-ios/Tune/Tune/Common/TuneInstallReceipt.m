//
//  TuneInstallReceipt.m
//  Tune
//
//  Created by John Bender on 3/24/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneInstallReceipt.h"
//#import <MessageUI/MessageUI.h> // just for emailing receipt files, has no effect

@implementation TuneInstallReceipt

+ (NSData*)installReceipt
{
#if TESTING
    return [@"fakeReceiptDataString" dataUsingEncoding:NSUTF8StringEncoding];
#endif

    // This is the correct way to detect whether the `appStoreReceiptURL` selector is available.
    // https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSBundle_Class/Reference/Reference.html#//apple_ref/occ/instm/NSBundle/appStoreReceiptURL
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        return nil;
    } else {
        // Load resources for iOS 7 or later
        NSURL *appStoreReceiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receiptData = [NSData dataWithContentsOfURL:appStoreReceiptURL];

        // if you delete the below code, you can also delete the MessageUI import above
        /*
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            MFMailComposeViewController *mailer = [MFMailComposeViewController new];
            [mailer setToRecipients:@[@"johnb@hasoffers.com"]];
            [mailer addAttachmentData:receiptData mimeType:@"application/octet-stream" fileName:@"app-store-receipt"];
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:mailer animated:YES completion:nil];
        }];
         */

        return receiptData;
    }
}

@end
