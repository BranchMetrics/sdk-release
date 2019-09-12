//
//  TuneEventQueue.m
//  Tune
//
//  Created by John Bender on 8/12/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneEventQueue.h"

#import "TuneConfiguration.h"
#import "TuneEncrypter.h"
#import "TuneFileUtils.h"
#import "TuneHttpUtils.h"
#import "TuneHttpRequest.h"
#import "TuneKeyStrings.h"
#import "TuneLocation+Internal.h"
#import "TuneLocationHelper.h"
#import "TuneLog.h"
#import "TuneManager.h"
#import "TuneNetworkUtils.h"
#import "TuneReachability.h"
#import "TuneUserAgentCollector.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneSkyhookCenter.h"
#import "TuneUserProfile.h"


const NSTimeInterval TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL  = 60.;

static NSString* const TUNE_REQUEST_QUEUE_FOLDER            = @"MATqueue";
static NSString* const TUNE_REQUEST_QUEUE_FILENAME          = @"events.json";
static NSString* const TUNE_LEGACY_REQUEST_QUEUE_FOLDER     = @"queue";

static const NSInteger TUNE_REQUEST_400_ERROR_CODE          = 1302;

#pragma mark - Private variables

@interface TuneEventQueue()

@property (nonatomic, strong, readwrite) NSOperationQueue *requestOpQueue;
@property (nonatomic, strong, readwrite) NSMutableArray *events;
@property (nonatomic, copy, readwrite) NSString *storageDir;

@property (nonatomic, weak) id <TuneEventQueueDelegate> delegate;

#if TESTING
@property (nonatomic, assign) BOOL forceError;
@property (nonatomic, assign) NSInteger forcedErrorCode;

- (void) saveQueue;
- (void) dumpQueue;
#endif

@end

@implementation TuneEventQueue

#pragma mark - Initialization

static dispatch_once_t sharedQueueOnceToken;

+ (TuneEventQueue *)sharedQueue {
    static TuneEventQueue *queue;
    dispatch_once(&sharedQueueOnceToken, ^{
        queue = [TuneEventQueue new];
    });
    return queue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requestOpQueue = [NSOperationQueue new];
        self.requestOpQueue.maxConcurrentOperationCount = 1;
        
        [self addNetworkAndAppNotificationListeners];
        [self createQueueStorageDirectory];
        [self loadQueue];
        
        // move data from legacy locations
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self moveOldQueueStorageDirectoryToTemp];
        });
        
        [self dumpQueue];
    }
    return self;
}

- (void)addNetworkAndAppNotificationListeners {
#if !TARGET_OS_WATCH
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(networkChangeHandler:)
                                              name:kTuneReachabilityChangedNotification
                                            object:nil];
#endif
    
    NSString *strNotif = nil;
#if TARGET_OS_WATCH
    strNotif = NSExtensionHostDidBecomeActiveNotification;
#else
    strNotif = UIApplicationDidBecomeActiveNotification;
#endif
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(networkChangeHandler:)
                                              name:strNotif
                                            object:nil];
}

/*!
 Creates a disk folder to be used to store the serialized event queue.
 */
- (void)createQueueStorageDirectory {
    self.storageDir = [self queueStorageDirectory];
    [TuneFileUtils createDirectory:self.storageDir];
}

- (NSString *)queueStorageDirectory {
    return [NSTemporaryDirectory() stringByAppendingString:TUNE_REQUEST_QUEUE_FOLDER];
}

// SDK-231 legacy code, only used for data migration
- (NSString *)oldQueueStorageDirectory {
    NSString *oldStorageDir;
    
    NSSearchPathDirectory queueParentFolder = NSDocumentDirectory;
#if TARGET_OS_TV // || TARGET_OS_WATCH
    queueParentFolder = NSCachesDirectory;
#endif
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(queueParentFolder, NSUserDomainMask, YES);
    NSString *baseFolder = [paths objectAtIndex:0];
    oldStorageDir = [baseFolder stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FOLDER];
    
    return oldStorageDir;
}

// SDK-231 move queue storage to the temp directory
// old queue storage is in the documents directory, this is against Apple's data storage guidelines
// https://developer.apple.com/icloud/documentation/data-storage/index.html
- (void)moveOldQueueStorageDirectoryToTemp {
    NSString *oldDirectory = [self oldQueueStorageDirectory];
    NSString *newDirectory = [self queueStorageDirectory];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSError *error;
    NSArray *files = [fm contentsOfDirectoryAtPath:oldDirectory error:&error];
    
    for (NSString *file in files) {
        [fm moveItemAtPath:[oldDirectory stringByAppendingPathComponent:file] toPath:[newDirectory stringByAppendingPathComponent:file] error:&error];
    }
    [fm removeItemAtPath:oldDirectory error:&error];
}

