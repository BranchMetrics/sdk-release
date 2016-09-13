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
#import "TuneManager.h"
#import "TuneNetworkUtils.h"
#import "TuneReachability.h"
#import "TuneRequestsQueue.h"
#import "TuneStringUtils.h"
#import "TuneUserAgentCollector.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneSkyhookCenter.h"
#import "TuneDeviceDetails.h"
#import "TuneUserProfile.h"


const NSTimeInterval TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL  = 60.;

static NSString* const TUNE_REQUEST_QUEUE_FOLDER            = @"MATqueue";
static NSString* const TUNE_REQUEST_QUEUE_FILENAME          = @"events.json";
static NSString* const TUNE_LEGACY_REQUEST_QUEUE_FOLDER     = @"queue";

static const NSInteger TUNE_REQUEST_400_ERROR_CODE          = 1302;

#if TESTING
//NOTE: We know, for the unit tests, a TuneDelegate may have this method
@protocol TuneDelegate
@optional

- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData;

@end
#endif

#pragma mark - Private variables

@interface TuneEventQueue() {
    /*!
     Shared NSOperationQueue.
     */
    NSOperationQueue *requestOpQueue;
    
    /*!
     List of queued events.
     */
    NSMutableArray *events;
    
    /*!
     Disk location of file used for storing serialized events.
     */
    NSString *storageDir;
}

@property (nonatomic, weak) id <TuneEventQueueDelegate> delegate;
@property (nonatomic, strong) NSObject *eventLock;

#if TESTING
@property (nonatomic, readonly) NSMutableArray *events;
@property (nonatomic, assign) BOOL forceError;
@property (nonatomic, assign) NSInteger forcedErrorCode;

- (void) saveQueue;
- (void) dumpQueue;
#endif

@end


/*!
 Shared singleton event queue object.
 */
static TuneEventQueue *sharedQueue = nil;


@implementation TuneEventQueue

#if TESTING
@synthesize events = events;
#endif


#pragma mark - Initialization

+ (void)initialize {
    sharedQueue = [TuneEventQueue new];
}

- (id)init {
    self = [super init];
    if( self ) {
        _eventLock = [[NSObject alloc] init];
        requestOpQueue = [NSOperationQueue new];
        requestOpQueue.maxConcurrentOperationCount = 1;
        
        [self addNetworkAndAppNotificationListeners];
        
        [self createQueueStorageDirectory];
        
        [self prependItemsFromLegacyQueue];
        
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
    // create queue storage directory
    
    NSSearchPathDirectory queueParentFolder = NSDocumentDirectory;
#if TARGET_OS_TV // || TARGET_OS_WATCH
    queueParentFolder = NSCachesDirectory;
#endif
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(queueParentFolder, NSUserDomainMask, YES);
    NSString *baseFolder = [paths objectAtIndex:0];
    storageDir = [baseFolder stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FOLDER];
    
    [TuneFileUtils createDirectory:storageDir];
}

/*!
 Reads disk file that may contain legacy request queue and prepends the items to the main event queue.
 */
- (void)prependItemsFromLegacyQueue {
    @synchronized(_eventLock) {
        [self loadQueue];
        
        // if a legacy queue exists
        if([TuneRequestsQueue exists]) {
            // load legacy queue items
            TuneRequestsQueue *legacyQueue = [TuneRequestsQueue new];
            [legacyQueue load];
            
            NSDictionary *item = [legacyQueue pop];
            NSMutableArray *legacyItems = [NSMutableArray array];
            
            while( item != nil ) {
                [legacyItems addObject:item];
                item = [legacyQueue pop];
            }
            
            // prepend legacy items
            if( [legacyItems count] > 0 ) {
                for( item in [legacyItems reverseObjectEnumerator] )
                    [events insertObject:[NSMutableDictionary dictionaryWithDictionary:item] atIndex:0];
                [self saveQueue];
            }
            
            // permanently delete legacy queue file
            [legacyQueue closedown];
        }
    }
}

+ (void)setDelegate:(id<TuneEventQueueDelegate>)delegate {
    sharedQueue.delegate = delegate;
}

#pragma mark - Notification Handlers

- (void)networkChangeHandler:(TuneSkyhookPayload *)payload {
    [self dumpQueue];
}

#pragma mark - Request handling

+ (void)enqueueUrlRequest:(NSString*)trackingLink
              eventAction:(NSString*)actionName
            encryptParams:(NSString*)encryptParams
                 postData:(NSString*)postData
                  runDate:(NSDate*)runDate {
    [sharedQueue enqueueUrlRequest:trackingLink eventAction:actionName encryptParams:encryptParams postData:postData runDate:runDate];
}

- (void)enqueueUrlRequest:(NSString*)trackingLink
              eventAction:(NSString*)actionName
            encryptParams:(NSString*)encryptParams
                 postData:(NSString*)postData
                  runDate:(NSDate*)runDate {
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
    
    @synchronized(_eventLock) {
        [events addObject:item];
        
        [self saveQueue];
    }
    
    [self dumpQueue];
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
        *sendDate = [*sendDate dateByAddingTimeInterval:[[self class] retryDelayForAttempt:retryCount]];
    }
}

