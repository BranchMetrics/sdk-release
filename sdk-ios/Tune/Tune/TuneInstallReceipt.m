//
//  TuneInstallReceipt.m
//  Tune
//
//  Created by John Bender on 3/24/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneInstallReceipt.h"
#import "TuneDeviceDetails.h"
//#import <MessageUI/MessageUI.h> // just for emailing receipt files, has no effect

@implementation TuneInstallReceipt

+ (NSData*)installReceipt
{
#if TESTING
    return [@"fakeReceiptDataString" dataUsingEncoding:NSUTF8StringEncoding];
#else
    NSData *receiptData = nil;
    
    if ([TuneDeviceDetails appIsRunningIniOS7OrAfter]) {
        // Load resources for iOS 7 or later
        NSURL *appStoreReceiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        receiptData = [NSData dataWithContentsOfURL:appStoreReceiptURL];

        // if you delete the below code, you can also delete the MessageUI import above
        /*
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            MFMailComposeViewController *mailer = [MFMailComposeViewController new];
            [mailer setToRecipients:@[@"johnb@hasoffers.com"]];
            [mailer addAttachmentData:receiptData mimeType:@"application/octet-stream" fileName:@"app-store-receipt"];
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:mailer animated:YES completion:nil];
        }];
         */
    }
    
    return receiptData;
#endif
}

@end