#pragma mark - Notification Handlers

- (void)networkChangeHandler:(TuneSkyhookPayload *)payload {
    [self dumpQueue];
}

#pragma mark - Request handling

- (void)enqueueUrlRequest:(NSString*)trackingLink
              eventAction:(NSString*)actionName
                    refId:(NSString*)refId
            encryptParams:(NSString*)encryptParams
                 postData:(NSDictionary*)postData
                  runDate:(NSDate*)runDate {
    [self enqueueUrlRequest:trackingLink eventAction:actionName refId:refId encryptParams:encryptParams postData:postData runDate:runDate shouldQueue:YES];
}

- (void)sendUrlRequestImmediately:(NSString*)trackingLink
                      eventAction:(NSString*)actionName
                            refId:(NSString*)refId
                    encryptParams:(NSString*)encryptParams
                         postData:(NSDictionary*)postData
                          runDate:(NSDate*)runDate {
    [self enqueueUrlRequest:trackingLink eventAction:actionName refId:refId encryptParams:encryptParams postData:postData runDate:runDate shouldQueue:NO];
}

- (void)enqueueUrlRequest:(NSString*)trackingLink
              eventAction:(NSString*)actionName
                    refId:(NSString*)refId
            encryptParams:(NSString*)encryptParams
                 postData:(NSDictionary*)postData
                  runDate:(NSDate*)runDate
              shouldQueue:(BOOL)shouldQueue {
    // add retry count to tracking link
    [self appendOrIncrementRetryCount:&trackingLink sendDate:&runDate];
    
    // add item to queue
    // note that postData might be nil
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setValue:@([runDate timeIntervalSince1970]) forKey:TUNE_KEY_RUN_DATE];
    [item setValue:actionName forKey:TUNE_KEY_ACTION];
    [item setValue:trackingLink forKey:TUNE_KEY_URL];
    [item setValue:encryptParams forKey:TUNE_KEY_DATA];
    [item setValue:postData forKey:TUNE_KEY_JSON];
    [item setValue:refId forKey:TUNE_KEY_REF_ID];
    
    if (shouldQueue) {
        @synchronized(self) {
            [self.events addObject:item];
            
            [self saveQueue];
        }
        
        [self dumpQueue];
    } else {
        [self sendImmediately:item];
    }
}

- (void)appendOrIncrementRetryCount:(NSString**)trackingLink sendDate:(NSDate**)sendDate {
    NSInteger retryCount = 0;
    NSString *searchString = [NSString stringWithFormat:@"&%@=", TUNE_KEY_RETRY_COUNT];
    NSRange searchResult = [*trackingLink rangeOfString:searchString];
    
    if( searchResult.location == NSNotFound ) {
        *trackingLink = [*trackingLink stringByAppendingFormat:@"%@0", searchString];
        // don't touch send date
    } else {
        // parse number, increment it, replace it
        NSString *countString = [*trackingLink substringFromIndex:searchResult.location + searchResult.length];
        retryCount = [countString integerValue];
        NSUInteger valueLength = MAX(1, (int)(log10(retryCount)+1)); // count digits
        retryCount++;
        *trackingLink = [NSString stringWithFormat:@"%@%ld%@",
                         [*trackingLink substringToIndex:searchResult.location + searchResult.length],
                         (long)retryCount,
                         [*trackingLink substringFromIndex:searchResult.location + searchResult.length + valueLength]];
        *sendDate = [*sendDate dateByAddingTimeInterval:[self retryDelayForAttempt:retryCount]];
    }
}

- (void)updateEnqueuedEventsWithReferralUrl:(NSString *)url referralSource:(NSString *)bundleId {
    @synchronized(self) {
        // start updating events from the end of queue
        for (long i = self.events.count - 1; i >= 0; --i) {
            NSMutableDictionary *dictEvent = self.events[i];
            
            if (![dictEvent[TUNE_KEY_NETWORK_REQUEST_PENDING] boolValue]) {
                [dictEvent setValue:url forKey:TUNE_KEY_REFERRAL_URL];
                [dictEvent setValue:bundleId forKey:TUNE_KEY_REFERRAL_SOURCE];
                
                // do not update events that were fired before the last "session" request
                if([dictEvent[TUNE_KEY_ACTION] isEqualToString:TUNE_EVENT_SESSION]) {
                    break;
                }
            }
        }
        
        [self saveQueue];
    }
}