+ (void)updateEnqueuedEventsWithReferralUrl:(NSString *)url referralSource:(NSString *)bundleId {
    [sharedQueue updateEnqueuedEventsWithReferralUrl:url referralSource:bundleId];
}

- (void)updateEnqueuedEventsWithReferralUrl:(NSString *)url referralSource:(NSString *)bundleId {
    @synchronized(_eventLock) {
        // start updating events from the end of queue
        for (long i = events.count - 1; i >= 0; --i) {
            NSMutableDictionary *dictEvent = events[i];
            
            [dictEvent setValue:url forKey:TUNE_KEY_REFERRAL_URL];
            [dictEvent setValue:bundleId forKey:TUNE_KEY_REFERRAL_SOURCE];
            
            // do not update events that were fired before the last "session" request
            if([dictEvent[TUNE_KEY_ACTION] isEqualToString:TUNE_EVENT_SESSION]) {
                break;
            }
        }
        
        [self saveQueue];
    }
}

+ (NSTimeInterval)retryDelayForAttempt:(NSInteger)attempt {
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
            NSString *encodedUserAgent = [TuneUtils urlEncodeQueryParamValue:[TuneUserAgentCollector userAgent]];
            if (encodedUserAgent) {
                encryptParams = [encryptParams stringByAppendingFormat:@"&%@=%@", TUNE_KEY_CONVERSION_USER_AGENT, encodedUserAgent];
            }
        }
        
        // if the request url does not contain device location params, auto-collection
        // is enabled and location access is permitted, then try to auto-collect
        searchString = [NSString stringWithFormat:@"%@=", TUNE_KEY_LATITUDE];
        
        if( [encryptParams rangeOfString:searchString].location == NSNotFound
           && [TuneManager currentManager].configuration.shouldAutoCollectDeviceLocation
           && [TuneLocationHelper isLocationEnabled] ) {
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
        encryptedData = 0 == [encryptedData length] ? @"encryption_failed_no_data_included" : encryptedData;
        if (0 == [encryptedData length]) {
            NSLog(@"Tune: encryption failed: key = %@, data = %@", [self.delegate encryptionKey], encryptParams);
        }
        
        trackingLink = [trackingLink stringByAppendingFormat:@"&%@=%@", TUNE_KEY_DATA, encryptedData];
    }
    
    return trackingLink;
}

/*!
 Fires each enqueued event until the queue is emptied. Fires the next event only when the previous event request has finished.
 */
