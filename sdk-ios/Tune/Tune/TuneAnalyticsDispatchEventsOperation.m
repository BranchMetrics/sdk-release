//
//  TuneAnalyticsDispatchEventsOperation.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/13/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneAnalyticsDispatchEventsOperation.h"
#import "TuneManager.h"
#import "TuneConfiguration.h"
#import "TuneUserProfile.h"
#import "TuneAnalyticsEvent.h"
#import "TuneAnalyticsManager.h"
#import "TuneHttpUtils.h"
#import "NSData+TuneGZIP.h"
#import "NSURLSession+SynchronousTask.h"
#import "TuneJSONUtils.h"

@implementation TuneAnalyticsDispatchEventsOperation

- (id)initWithTuneManager:(TuneManager *)manager {
    self = [self init];
    if (self) {
        self.includeTracer = YES;
        
        urlString = manager.configuration.analyticsHostPort;
        echoAnalytics = manager.configuration.echoAnalytics;
        
        timeoutInterval = @20;
        
        appId = manager.userProfile.hashedAppId;
        deviceId = manager.userProfile.deviceId;
    }
    return self;
}

- (void)main {
    @try {
        DebugLog(@"Dispatching the analytics events.");
        
        if(self.isCancelled) {
            ErrorLog(@"TuneAnalyticsDispatchEventsOperation has already been cancelled: do not read events from disk");
            return;
        }
        
        NSError *error = nil;
        BOOL success = NO;
        
        NSDictionary *eventsFromFile = [TuneFileManager loadAnalyticsFromDisk];
        
        NSMutableArray *eventIds = [[NSMutableArray alloc] initWithCapacity:[eventsFromFile count]];
        NSMutableArray *eventsToSend = [[NSMutableArray alloc] initWithCapacity:[eventsFromFile count]];
        
        // Split the dictionary for the two arrays we need.
        // One to send, and one to store the keys for what we sent (so we can delete it later).
        for (NSString *eventId in eventsFromFile) {
            [eventIds addObject:eventId];
            [eventsToSend addObject:[eventsFromFile objectForKey:eventId]];
        }
        
        // Add the tracer event to the array of event JSON going out the door.
        if ([self includeTracer]) {
            TuneAnalyticsEvent *tracer = [[TuneManager currentManager].analyticsManager buildTracerEvent];
            if (tracer) {
                NSString *tracerJSON = [TuneJSONUtils createJSONStringFromDictionary:[tracer toDictionary]];
                [eventsToSend addObject: tracerJSON];
            }
        }
        
        if(self.isCancelled) {
            ErrorLog(@"TuneAnalyticsDispatchEventsOperation has already been cancelled: do not fire request");
            return;
        }
        
        success = [self postAnalytics:eventsToSend toURL:[NSURL URLWithString:urlString] error:&error];
        
        if (!error && success) {
            [TuneFileManager deleteAnalyticsEventsFromDisk:eventIds];
            InfoLog(@"Successfully sent analytics information to server.");
        } else if (error || !success) {
            DebugLog(@"Unable to send analytics information to server: %@", [error localizedDescription]);
        }
    } @catch (NSException *exception) {
        ErrorLog(@"An exception occured while posting Analytics. Exception: %@", exception.description);
    } @finally {
#if !TARGET_OS_WATCH
        [[TuneManager currentManager].analyticsManager endBackgroundTask];
#endif
    }
}

// TODO: This should use TuneApi to build the Request.
- (BOOL)postAnalytics:(NSArray *)eventsToSubmit toURL:(NSURL *)url error:(NSError **)error {
    NSString *eventsPostString = [self outboundMessageStringFromEventArray:eventsToSubmit];
    if (echoAnalytics) {
        NSLog(@"Posting Analytics to endpoint: %@", urlString);
        NSLog(@"\n%@", [TuneJSONUtils createPrettyJSONFromDictionary:[TuneJSONUtils createDictionaryFromJSONString:eventsPostString]]);
    }
    
    NSString *boundary = @"thisIsMyFileBoundary";
    NSData *zippedPostPayload = [self zipAndEncodeData:[eventsPostString dataUsingEncoding:NSUTF8StringEncoding] withFileBoundary:boundary];
    NSString *requestDataLengthString = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)[zippedPostPayload length]];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:zippedPostPayload];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    [request setValue:requestDataLengthString forHTTPHeaderField:@"Content-Length"];
    [request setTimeoutInterval:[timeoutInterval doubleValue]];
    [TuneHttpUtils addIdentifyingHeaders:request];
    
    // Make a synchronous call, since we're already running on a separate thread.
    [TuneHttpUtils sendSynchronousRequest:request response:nil error:error];
    
    return (*error == nil);
}

- (NSString *)outboundMessageStringFromEventArray:(NSArray*)eventArray {
    // We'll create the JSON string manually since the eventArray contains strings already in JSON format
    // (and we don't want to risk double-encoding via SBJSON)
    
    return [NSString stringWithFormat:@"{ \"events\": [%@]}", [eventArray componentsJoinedByString:@","]];
}

- (NSData*)zipAndEncodeData:(NSData*)uncompressedData withFileBoundary:(NSString*)boundary {
    // GZip Data
    NSMutableData *compressedData = [[NSMutableData alloc] init];
    NSData *zippedData = [uncompressedData tuneGzippedData];
    
    // wrap the zipped data in a file boundary for multi-part transmission
    [compressedData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [compressedData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"analytics.gzip\"\r\n", @"analytics"] dataUsingEncoding:NSUTF8StringEncoding]];
    [compressedData appendData:[@"Content-Type: application/gzip\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [compressedData appendData:zippedData];
    [compressedData appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [compressedData appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return compressedData;
}

@end
