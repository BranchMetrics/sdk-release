//
//  ConnectionManager.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATConnectionManager.h"
#import "MATKeyStrings.h"
#import "MATUtils.h"
#import "MATEncrypter.h"

int const MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL = 60;

/********* MNSURLConnection interface ********/
@interface MNSURLConnection : NSURLConnection
{
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *postData;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, assign) BOOL isAppToApp;
@property (nonatomic, assign) SEL delegateSuccessSelector, delegateFailureSelector;
@property (nonatomic, retain) id delegateTarget;
@property (nonatomic, retain) id delegateArgument;

@end

/********* MNSURLConnection implementation ********/

@implementation MNSURLConnection

@synthesize url, postData;
@synthesize responseData;
@synthesize isAppToApp;
@synthesize delegateTarget;
@synthesize delegateArgument;
@synthesize delegateSuccessSelector;
@synthesize delegateFailureSelector;

@end


/********* MATConnectionManager private interface ********/

@interface MATConnectionManager()

@property (nonatomic, retain) MATReachability * reachability;
@property (assign) BOOL dumpingQueue;
@property (assign) NSUInteger dumpTriesFailures;

- (void)dumpQueue;
- (void)dumpNextFromQueue;
- (void)stopQueueDump;

- (void)handleNetworkChange:(NSNotification *)notice;

@end

/********* MATConnectionManager implementation ********/

@implementation MATConnectionManager

@synthesize requestsQueue = requestsQueue_;
@synthesize reachability = reachability_;
@synthesize status = status_;
@synthesize dumpingQueue = dumpingQueue_;
@synthesize dumpTriesFailures = dumpTriesFailures_;
@synthesize shouldDebug = _shouldDebug;
@synthesize delegate = _delegate;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        requestsQueue_ = [[MATRequestsQueue alloc] init];

        queueQueue = [NSOperationQueue new];
        queueQueue.maxConcurrentOperationCount = 1;
        
        // TODO: Consider calling this method on a background thread.
        // Also, call other dependent methods after this method finishes.
        [self.requestsQueue load];
        
        DLog(@"MATConnManager: init(): requestsQueue = %@", requestsQueue_);
        
        /// Initialize Reachability
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNetworkChange:)
                                                     name:kMATReachabilityChangedNotification
                                                   object:nil];
        
        // When the app becomes active, fire the requests stored in the request queue.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNetworkChange:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        self.reachability = [MATReachability reachabilityForInternetConnection];
        
        DLog(@"MATConnManager: init(): reachability = %@", self.reachability);
        
        [self.reachability startNotifier];
        self.status = [self.reachability currentReachabilityStatus];
        
        [self dumpQueue];
    }
    
    return self;
}

- (void)dealloc
{
    // Note: Being a Singleton class, dealloc should never get called, but just here for clarity.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMATReachabilityChangedNotification object:nil];
    
    // stop observing app-did-become-active notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    DLog(@"MATConnManager: dealloc: stop reachability notifier: self = %@, self.reachability = %@", self, self.reachability);
    
    // stop observing network reachability notifications
    self.reachability = nil;
    
    // store pending requests to file
    [self.requestsQueue save];
    requestsQueue_ = nil;
}

#pragma mark - Reachability Notification

- (void)handleNetworkChange:(NSNotification *)notice
{
    DLog(@"MATConnManager: handleNetworkChange: notice = %@", notice);
    DLog(@"MATConnManager: handleNetworkChange: reachability status = %ld", (long)self.reachability.currentReachabilityStatus);
    
    self.status = [self.reachability currentReachabilityStatus];
    
    [self dumpQueue];
}


#pragma mark - Network Request Methods