- (void)updateEnqueuedSessionEventWithIadAttributionInfo:(NSDictionary *)iadInfo impressionDate:(NSDate *)impressionDate completionHandler:(void(^)(BOOL updated, NSString *refId, NSString *url, NSDictionary *postDict))completionHandler {
    BOOL updated = NO;
    NSString *refId = nil;
    NSString *url = nil;
    NSDictionary *postDict = nil;
    
    @synchronized(self) {
        // extract the very first "session" event if it is still enqueued
        
        NSMutableDictionary *dictEvent = self.events.count > 0 ? self.events[0] : nil;
        
        if (![TuneUtils isFirstSessionRequestComplete] && ![dictEvent[TUNE_KEY_NETWORK_REQUEST_PENDING] boolValue] && [dictEvent[TUNE_KEY_ACTION] isEqualToString:TUNE_EVENT_SESSION]) {
            if (impressionDate) {
                NSString *queryParams = [NSString stringWithFormat:@"%@&%@=%@", dictEvent[TUNE_KEY_DATA], TUNE_KEY_IAD_IMPRESSION_DATE, [TuneUtils urlEncodeQueryParamValue:impressionDate]];
                dictEvent[TUNE_KEY_DATA] = queryParams;
                updated = YES;
            }
            
            id postJsonStringOrDict = dictEvent[TUNE_KEY_JSON];
            
            // handle post data json string from SDK versions <= 4.9.1
            if ([postJsonStringOrDict isKindOfClass:[NSString class]]) {
                NSData *dataPost = [postJsonStringOrDict dataUsingEncoding:NSUTF8StringEncoding];
                postDict = [NSJSONSerialization JSONObjectWithData:dataPost options:0 error:nil];
            } else if ([postJsonStringOrDict isKindOfClass:[NSDictionary class]]) {
                postDict = postJsonStringOrDict;
            }
            
            if (!postDict) {
                postDict = @{};
            }
            
            // update postData json with iAd attribution info
            NSMutableDictionary *newPostDict = postDict.mutableCopy;
            [newPostDict setValue:iadInfo forKey:TUNE_KEY_IAD];
            
            // update enqueued event dictionary
            dictEvent[TUNE_KEY_JSON] = newPostDict;
            
            // prepare the result
            url = [NSString stringWithFormat:@"%@%@", [dictEvent valueForKey:TUNE_KEY_URL], [dictEvent valueForKey:TUNE_KEY_DATA]];
            if (dictEvent[TUNE_KEY_REF_ID]) {
                refId = [NSString stringWithString:dictEvent[TUNE_KEY_REF_ID]];
            }
            postDict = newPostDict;
            updated = YES;
            
            // store the updated events queue
            [self saveQueue];
        }
    }
    
    completionHandler(updated, refId, url, postDict);
}

- (NSTimeInterval)retryDelayForAttempt:(NSInteger)attempt {
#if TESTING
    return 0.2;
#else
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        srand48( time( 0 ) );
    });
    
    NSTimeInterval delay;
    switch( attempt ) {
        case 0:
            delay = 0.;
            break;
        case 1:
            delay = 30.;
            break;
        case 2:
            delay = 90.;
            break;
        case 3:
            delay = 10.*60.;
            break;
        case 4:
            delay = 60.*60;
            break;
        case 5:
            delay = 6.*60.*60.;
            break;
        case 6:
        default:
            delay = 24.*60.*60.;
    }
    
    return (1 + 0.1*drand48())*delay;
#endif
}


#pragma mark - Sending requests

