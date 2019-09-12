//
//  TuneUserAgentCollector.m
//  Branch
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "TuneUserAgentCollector.h"
#import <sys/sysctl.h>
#if TARGET_OS_IOS
@import WebKit;
#endif


@interface TuneUserAgentCollector()
// need to hold onto the webview until the async user agent fetch is done
#if TARGET_OS_IOS
@property (nonatomic, strong, readwrite) WKWebView *webview;
#endif
@end

@implementation TuneUserAgentCollector

+ (TuneUserAgentCollector *)shared {
    static TuneUserAgentCollector *collector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collector = [TuneUserAgentCollector new];
    });
    return collector;
}

+ (NSString *)userAgentKey {
    return @"BNC_USER_AGENT";
}

+ (NSString *)systemBuildVersionKey {
    return @"BNC_SYSTEM_BUILD_VERSION";
}

// copied from BNCDevice.m
+ (NSString *) systemBuildVersion {
    int mib[2] = { CTL_KERN, KERN_OSVERSION };
    u_int namelen = sizeof(mib) / sizeof(mib[0]);
    
    //  Get the size for the buffer --
    size_t bufferSize = 0;
    sysctl(mib, namelen, NULL, &bufferSize, NULL, 0);
    if (bufferSize <= 0) return nil;
    
    u_char buildBuffer[bufferSize];
    int result = sysctl(mib, namelen, buildBuffer, &bufferSize, NULL, 0);
    
    NSString *version = nil;
    if (result >= 0) {
        version = [[NSString alloc] initWithBytes:buildBuffer length:bufferSize-1 encoding:NSUTF8StringEncoding];
    }
    return version;
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString * _Nullable))completion {
    [self loadUserAgentForSystemBuildVersion:[TuneUserAgentCollector systemBuildVersion] withCompletion:completion];
}

- (void)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion withCompletion:(void (^)(NSString *userAgent))completion {
    NSString *savedUserAgent = [self loadUserAgentForSystemBuildVersion:systemBuildVersion];
    if (savedUserAgent) {
        self.userAgent = savedUserAgent;
        if (completion) {
            completion(savedUserAgent);
        }
    } else {
        [self collectUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
            self.userAgent = userAgent;
            [self saveUserAgent:userAgent forSystemBuildVersion:systemBuildVersion];
            if (completion) {
                completion(userAgent);
            }
        }];
    }
}

// load user agent from preferences
- (NSString *)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion {
    NSString *userAgent = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedUserAgent = (NSString *)[defaults valueForKey:[TuneUserAgentCollector userAgentKey]];
    NSString *savedSystemBuildVersion = (NSString *)[defaults valueForKey:[TuneUserAgentCollector systemBuildVersionKey]];
    
    if (savedUserAgent && [systemBuildVersion isEqualToString:savedSystemBuildVersion]) {
        userAgent = savedUserAgent;
    }
    return userAgent;
}

// save user agent to preferences
- (void)saveUserAgent:(NSString *)userAgent forSystemBuildVersion:(NSString *)systemBuildVersion {
    if (userAgent && systemBuildVersion) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:userAgent forKey:[TuneUserAgentCollector userAgentKey]];
        [defaults setObject:systemBuildVersion forKey:[TuneUserAgentCollector systemBuildVersionKey]];
    }
}

// collect user agent from webkit.  this is expensive.
- (void)collectUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        #if TARGET_OS_IOS
        self.webview = [[WKWebView alloc] initWithFrame:CGRectZero];
        [self.webview evaluateJavaScript:@"navigator.userAgent;" completionHandler:^(id _Nullable response, NSError * _Nullable error) {            
            if (completion) {
                completion(response);
                
                // release the webview
                self.webview = nil;
            }
        }];
        #endif
    });
}

@end