- (void)beginRequestGetTrackingId:(NSString *)trackingLink
               withDelegateTarget:(id)target
              withSuccessSelector:(SEL)selectorSuccess
              withFailureSelector:(SEL)selectorFailure
                     withArgument:(NSMutableDictionary *)dict
{
    //https://engine.mobileapptracking.com/serve?action=click&publisher_advertiser_id=1587&package_name=com.HasOffers.matsdktestapp&response_format=json
    
    // ignore the request if the network is not reachable
    if(NotReachable != self.status)
    {
        DLLog(@"MATConnManager: beginRequestGetTrackingId: %@", trackingLink);
        
        NSURL * url = [NSURL URLWithString:trackingLink];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
        MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        connection.url = url;
        connection.postData = STRING_EMPTY;
        
        // create a flag for app to app tracking request
        connection.isAppToApp = YES;
        connection.responseData = [NSMutableData data];
        
        connection.delegateTarget = target;
        connection.delegateSuccessSelector = selectorSuccess;
        connection.delegateFailureSelector = selectorFailure;
        connection.delegateArgument = dict;
        
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [connection start];
    }
}


- (void)beginUrlRequest:(NSString *)trackingLink encryptParams:(NSString*)encryptParams withPOSTData:(NSString*)postData
{
    trackingLink = [self updateTrackingLink:trackingLink encryptParams:encryptParams];
    
#if DEBUG_REQUEST_LOG
    NSRange range = [trackingLink rangeOfString:[NSString stringWithFormat:@"&%@=", KEY_DATA]];
    range.length = [trackingLink length] - range.location;
    NSString * debugString = [trackingLink stringByReplacingCharactersInRange:range withString:STRING_EMPTY];
    NSLog(@"MATConnManager: beginUrlRequest: URL: %@", debugString);
    NSLog(@"MATConnManager: beginUrlRequest: post data = %@", postData);
#endif
    DLLog(@"MATConnManager: beginUrlRequest: URL trackingLink = %@", trackingLink);
    
#if DEBUG
    // for testing, attempt informing the delegate's delegate of the trackingLink
    if( [self.delegate respondsToSelector:@selector(delegate)] ) {
        id ddelegate = [self.delegate performSelector:@selector(delegate)];
        if( [ddelegate respondsToSelector:@selector(_matSuperSecretURLTestingCallbackWithURLString:andPostDataString:)] )
            [ddelegate performSelector:@selector(_matSuperSecretURLTestingCallbackWithURLString:andPostDataString:) withObject:trackingLink withObject:postData];
    }
#endif
    
    NSURL * url = [NSURL URLWithString:trackingLink];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
    
    [request setHTTPMethod:HTTP_METHOD_POST];
    [request setValue:HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:HTTP_CONTENT_TYPE];
    
    NSData *post = [postData dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:post];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)post.length] forHTTPHeaderField:HTTP_CONTENT_LENGTH];
    
    DLog(@"MATConnManager: beginUrlRequest: fire the network request.");
    
    MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request
                                                                     delegate:self
                                                             startImmediately:NO];
    connection.url = url;
    connection.postData = postData;
    connection.responseData = [NSMutableData data];
    
    [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [connection start];
}