- (NSString*)updateTrackingLink:(NSString*)trackingLink encryptParams:(NSString*)encryptParams referralUrl:(NSString *)refUrl referralSource:(NSString*)refSource {
    // Add/update tracked values that are determined asynchronously.
    
    if( encryptParams != nil ) {
        NSString *searchString = nil;
        
        // append referral_url if not present
        searchString = [NSString stringWithFormat:@"&%@=", TUNE_KEY_REFERRAL_URL];
        if( refUrl && [encryptParams rangeOfString:searchString].location == NSNotFound) {
            NSString *encodedRefUrl = [TuneUtils urlEncodeQueryParamValue:refUrl];
            if(encodedRefUrl) {
                NSString *refUrlParam = [NSString stringWithFormat:@"&%@=%@", TUNE_KEY_REFERRAL_URL, encodedRefUrl];
                encryptParams = [encryptParams stringByAppendingString:refUrlParam];
            }
        }
        
        // add referral_source if not present
        searchString = [NSString stringWithFormat:@"&%@=", TUNE_KEY_REFERRAL_SOURCE];
        if( refSource && [encryptParams rangeOfString:searchString].location == NSNotFound) {
            NSString *encodedRefSource = [TuneUtils urlEncodeQueryParamValue:refSource];
            if(encodedRefSource) {
                NSString *refSourceParam = [NSString stringWithFormat:@"&%@=%@", TUNE_KEY_REFERRAL_SOURCE, encodedRefSource];
                encryptParams = [encryptParams stringByAppendingString:refSourceParam];
            }
        }
        
        // if iad_attribution, append/overwrite current status
        if ([self.delegate isiAdAttribution]) {
            searchString = [NSString stringWithFormat:@"&%@=0", TUNE_KEY_IAD_ATTRIBUTION];
            NSString *replaceString = [NSString stringWithFormat:@"&%@=1", TUNE_KEY_IAD_ATTRIBUTION];
            
            // make sure iad_attribution=1 key-value is included only once
            if([encryptParams rangeOfString:replaceString].location == NSNotFound) {
                if ([encryptParams rangeOfString:searchString].location != NSNotFound) {
                    encryptParams = [encryptParams stringByReplacingOccurrencesOfString:searchString withString:replaceString];
                } else {
                    encryptParams = [encryptParams stringByAppendingString:replaceString];
                }
            }
        }
        
        // append user agent, if not present
        searchString = [NSString stringWithFormat:@"%@=", TUNE_KEY_CONVERSION_USER_AGENT];
        if ([encryptParams rangeOfString:searchString].location == NSNotFound) {
            // url encoded user agent string
            NSString *encodedUserAgent = [TuneUtils urlEncodeQueryParamValue:[TuneUserAgentCollector shared].userAgent];
            if (encodedUserAgent) {
                encryptParams = [encryptParams stringByAppendingFormat:@"&%@=%@", TUNE_KEY_CONVERSION_USER_AGENT, encodedUserAgent];
            }
        }
        
        // if the request url does not contain device location params, auto-collection
        // is enabled and location access is permitted, then try to auto-collect
        searchString = [NSString stringWithFormat:@"%@=", TUNE_KEY_LATITUDE];
        
        if( [encryptParams rangeOfString:searchString].location == NSNotFound && [TuneLocationHelper isLocationEnabled]  && TuneConfiguration.sharedConfiguration.collectDeviceLocation) {
            // try accessing location
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
            [[TuneLocationHelper class] performSelectorOnMainThread:@selector(getOrRequestDeviceLocation:) withObject:arr waitUntilDone:YES];
            
            // if location is not readily available
            if( 0 == arr.count ) {
                // wait for location update to finish
                [NSThread sleepForTimeInterval:TUNE_LOCATION_UPDATE_DELAY];
                
                // retry accessing location
                [[TuneLocationHelper class] performSelectorOnMainThread:@selector(getOrRequestDeviceLocation:) withObject:arr waitUntilDone:YES];
            }
            
            // if the location is available
            if( 1 == arr.count ) {
                TuneLocation *location = arr[0];
                
                [[TuneManager currentManager].userProfile setLocation:location];
                
                NSMutableString *mutableEncryptParams = [NSMutableString stringWithString:encryptParams];
                [TuneUtils addUrlQueryParamValue:location.altitude forKey:TUNE_KEY_ALTITUDE queryParams:mutableEncryptParams];
                [TuneUtils addUrlQueryParamValue:location.latitude forKey:TUNE_KEY_LATITUDE queryParams:mutableEncryptParams];
                [TuneUtils addUrlQueryParamValue:location.longitude forKey:TUNE_KEY_LONGITUDE queryParams:mutableEncryptParams];
                [TuneUtils addUrlQueryParamValue:location.horizontalAccuracy forKey:TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY queryParams:mutableEncryptParams];
                [TuneUtils addUrlQueryParamValue:location.verticalAccuracy forKey:TUNE_KEY_LOCATION_VERTICAL_ACCURACY queryParams:mutableEncryptParams];
                [TuneUtils addUrlQueryParamValue:location.timestamp forKey:TUNE_KEY_LOCATION_TIMESTAMP queryParams:mutableEncryptParams];
                
                // include the location info in the request url
                encryptParams = mutableEncryptParams;
            }
        }
        
        // encrypt params and append
        NSString *encryptedData = [TuneEncrypter encryptString:encryptParams withKey:[self.delegate encryptionKey]];
        trackingLink = [trackingLink stringByAppendingFormat:@"&%@=%@", TUNE_KEY_DATA, encryptedData];
    }
    
    return trackingLink;
}