- (void)dumpQueue {
    if( ![TuneNetworkUtils isNetworkReachable] ) return;
    
    [requestOpQueue addOperationWithBlock:^{
        // get first request
        NSDictionary *request = nil;
        @synchronized(_eventLock) {
            if( [events count] < 1 ) return;
            request = events[0];
        }
        
        // sleep until fire date
        NSDate *runDate = [NSDate dateWithTimeIntervalSince1970:[request[TUNE_KEY_RUN_DATE] doubleValue]];
        if( [runDate isKindOfClass:[NSDate class]] ) {
            [NSThread sleepUntilDate:runDate];
        }
        
        // fire URL request synchronously
        NSString *trackingLink = request[TUNE_KEY_URL];
        NSString *encryptParams = request[TUNE_KEY_DATA];
        NSString *postData = request[TUNE_KEY_JSON];
        NSString *refUrl = request[TUNE_KEY_REFERRAL_URL];
        NSString *refSource = request[TUNE_KEY_REFERRAL_SOURCE];
        
        NSString *fullRequestString = [self updateTrackingLink:trackingLink encryptParams:encryptParams referralUrl:refUrl referralSource:refSource];
        
#if DEBUG
        // for testing, attempt informing the delegate's delegate of the trackingLink
        if( [self.delegate respondsToSelector:@selector(delegate)] ) {
            id ddelegate = [self.delegate performSelector:@selector(delegate)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            if( [ddelegate respondsToSelector:@selector(_tuneSuperSecretURLTestingCallbackWithURLString:andPostDataString:)] )
                [ddelegate performSelector:@selector(_tuneSuperSecretURLTestingCallbackWithURLString:andPostDataString:) withObject:fullRequestString withObject:postData];
#pragma clang diagnostic pop
        }
#endif
        NSURL *reqUrl = [NSURL URLWithString:fullRequestString];
        NSMutableURLRequest *urlReq = [NSMutableURLRequest requestWithURL:reqUrl
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
        NSData *post = [postData dataUsingEncoding:NSUTF8StringEncoding];
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
        [urlReq setValue:[NSString stringWithFormat:@"%lu", (unsigned long)post.length] forHTTPHeaderField:TUNE_HTTP_CONTENT_LENGTH];
        [urlReq setHTTPBody:post];
        
#if IDE_XCODE_7_OR_HIGHER
        void (^handlerBlock)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable) =
        ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
#else
        void (^handlerBlock)(NSData *, NSURLResponse *, NSError *) =
        ^(NSData * data, NSURLResponse * response, NSError * error) {
#endif
            NSHTTPURLResponse *urlResp = (NSHTTPURLResponse *)response;
            NSString *trackingUrl = request[TUNE_KEY_URL];
            
            NSInteger code = 0;
            if (error != nil) {
                DLLog(@"TuneEventQueue: dumpQueue: error code = %d", (int)error.code);
                
                if ([_delegate respondsToSelector:@selector(queueRequestDidFailWithError:)]) {
                    [_delegate queueRequestDidFailWithError:error];
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
                if ([_delegate respondsToSelector:@selector(queueRequestDidSucceedWithData:)]) {
                    [_delegate queueRequestDidSucceedWithData:data];
                }
                // leave newFirstItem nil to delete
            }
            // for HTTP 400, if it's from our server, drop the request and don't retry
            else if ( code == 400 && headers[@"X-MAT-Responder"] != nil ) {
                if ([_delegate respondsToSelector:@selector(queueRequestDidFailWithError:)]) {
                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedFailureReasonErrorKey] = @"Bad Request";
                    userInfo[NSLocalizedDescriptionKey] = @"HTTP 400/Bad Request received from Tune server";
                    userInfo[NSURLErrorKey] = reqUrl;
                    
                    // use setValue:forKey: to handle nil error object
                    [userInfo setValue:error forKey:NSUnderlyingErrorKey];
                    
                    NSError *e = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                     code:TUNE_REQUEST_400_ERROR_CODE
                                                 userInfo:userInfo];
                    [_delegate queueRequestDidFailWithError:e];
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
            @synchronized(_eventLock) {
                NSUInteger index = [events indexOfObject:request];
                
                if (index != NSNotFound) {
                    if (newFirstItem == nil) {
                        [events removeObjectAtIndex:index];
                    } else {
                        [events replaceObjectAtIndex:index withObject:newFirstItem];
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
            DLLog(@"TuneEventQueue: dumpQueue: error code = %d", (int)error.code);
            
            if ([_delegate respondsToSelector:@selector(queueRequestDidFailWithError:)]) {
                [_delegate queueRequestDidFailWithError:error];
            }
            urlResp = nil; // set response to nil to make sure that the request is retried
        }
        
        handlerBlock(data, urlResp, error);
    }];
}


#pragma mark - Queue storage

/*! Reads file from disk, deserializes and refills the network request queue.
 
 Note: Calls to loadQueue should be wrapped in @synchronized(_eventLock){}
 */
- (void)loadQueue {
    events = [NSMutableArray array];
    
    NSString *path = [storageDir stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FILENAME];
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:path] )
        return;
    
    NSError *error = nil;
    NSData *serializedQueue = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if( error != nil ) {
        ErrorLog( @"Error reading event queue from file: %@", error );
        return;
    }
    
    id queue = [NSJSONSerialization JSONObjectWithData:serializedQueue options:0 error:&error];
    if( error != nil ) {
        ErrorLog( @"Error deserializing event queue from storage: %@", error );
        return;
    }
    
    if( ![queue isKindOfClass:[NSArray class]] ) {
        ErrorLog( @"Unexpected data type %@ read from storage", [queue class] );
        return;
    }
    
    for( id item in (NSArray*)queue ) {
        if( ![item isKindOfClass:[NSDictionary class]] ) {
            ErrorLog( @"Unexpected data type %@ in array read from storage", [item class] );
            return;
        }
    }
    
    for (NSDictionary *dict in queue) {
        [events addObject:[NSMutableDictionary dictionaryWithDictionary:dict]];
    }
}

/*! Serializes and saves the existing network request queue to disk.
 
 Note: Calls to saveQueue should be wrapped in @synchronized(eventLock){}
 */
- (void)saveQueue {
    NSError *error = nil;
    NSData *serializedQueue = [NSJSONSerialization dataWithJSONObject:events options:0 error:&error];
    if( error != nil ) {
        ErrorLog( @"Error serializing event queue for storage: %@", error );
        return;
    }
    
    NSString *path = [storageDir stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FILENAME];
    if( ![serializedQueue writeToFile:path atomically:YES] ) {
        ErrorLog( @"Error writing event queue to file: %@", error );
        return;
    }
}


#pragma mark - Testing Helper Methods

#if TESTING

- (void)waitUntilAllOperationsAreFinishedOnQueue {
    [requestOpQueue waitUntilAllOperationsAreFinished];
}

- (void)cancelAllOperationsOnQueue {
    [requestOpQueue cancelAllOperations];
}

+ (void)resetSharedInstance {
    sharedQueue = [TuneEventQueue new];
}

+ (instancetype)sharedInstance {
    return sharedQueue;
}

+ (NSMutableArray *)events {
    @synchronized(sharedQueue.eventLock) {
        return sharedQueue.events;
    }
}

+ (NSDictionary *)eventAtIndex:(NSUInteger)index {
    @synchronized(sharedQueue.eventLock) {
        return [sharedQueue.events objectAtIndex:index];
    }
}

+ (NSUInteger)queueSize {
    @synchronized(sharedQueue.eventLock) {
        return [sharedQueue.events count];
    }
}

+ (void)drainQueue {
    @synchronized(sharedQueue.eventLock) {
        [sharedQueue.events removeAllObjects];
        
        [sharedQueue saveQueue];
    }
    [sharedQueue cancelAllOperationsOnQueue];
}

+ (void)dumpQueue {
    [sharedQueue dumpQueue];
}

+ (void)setForceNetworkError:(BOOL)isError code:(NSInteger)code {
    sharedQueue.forceError = isError;
    sharedQueue.forcedErrorCode = isError ? code : 0;
}

#endif

@end