- (NSString*)updateTrackingLink:(NSString*)trackingLink encryptParams:(NSString*)encryptParams
{
    if( encryptParams != nil ) {
        // if iad_attribution, append/overwrite current status
        NSString *searchString = [NSString stringWithFormat:@"%@=0", KEY_IAD_ATTRIBUTION];
        if( [encryptParams rangeOfString:searchString].location != NSNotFound &&
           [self.delegate isiAdAttribution] )
        {
            NSString *replaceString = [NSString stringWithFormat:@"%@=1", KEY_IAD_ATTRIBUTION];
            encryptParams = [encryptParams stringByReplacingOccurrencesOfString:searchString withString:replaceString];
        }
        else if( [self.delegate isiAdAttribution] )
            encryptParams = [encryptParams stringByAppendingFormat:@"&%@=1", KEY_IAD_ATTRIBUTION];
        
        // append user agent, if not present
        searchString = [NSString stringWithFormat:@"%@=", KEY_CONVERSION_USER_AGENT];
        if( [encryptParams rangeOfString:searchString].location == NSNotFound )
            encryptParams = [encryptParams stringByAppendingFormat:@"&%@=%@", KEY_CONVERSION_USER_AGENT, [self.delegate userAgent]];

        // encrypt params and append
        NSString* encryptedData = [MATEncrypter encryptString:encryptParams withKey:[self.delegate encryptionKey]];
        trackingLink = [trackingLink stringByAppendingFormat:@"&%@=%@", KEY_DATA, encryptedData];
    }
    
    // append other params
    if (self.shouldDebug && [trackingLink rangeOfString:[NSString stringWithFormat:@"&%@=", KEY_DEBUG]].location == NSNotFound)
        trackingLink = [trackingLink stringByAppendingFormat:@"&%@=1", KEY_DEBUG];
    
    if (self.shouldAllowDuplicates && [trackingLink rangeOfString:[NSString stringWithFormat:@"&%@=", KEY_SKIP_DUP]].location == NSNotFound)
        trackingLink = [trackingLink stringByAppendingFormat:@"&%@=1", KEY_SKIP_DUP];

#if DEBUG
    NSString *searchString = @"&bypass_throttling=1";
    if( [trackingLink rangeOfString:searchString].location == NSNotFound )
        trackingLink = [trackingLink stringByAppendingString:searchString];
#endif
    
    return trackingLink;
}


#pragma mark - Request Queue Helper Methods

- (void)dumpQueue
{
    DLog(@"MATConnManager: dumpQueue is already dumping queue = %d", dumpingQueue_);
    
    if( dumpingQueue_ ) return;
    if (NotReachable == self.status) return;

    DLLog(@"MATConnManager: dumpQueue %@", self.requestsQueue );
    
    dumpingQueue_ = YES;
    dumpTriesFailures_ = 0;
    
    // fire the first request from the queue
    [self dumpNextFromQueue];
}

- (void)dumpNextFromQueue
{
    [queueQueue addOperationWithBlock:^{
        if( NotReachable == self.status )
            [self stopQueueDump];
        if( !dumpingQueue_ ) return;

        // retrieve next request item from storage queue
        NSDictionary * dict = [requestsQueue_ pop];
        DLLog(@"MATConnManager: dumpNextFromQueue %@", dict);
        
        // if a stored request is found
        if (dict)
        {
            // if stored runDate is later than now, block until that time
            NSDate *runDate = dict[KEY_RUN_DATE];
            if( [runDate isKindOfClass:[NSDate class]] ) {
                [NSThread sleepUntilDate:runDate];
            }
            
            DLLog(@"MATConnManager: dumpNextFromQueue calling beginUrlRequest: %@", [NSDate date]);
            
            // fire web request
            [self beginUrlRequest:[dict valueForKey:KEY_URL]
                    encryptParams:[dict valueForKey:KEY_DATA]
                     withPOSTData:[dict valueForKey:KEY_JSON]];
            
            // store request queue to file
            [requestsQueue_ save];
        }
        else
        {
            // the stored request queue is empty, so stop
            [self stopQueueDump];
        }
    }];
}

- (void)stopQueueDump
{
    DLLog(@"MATConnManager: stopQueueDump");
    
    dumpingQueue_ = NO;
}


- (NSDate*)nextRetryDateForAttempt:(NSInteger)attempt
{
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
    
    return [NSDate dateWithTimeIntervalSinceNow:(1 + 0.1*drand48())*delay];
}