- (void)sendImmediately:(NSMutableDictionary *)request {
    NSOperationQueue *queue = [NSOperationQueue new];
    [queue addOperationWithBlock:^{
        if( ![TuneNetworkUtils isNetworkReachable] ) return;
        
        // sleep until fire date
        NSDate *runDate = [NSDate dateWithTimeIntervalSince1970:[request[TUNE_KEY_RUN_DATE] doubleValue]];
        if( [runDate isKindOfClass:[NSDate class]] ) {
            [NSThread sleepUntilDate:runDate];
        }
        
        @synchronized(self) {
            request[TUNE_KEY_NETWORK_REQUEST_PENDING] = @(YES);
        }
        
        // fire URL request synchronously
        NSString *trackingLink = request[TUNE_KEY_URL];
        NSString *encryptParams = request[TUNE_KEY_DATA];
        id postJsonStringOrDict = request[TUNE_KEY_JSON];
        NSString *refUrl = request[TUNE_KEY_REFERRAL_URL];
        NSString *refSource = request[TUNE_KEY_REFERRAL_SOURCE];
        
        NSString *fullRequestString = [self updateTrackingLink:trackingLink encryptParams:encryptParams referralUrl:refUrl referralSource:refSource];
        
        NSData *postData = nil;
        
        // handle post data json string from SDK versions <= 4.9.1
        if ([postJsonStringOrDict isKindOfClass:[NSString class]]) {
            postData = [postJsonStringOrDict dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([postJsonStringOrDict isKindOfClass:[NSDictionary class]]) {
            postData = [TuneUtils jsonSerializedDataForObject:postJsonStringOrDict];
        }
        
#if TESTING
        // for testing, attempt informing the delegate's delegate of the trackingLink
        if (self.unitTestCallback) {
            NSString *postStr = nil;
            
            if ([postJsonStringOrDict isKindOfClass:[NSString class]]) {
                postStr = postJsonStringOrDict;
            } else if (postData) {
                postStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
            }
            
            self.unitTestCallback(fullRequestString, postStr);
        }
#endif
        NSURL *reqUrl = [NSURL URLWithString:fullRequestString];
        NSMutableURLRequest *urlReq = [NSMutableURLRequest requestWithURL:reqUrl
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
#if TESTING
        // These calls require the URL to be a GET
        if ([fullRequestString rangeOfString:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode"].location != NSNotFound) {
            [urlReq setHTTPMethod:TuneHttpRequestMethodTypeGet];
        } else {
            [urlReq setHTTPMethod:TuneHttpRequestMethodTypePost];
        }
#else
        [urlReq setHTTPMethod:TuneHttpRequestMethodTypePost];
#endif
        [urlReq setValue:TUNE_HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:TUNE_HTTP_CONTENT_TYPE];
        [urlReq setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:TUNE_HTTP_CONTENT_LENGTH];
        [urlReq setHTTPBody:postData];
        
        void (^handlerBlock)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable) =
        ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse *urlResp = (NSHTTPURLResponse *)response;
            NSString *trackingUrl = request[TUNE_KEY_URL];
                
            NSInteger code = 0;
            if (error != nil) {
                if ([self.delegate respondsToSelector:@selector(queueRequestDidFailWithError:request:response:)]) {
                    [self.delegate queueRequestDidFailWithError:error request:fullRequestString response:response.debugDescription];
                }
                
                urlResp = nil; // set response to nil and make sure that the request is retried
            }
                
#if TESTING
            // when testing network errors, use forced error code
            if (self.forceError) {
                code = self.forcedErrorCode;
            }
            else
#endif
                code = [urlResp statusCode];
            NSDictionary *headers = [urlResp allHeaderFields];
            NSMutableDictionary *newFirstItem = nil;
                
            // if the network request was successful, great
            if (code >= 200 && code <= 299) {
                if ([self.delegate respondsToSelector:@selector(queueRequest:didSucceedWithData:)]) {
                    [self.delegate queueRequest:fullRequestString didSucceedWithData:data];
                }
                // leave newFirstItem nil to delete
            }
            // for HTTP 400, if it's from our server, drop the request and don't retry
            else if ( code == 400 && headers[@"X-MAT-Responder"] != nil ) {
                if ([self.delegate respondsToSelector:@selector(queueRequestDidFailWithError:request:response:)]) {
                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedFailureReasonErrorKey] = @"Bad Request";
                    userInfo[NSLocalizedDescriptionKey] = @"HTTP 400/Bad Request received from Tune server";
                    userInfo[NSURLErrorKey] = reqUrl;
                    
                    // use setValue:forKey: to handle nil error object
                    [userInfo setValue:error forKey:NSUnderlyingErrorKey];
                    
                    NSError *e = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                     code:TUNE_REQUEST_400_ERROR_CODE
                                                 userInfo:userInfo];
                    [self.delegate queueRequestDidFailWithError:e request:fullRequestString response:response.debugDescription];
                }
                // leave newFirstItem nil to delete
            }
            // for all other calls, assume the server/connection is broken and will be fixed later
            else {
                // update retry parameters
                NSDate *newSendDate = [NSDate date];
                
                [self appendOrIncrementRetryCount:&trackingUrl sendDate:&newSendDate];
                
                newFirstItem = [NSMutableDictionary dictionaryWithDictionary:request];
                newFirstItem[TUNE_KEY_URL] = trackingUrl;
                newFirstItem[TUNE_KEY_RUN_DATE] = @([newSendDate timeIntervalSince1970]);
            }
            
            // pop or replace event from queue
            @synchronized(self) {
                NSUInteger index = [self.events indexOfObject:request];
                
                if (index != NSNotFound) {
                    if (newFirstItem == nil) {
                        [self.events removeObjectAtIndex:index];
                    } else {
                        [self.events replaceObjectAtIndex:index withObject:newFirstItem];
                    }
                }
                
                [self saveQueue];
            }
            
            // send next
            [self performSelectorOnMainThread:@selector(dumpQueue) withObject:nil waitUntilDone:NO];
        };
        
#if TESTING
        // when testing network errors, skip request and force error response
        if(self.forceError) {
            NSError *error = [NSError errorWithDomain:@"TuneTest" code:self.forcedErrorCode userInfo:nil];
            
            handlerBlock(nil, nil, error);
            return;
        }
#endif
        NSHTTPURLResponse *urlResp = nil;
        NSError *error = nil;
        NSData *data = [TuneHttpUtils sendSynchronousRequest:urlReq response:&urlResp error:&error];
        
        if (error != nil) {
            if ([self.delegate respondsToSelector:@selector(queueRequestDidFailWithError:request:response:)]) {
                [self.delegate queueRequestDidFailWithError:error request:fullRequestString response:urlResp.debugDescription];
            }
            urlResp = nil; // set response to nil to make sure that the request is retried
        }
        
        handlerBlock(data, urlResp, error);
    }];
}