- (void)pushUrlRequestToHead:(NSString*)trackingLink
                    POSTData:(NSString*)postData
{
    // update retry attempt count
    NSInteger retryCount = 0;
    NSString *searchString = [NSString stringWithFormat:@"&%@=", KEY_RETRY_COUNT];
    NSRange searchResult = [trackingLink rangeOfString:searchString];
    if( searchResult.location == NSNotFound ) {
        trackingLink = [trackingLink stringByAppendingFormat:@"%@0", searchString];
    }
    else {
        // parse number, increment it, replace it
        NSString *countString = [trackingLink substringFromIndex:searchResult.location + searchResult.length];
        retryCount = [countString integerValue];
        NSUInteger valueLength = MAX(1, (int)(log10(retryCount)+1)); // count digits
        retryCount++;
        trackingLink = [NSString stringWithFormat:@"%@%ld%@",
                        [trackingLink substringToIndex:searchResult.location + searchResult.length],
                        (long)retryCount,
                        [trackingLink substringFromIndex:searchResult.location + searchResult.length + valueLength]];
    }
    
    // note that postData might be nil
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           [self nextRetryDateForAttempt:retryCount], KEY_RUN_DATE,
                           trackingLink, KEY_URL,
                           postData, KEY_JSON, nil];

    DLLog(@"MATConnManager: pushUrlRequestToHead %@", dict);

    [queueQueue addOperationWithBlock:^{
        [self.requestsQueue pushToHead:dict];
        [self.requestsQueue save];
    }];
    
    DLog(@"MATConnManager: pushUrlRequestToHead calling dumpQueue");
    // without this delay, we might dump before the queue is updated (race condition)
    // without running on a particular queue, the current runloop might stop during the delay
    dispatch_async( dispatch_get_main_queue(), ^{
        [self performSelector:@selector(dumpQueue) withObject:nil afterDelay:0.5];
    });
}

- (void)enqueueUrlRequest:(NSString*)trackingLink
            encryptParams:(NSString*)encryptParams
              andPOSTData:(NSString*)postData
                  runDate:(NSDate*)runDate
{
    // add retry attempt count, if not present
    NSString *searchString = [NSString stringWithFormat:@"&%@=", KEY_RETRY_COUNT];
    if( [trackingLink rangeOfString:searchString].location == NSNotFound ) {
        trackingLink = [trackingLink stringByAppendingFormat:@"%@0", searchString];
    }
    
    DLLog(@"MATConnManager: enqueueUrlRequest: trackingLink  = %@", trackingLink);

    // note that postData might be nil
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:runDate, KEY_RUN_DATE,
                           trackingLink, KEY_URL, encryptParams, KEY_DATA, postData, KEY_JSON, nil];
    DLLog(@"MATConnManager: enqueueUrlRequest: enqueuing dict = %@", dict);

    [queueQueue addOperationWithBlock:^{
        [self.requestsQueue push:dict];
        [self.requestsQueue save];
    }];

    // without a delay, we might dump before the queue is updated (race condition)
    // without running on a particular queue, the current runloop might stop during the delay
    dispatch_async( dispatch_get_main_queue(), ^{
        [self performSelector:@selector(dumpQueue) withObject:nil afterDelay:0.5];
    });
}


#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(MNSURLConnection *)connection didFailWithError:(NSError *)error
{
    // do not requeue failed request to fetch tracking id for app to app tracking
    if(connection.isAppToApp)
    {
        // suppress the memory leak warning -- we do not expect a memory leak since we are dealing with Class object and SEL.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if(connection.delegateFailureSelector &&
           [connection.delegateTarget respondsToSelector:connection.delegateFailureSelector])
        {
            [connection.delegateTarget performSelector:connection.delegateFailureSelector withObject:connection.delegateArgument withObject:error];
        }
#pragma clang diagnostic pop
    }
    else
    {
        DLLog(@"MATConnManager: connection:didFailWithError: error = %@", error);
        DLLog(@"MATConnManager: connection:didFailWithError: failed url = %@", connection.url.absoluteString);
        
        // Store to queue, so that the request may be fired when internet becomes available.
        [self pushUrlRequestToHead:connection.url.absoluteString POSTData:connection.postData];

        if([self.delegate respondsToSelector:@selector(connectionManager:didFailWithError:)])
        {
            [self.delegate connectionManager:self didFailWithError:error];
        }
    }
}

- (void)connection:(MNSURLConnection *)connection didReceiveData:(NSData *)data
{
#if DEBUG_REQUEST_LOG
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"MATConnManager: didReceiveData: connectionManager = %@", self);
    NSLog(@"MATConnManager: didReceiveData: size = %lu, %@", (unsigned long)data.length, dataString);