/*!
 Fires each enqueued event until the queue is emptied. Fires the next event only when the previous event request has finished.
 */
- (void)dumpQueue {
    [self.requestOpQueue addOperationWithBlock:^{
        if( ![TuneNetworkUtils isNetworkReachable] ) return;
        
        // get first request
        NSMutableDictionary *request = nil;
        @synchronized(self) {
            if( [self.events count] < 1 ) return;
            request = self.events[0];
        }
        
        // sleep until fire date
        NSDate *runDate = [NSDate dateWithTimeIntervalSince1970:[request[TUNE_KEY_RUN_DATE] doubleValue]];
        if( [runDate isKindOfClass:[NSDate class]] ) {
            [NSThread sleepUntilDate:runDate];
        }
        
        @synchronized(self) {
            request[TUNE_KEY_NETWORK_REQUEST_PENDING] = @(YES);
        }
        
        // fire URL request synchronously
        NSString *trackingLink = request[TUNE_KEY_URL];
        NSString *encryptParams = request[TUNE_KEY_DATA];
        id postJsonStringOrDict = request[TUNE_KEY_JSON];
        NSString *refUrl = request[TUNE_KEY_REFERRAL_URL];
        NSString *refSource = request[TUNE_KEY_REFERRAL_SOURCE];
        
        NSString *fullRequestString = [self updateTrackingLink:trackingLink encryptParams:encryptParams referralUrl:refUrl referralSource:refSource];
        
        NSData *postData = nil;
        
        // handle post data json string from SDK versions <= 4.9.1
        if ([postJsonStringOrDict isKindOfClass:[NSString class]]) {
            postData = [postJsonStringOrDict dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([postJsonStringOrDict isKindOfClass:[NSDictionary class]]) {
            postData = [TuneUtils jsonSerializedDataForObject:postJsonStringOrDict];
        }
        
#if TESTING
        // for testing, attempt informing the delegate's delegate of the trackingLink
        if (self.unitTestCallback) {
            NSString *postStr = nil;
            
            if ([postJsonStringOrDict isKindOfClass:[NSString class]]) {
                postStr = postJsonStringOrDict;
            } else if (postData) {
                postStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
            }
            
            self.unitTestCallback(fullRequestString, postStr);
        }
#endif
        NSURL *reqUrl = [NSURL URLWithString:fullRequestString];
        NSMutableURLRequest *urlReq = [NSMutableURLRequest requestWithURL:reqUrl
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
#if TESTING
        // These calls require the URL to be a GET
        if ([fullRequestString rangeOfString:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode"].location != NSNotFound) {
            [urlReq setHTTPMethod:TuneHttpRequestMethodTypeGet];
        } else {
            [urlReq setHTTPMethod:TuneHttpRequestMethodTypePost];
        }
#else
        [urlReq setHTTPMethod:TuneHttpRequestMethodTypePost];
#endif
        [urlReq setValue:TUNE_HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:TUNE_HTTP_CONTENT_TYPE];
        [urlReq setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:TUNE_HTTP_CONTENT_LENGTH];
        [urlReq setHTTPBody:postData];
        
        void (^handlerBlock)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable) =
        ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse *urlResp = (NSHTTPURLResponse *)response;
            NSString *trackingUrl = request[TUNE_KEY_URL];
            
            NSInteger code = 0;
            if (error != nil) {
                if ([self.delegate respondsToSelector:@selector(queueRequestDidFailWithError:request:response:)]) {
                    [self.delegate queueRequestDidFailWithError:error request:fullRequestString response:response.debugDescription];
                }
                
                urlResp = nil; // set response to nil and make sure that the request is retried
            }
            
#if TESTING
            // when testing network errors, use forced error code
            if (self.forceError) {
                code = self.forcedErrorCode;
            }
            else
#endif
                code = [urlResp statusCode];
            NSDictionary *headers = [urlResp allHeaderFields];
            NSMutableDictionary *newFirstItem = nil;
            
            // if the network request was successful, great
            if (code >= 200 && code <= 299) {
                if ([self.delegate respondsToSelector:@selector(queueRequest:didSucceedWithData:)]) {
                    [self.delegate queueRequest:fullRequestString didSucceedWithData:data];
                }
                // leave newFirstItem nil to delete
            }
            // for HTTP 400, if it's from our server, drop the request and don't retry
            else if ( code == 400 && headers[@"X-MAT-Responder"] != nil ) {
                if ([self.delegate respondsToSelector:@selector(queueRequestDidFailWithError:request:response:)]) {
                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedFailureReasonErrorKey] = @"Bad Request";
                    userInfo[NSLocalizedDescriptionKey] = @"HTTP 400/Bad Request received from Tune server";
                    userInfo[NSURLErrorKey] = reqUrl;
                    
                    // use setValue:forKey: to handle nil error object
                    [userInfo setValue:error forKey:NSUnderlyingErrorKey];
                    
                    NSError *e = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                     code:TUNE_REQUEST_400_ERROR_CODE
                                                 userInfo:userInfo];
                    [self.delegate queueRequestDidFailWithError:e request:fullRequestString response:response.debugDescription];
                }
                // leave newFirstItem nil to delete
            }
            // for all other calls, assume the server/connection is broken and will be fixed later
            else {
                // update retry parameters
                NSDate *newSendDate = [NSDate date];
                
                [self appendOrIncrementRetryCount:&trackingUrl sendDate:&newSendDate];
                
                newFirstItem = [NSMutableDictionary dictionaryWithDictionary:request];
                newFirstItem[TUNE_KEY_URL] = trackingUrl;
                newFirstItem[TUNE_KEY_RUN_DATE] = @([newSendDate timeIntervalSince1970]);
            }
            
            // pop or replace event from queue
            @synchronized(self) {
                NSUInteger index = [self.events indexOfObject:request];
                
                if (index != NSNotFound) {
                    if (newFirstItem == nil) {
                        [self.events removeObjectAtIndex:index];
                    } else {
                        [self.events replaceObjectAtIndex:index withObject:newFirstItem];
                    }
                }
                
                [self saveQueue];
            }
            
            // send next
            [self performSelectorOnMainThread:@selector(dumpQueue) withObject:nil waitUntilDone:NO];
        };
        
#if TESTING
        // when testing network errors, skip request and force error response
        if(self.forceError) {
            NSError *error = [NSError errorWithDomain:@"TuneTest" code:self.forcedErrorCode userInfo:nil];
            
            handlerBlock(nil, nil, error);
            return;
        }
#endif
        NSHTTPURLResponse *urlResp = nil;
        NSError *error = nil;
        NSData *data = [TuneHttpUtils sendSynchronousRequest:urlReq response:&urlResp error:&error];
        
        if (error != nil) {            
            if ([self.delegate respondsToSelector:@selector(queueRequestDidFailWithError:request:response:)]) {
                [self.delegate queueRequestDidFailWithError:error request:fullRequestString response:urlResp.debugDescription];
            }
            urlResp = nil; // set response to nil to make sure that the request is retried
        }
        
        handlerBlock(data, urlResp, error);
    }];
}