#endif
    
    [connection.responseData appendData:data];
    
#if DEBUG_REQUEST_LOG
    NSString *str = [[NSString alloc] initWithData:connection.responseData encoding:NSASCIIStringEncoding];
    NSLog(@"MATConnManager: didReceiveData: newCombinedData = %@", str);
#endif
}

- (void)connection:(MNSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#if DEBUG_REQUEST_LOG
    NSHTTPURLResponse* httpResponse1 = (NSHTTPURLResponse*)response;
    NSInteger code1 = [httpResponse1 statusCode];
    NSLog(@"MATConnManager: didReceiveResponse: connectionManager = %@", self);
    NSLog(@"MATConnManager: didReceiveResponse: http response code = %ld", (long)code1);
#endif
    if(!connection.isAppToApp)
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSInteger code = [httpResponse statusCode];
        NSDictionary *headers = [httpResponse allHeaderFields];
        
        // if the network request was successful, great
        if( code >= 200 && code <= 299 ) {
            self.dumpTriesFailures = 0;
            
            DRLog(@"MATConnManager: didReceiveResponse: previous request successful: call dumpNextFromQueue");
            
            // fire the next stored request
            [self dumpNextFromQueue];
        }
        // for HTTP 400, if it's from our server, drop the request and don't retry
        else if( code == 400 && headers[@"X-MAT-Responder"] != nil ) {
            DRLog(@"MATConnManager: didReceiveResponse: won't retry with 400 error" );
        }
        // for all other calls, assume the server/connection is broken and will be fixed later
        else {
            [self pushUrlRequestToHead:connection.url.absoluteString POSTData:connection.postData];
        }
    }
}

- (void)connectionDidFinishLoading:(MNSURLConnection *)connection
{
    DLog(@"MATConnManager: didFinishLoading: connectionManager = %@", self);

    DLLog(@"MATConnManager: didFinishLoading: url = %@", connection.url.absoluteString);

#if DEBUG_LOG
    NSString *dataString = [[NSString alloc] initWithData:connection.responseData encoding:NSASCIIStringEncoding];
    NSLog(@"========Server Response==========");
    NSLog(@"MATConnManager: didFinishLoading: %@", dataString);
#endif
    
    DLog(@"MATConnManager: didFinishLoading 2: connectionManager = %@", self);
    DLog(@"delegateTarget  = %@", NSStringFromClass(connection.delegateTarget));
    DLog(@"successSEL      = %@, responds = %d", NSStringFromSelector(connection.delegateSuccessSelector), [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector]);
    DLog(@"arg             = %@", connection.delegateArgument);
    DLog(@"call delegate   = %d", (connection.isAppToApp)
                                    && connection.delegateTarget
                                    && connection.delegateSuccessSelector
                                    && [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector]);
    
    if(connection.isAppToApp && connection.delegateSuccessSelector &&
       [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector])
    {
        if(!connection.delegateArgument)
        {
            connection.delegateArgument = [NSMutableDictionary dictionary];
        }
        [connection.delegateArgument setValue:connection.responseData forKey:KEY_SERVER_RESPONSE];
        
        DLog(@"MATConnManager: calling delegateTarget success selector: arg = %@", connection.delegateArgument);
        
        // suppress the memory leak warning -- we do not expect a memory leak since we are dealing with Class object and SEL.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [connection.delegateTarget performSelector:connection.delegateSuccessSelector withObject:connection.delegateArgument];
#pragma clang diagnostic pop
    }

    DLog(@"MATConnManager: calling delegate success callback: %d", (!connection.isAppToApp && [self.delegate respondsToSelector:@selector(connectionManager:didSucceedWithData:)]));
    
    if(!connection.isAppToApp && [self.delegate respondsToSelector:@selector(connectionManager:didSucceedWithData:)])
    {
        [self.delegate connectionManager:self didSucceedWithData:connection.responseData];
    }
}

#if DEBUG_STAGING

// allow self-signed certificates for internal testing on MAT Staging server
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#endif

@end