#pragma mark - Queue storage

/*! Reads file from disk, deserializes and refills the network request queue.
 
 Note: Calls to loadQueue should be wrapped in @synchronized(self){}
 */
- (void)loadQueue {
    self.events = [NSMutableArray array];
    
    NSString *path = [self.storageDir stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FILENAME];
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:path] )
        return;
    
    NSError *error = nil;
    NSData *serializedQueue = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if( error != nil ) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error reading event queue from file: %@", error];
        [TuneLog.shared logError:errorMessage];
        return;
    }
    
    id queue = [NSJSONSerialization JSONObjectWithData:serializedQueue options:0 error:&error];
    if( error != nil ) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error deserializing event queue from storage: %@", error];
        [TuneLog.shared logError:errorMessage];
        return;
    }
    
    if( ![queue isKindOfClass:[NSArray class]] ) {
        NSString *errorMessage = [NSString stringWithFormat:@"Unexpected data type %@ read from storage", [queue class]];
        [TuneLog.shared logError:errorMessage];
        return;
    }
    
    for( id item in (NSArray*)queue ) {
        if( ![item isKindOfClass:[NSDictionary class]] ) {
            NSString *errorMessage = [NSString stringWithFormat:@"Unexpected data type %@ in array read from storage", [item class]];
            [TuneLog.shared logError:errorMessage];
            return;
        }
    }
    
    for (NSDictionary *dict in queue) {
        [self.events addObject:[NSMutableDictionary dictionaryWithDictionary:dict]];
    }
}

/*! Serializes and saves the existing network request queue to disk.
 
 Note: Calls to saveQueue should be wrapped in @synchronized(eventLock){}
 */
- (void)saveQueue {
    if (!self.events) {
        return;
    }
    
    NSError *error = nil;
    NSData *serializedQueue = [NSJSONSerialization dataWithJSONObject:self.events options:0 error:&error];
    if( error != nil ) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error serializing event queue for storage: %@", error];
        [TuneLog.shared logError:errorMessage];
        return;
    }
    
    NSString *path = [self.storageDir stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FILENAME];
    if( ![serializedQueue writeToFile:path atomically:YES] ) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error writing event queue to file: %@", error];
        [TuneLog.shared logError:errorMessage];
        return;
    }
}


#pragma mark - Testing Helper Methods

#if TESTING

+ (void)resetSharedQueue {
    sharedQueueOnceToken = 0;
}
     
- (void)waitUntilAllOperationsAreFinishedOnQueue {
    [self.requestOpQueue waitUntilAllOperationsAreFinished];
}

- (void)cancelAllOperationsOnQueue {
    [self.requestOpQueue cancelAllOperations];
}

- (NSDictionary *)eventAtIndex:(NSUInteger)index {
    @synchronized(self) {
        return [self.events objectAtIndex:index];
    }
}

- (NSUInteger)queueSize {
    @synchronized(self) {
        return [self.events count];
    }
}

- (void)drainQueue {
    @synchronized(self) {
        [self.events removeAllObjects];
        
        [self saveQueue];
    }
    [self cancelAllOperationsOnQueue];
}

- (void)setForceNetworkError:(BOOL)isError code:(NSInteger)code {
    self.forceError = isError;
    self.forcedErrorCode = isError ? code : 0;
}

#endif

@end
