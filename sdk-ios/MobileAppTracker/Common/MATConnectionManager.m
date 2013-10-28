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
#import "../MobileAppTracker.h"

static const NSUInteger MAX_QUEUE_DUMP_TRIES_FAILURES       =   5;

int const MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL = 60;

/********* MNSURLConnection interface ********/
@interface MNSURLConnection : NSURLConnection
{
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *postData;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, assign) BOOL isAppToApp, isInstallLogId;
@property (nonatomic, assign) SEL delegateSuccessSelector, delegateFailureSelector;
@property (nonatomic, retain) id delegateTarget;
@property (nonatomic, retain) id delegateArgument;

@end

/********* MNSURLConnection implementation ********/

@implementation MNSURLConnection

@synthesize url, postData;
@synthesize responseData;
@synthesize isAppToApp;
@synthesize isInstallLogId;
@synthesize delegateTarget;
@synthesize delegateArgument;
@synthesize delegateSuccessSelector;
@synthesize delegateFailureSelector;

-(void) dealloc
{
    [delegateTarget release], delegateTarget = nil;
    [delegateArgument release], delegateArgument = nil;
    
    [responseData release], responseData = nil;
    [url release], url = nil;
    [postData release], postData = nil;
    [super dealloc];
}

@end


/********* MATConnectionManager private interface ********/

static MATConnectionManager * instance__ = nil;

@interface MATConnectionManager()

@property (nonatomic, retain) MATRequestsQueue * requestsQueue;
@property (nonatomic, retain) MATReachability * reachability;
@property (assign) BOOL dumpingQueue;
@property (assign) NSUInteger dumpTriesFailures;

- (void)dumpQueue;
- (void)dumpNextFromQueue;
- (void)stopQueueDump;
- (void)enqueueNetworkRequestWithUrlString:(NSString *)urlString andPOSTData:(NSString *)postData;

- (void)beginUrlRequest:(NSString *)trackingLink andPOSTData:(NSString*)postData withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate storedRequest:(BOOL)isStoredRequest;

- (void)fireStoredRequests;

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
@synthesize shouldAllowDuplicates = _shouldAllowDuplicates;
@synthesize delegate = _delegate;

+ (MATConnectionManager*)sharedManager
{
    if (!instance__)
    {
        instance__ = [[MATConnectionManager alloc] init];
    }
    
    return instance__;
}

+ (void)destroyManager
{
    if (instance__)
    {
        [instance__ release]; instance__ = nil;
    }
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        requestsQueue_ = [[MATRequestsQueue alloc] init];
        
        // TODO: Consider calling this method on a background thread.
        // Also, call other dependent methods after this method finishes.
        [self.requestsQueue load];
        
        DLog(@"MATConnManager: init(): requestsQueue = %@", requestsQueue_);
        
        /// Initialize Reachability
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNetworkChange:)
                                                     name:kReachabilityChangedNotification
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
        
        [self fireStoredRequests];
    }
    
    return self;
}

- (void)dealloc
{
    // Note: Being a Singleton class, dealloc should never get called, but just here for clarity.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    // stop observing app-did-become-active notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    DLog(@"MATConnManager: dealloc: stop reachability notifier: self = %@, self.reachability = %@", self, self.reachability);
    
    // stop observing network reachability notifications
    self.reachability = nil;
    
    // store pending requests to file
    [self.requestsQueue save];
    [requestsQueue_ release], requestsQueue_ = nil;
    
    [super dealloc];
}

#pragma mark - Reachability Notification

- (void)handleNetworkChange:(NSNotification *)notice
{
    DLog(@"MATConnManager: handleNetworkChange: notice = %@", notice);
    DLog(@"MATConnManager: handleNetworkChange: reachability status = %d", self.reachability.currentReachabilityStatus);
	
    self.status = [self.reachability currentReachabilityStatus];
    
    [self fireStoredRequests];
}

- (void)fireStoredRequests
{
    // if network is available
    if (NotReachable != self.status)
    {
        DLog(@"MATConnManager: fireStoredRequests: calling dumpQueue");
        // fire the stored web requests
        [self dumpQueue];
    }
}

#pragma mark - Network Request Methods

- (void)beginRequestGetTrackingId:(NSString *)trackingLink
               withDelegateTarget:(id)target
              withSuccessSelector:(SEL)selectorSuccess
              withFailureSelector:(SEL)selectorFailure
                     withArgument:(NSMutableDictionary *)dict
                     withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    //https://engine.mobileapptracking.com/serve?action=click&publisher_advertiser_id=1587&package_name=com.HasOffers.matsdktestapp&response_format=json
    
    // ignore the request if the network is not reachable
    if(NotReachable != self.status)
    {
        self.delegate = connectionDelegate;
        
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
        [connection release];
    }
}

- (void)beginRequestGetInstallLogId:(NSString *)trackingLink
                 withDelegateTarget:(id)target
                withSuccessSelector:(SEL)selectorSuccess
                withFailureSelector:(SEL)selectorFailure
                       withArgument:(NSMutableDictionary *)dict
                       withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    // ignore the request if the network is not reachable
    if(NotReachable != self.status)
    {
        self.delegate = connectionDelegate;
        
        NSURL * url = [NSURL URLWithString:trackingLink];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
        DLLog(@"MATConnManager: beginRequestGetInstallLogId: This is the request URL2: %@", request.URL.absoluteString);
        
        MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        connection.url = url;
        connection.postData = STRING_EMPTY;
        
        // create a flag for get install log id request
        connection.isInstallLogId = YES;
        connection.responseData = [NSMutableData data];
        
        connection.delegateTarget = target;
        connection.delegateSuccessSelector = selectorSuccess;
        connection.delegateFailureSelector = selectorFailure;
        connection.delegateArgument = dict;
        
        DLLog(@"MATConnManager: beginRequestGetInstallLogId: connectionManager = %@", self);
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [connection start];
        [connection release];
    }
}

- (void)beginUrlRequest:(NSString *)trackingLink andPOSTData:(NSString*)postData withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    [self beginUrlRequest:trackingLink andPOSTData:postData withDelegate:connectionDelegate storedRequest:NO];
}

- (void)beginUrlRequest:(NSString *)trackingLink andPOSTData:(NSString*)postData withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate storedRequest:(BOOL)isStoredRequest
{
    self.delegate = connectionDelegate;
    
    // if it's a stored request, do not modify the request url
    if(!isStoredRequest)
    {
        // debug on or off
        if (self.shouldDebug)
        {
            DLog(@"MATConnManager: beginUrlRequest: debug mode");
        
            trackingLink = [trackingLink stringByAppendingFormat:@"&%@=1", KEY_DEBUG];
        }
    
        // duplicate installs/events/ref_ids allowed or not
        if (self.shouldAllowDuplicates)
        {
            DLog(@"MATConnManager: beginUrlRequest: allow duplicate requests");
            
            trackingLink = [trackingLink stringByAppendingFormat:@"&%@=1", KEY_SKIP_DUP];
        }
        
        // Append json format to the url
        // This in the future, can be overridden by developer
        trackingLink = [trackingLink stringByAppendingFormat:@"&%@=%@", KEY_RESPONSE_FORMAT, KEY_JSON];
    }
    
    // Fire a network request only if the internet is currently available, otherwise store the request for later.
    if(NotReachable == self.status)
    {
        DRLog(@"MATConnManager: beginUrlRequest: Network not reachable, store the request for now.");
        
        MobileAppTracker *mat = [MobileAppTracker sharedManager];
        
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:KEY_ERROR_MAT_NETWORK_NOT_REACHABLE forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"Network not reachable, request stored." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1201 userInfo:errorDetails];
        [mat performSelector:NSSelectorFromString(@"notifyDelegateFailureWithError:") withObject:error];
        
        // Store to queue, so that the request may be fired when internet becomes available.
        [self enqueueNetworkRequestWithUrlString:trackingLink andPOSTData:postData];
    }
    else
    {
        DLog(@"MATConnManager: beginUrlRequest: Network is reachable, continue with the network request.");
        
        NSURL * url = [NSURL URLWithString:trackingLink];
        
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
#if DEBUG_REQUEST_LOG
        NSRange range = [trackingLink rangeOfString:[NSString stringWithFormat:@"&%@=", KEY_DATA]];
        range.length = [trackingLink length] - range.location;
        NSString * debugString = [trackingLink stringByReplacingCharactersInRange:range withString:STRING_EMPTY];
        NSLog(@"MATConnManager: beginUrlRequest: URL: %@", debugString);
#endif
        
        DLLog(@"MATConnManager: beginUrlRequest: URL trackingLink = %@", trackingLink);
        
        DRLog(@"MATConnManager: beginUrlRequest: post data = %@", postData);
        
        request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:HTTP_METHOD_POST];
        [request setValue:HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:HTTP_CONTENT_TYPE];
        
        NSData *post = [postData dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:post];
        [request setValue:[NSString stringWithFormat:@"%d", post.length] forHTTPHeaderField:HTTP_CONTENT_LENGTH];
        
        DLog(@"MATConnManager: beginUrlRequest: fire the network request.");
        
        MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        connection.url = url;
        connection.postData = postData;
        connection.responseData = [NSMutableData data];
        
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [connection start];
        [connection release];
    }
}

#pragma mark - Request Queue Helper Methods

-(void)dumpQueue
{
    dumpingQueue_ = YES;
    dumpTriesFailures_ = 0;
    
    // fire the first request from the queue
    [self dumpNextFromQueue];
}

- (void)dumpNextFromQueue
{
    // retrieve next request item from storage queue
    NSDictionary * dict = [requestsQueue_ pop];
    
    DLog(@"MATConnManager: dumpNextFromQueue: %@", dict);
    
    // if a stored request is found
    if (dict)
    {
        // extract stored data
        NSString * trackingLink = [dict valueForKey:KEY_URL];
        NSString * json = [dict valueForKey:KEY_JSON];
        
        // fire web request
        [self beginUrlRequest:trackingLink andPOSTData:json withDelegate:self.delegate storedRequest:YES];
        
        // store request queue to file
        [requestsQueue_ save];
    }
    else
    {
        // the stored request queue is empty, so stop
        [self stopQueueDump];
    }
}

- (void)stopQueueDump
{
    dumpingQueue_ = NO;
}

- (void)enqueueNetworkRequestWithUrlString:(NSString *)urlString andPOSTData:(NSString *)postData
{
    DLog(@"MATConnManager: enqueueNetworkRequestWithUrlString");
    
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:urlString, KEY_URL, postData, KEY_JSON, nil];
    [self.requestsQueue push:dict];
    [self.requestsQueue save];
}

#pragma mark - NSURLConnection Delegate Methods

-(void)connection:(MNSURLConnection *)connection didFailWithError:(NSError *)error
{
    // do not requeue failed request to fetch tracking id for app to app tracking
    if(connection.isAppToApp || connection.isInstallLogId)
    {
        // suppress the memory leak warning -- we do not expect a memory leak since we are dealing with Class object and SEL.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if(connection.delegateTarget
           && connection.delegateFailureSelector
           && [connection.delegateTarget respondsToSelector:connection.delegateFailureSelector])
        {
            [connection.delegateTarget performSelector:connection.delegateFailureSelector withObject:connection.delegateArgument withObject:error];
        }
#pragma clang diagnostic pop
    }
    else
    {
        if (self.dumpingQueue)
        {
            self.dumpTriesFailures = self.dumpTriesFailures + 1;
            if (self.dumpTriesFailures > MAX_QUEUE_DUMP_TRIES_FAILURES)
            {
                [self stopQueueDump];
            }
        }
        
        DLLog(@"MATConnManager: connection:didFailWithError: error = %@", error);
        DLLog(@"MATConnManager: connection:didFailWithError: failed url = %@", connection.url.absoluteString);
        
        // Store to queue, so that the request may be fired when internet becomes available.
        [self enqueueNetworkRequestWithUrlString:connection.url.absoluteString andPOSTData:connection.postData];
    }
    
    // requests for app-to-app and install-log-id have their own delegates, so do not send callbacks for those...
    if(!connection.isAppToApp && !connection.isInstallLogId && [self.delegate respondsToSelector:@selector(connectionManager:didFailWithError:)])
    {
        [self.delegate connectionManager:self didFailWithError:error];
    }
}

-(void)connection:(MNSURLConnection *)connection didReceiveData:(NSData *)data
{
#if DEBUG_REQUEST_LOG
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"MATConnManager: didReceiveData: connectionManager = %@", self);
    NSLog(@"MATConnManager: didReceiveData: size = %d, %@", data.length, dataString);
    [dataString release], dataString = nil;
#endif
    
    [connection.responseData appendData:data];
    
#if DEBUG_REQUEST_LOG
    NSString *str = [[NSString alloc] initWithData:connection.responseData encoding:NSASCIIStringEncoding];
    NSLog(@"MATConnManager: didReceiveData: newCombinedData = %@", str);
    [str release], str = nil;
#endif
}

-(void)connection:(MNSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#if DEBUG_REQUEST_LOG
    NSHTTPURLResponse* httpResponse1 = (NSHTTPURLResponse*)response;
    int code1 = [httpResponse1 statusCode];
    NSLog(@"MATConnManager: didReceiveResponse: connectionManager = %@", self);
    NSLog(@"MATConnManager: didReceiveResponse: http response code = %d", code1);
#endif
    if(!connection.isAppToApp && !connection.isInstallLogId)
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int code = [httpResponse statusCode];
        
        // if the network request was successful
        if(200 == code)
        {
            self.dumpTriesFailures = 0;
            
            DRLog(@"MATConnManager: didReceiveResponse: previous request successful: call dumpNextFromQueue");
            
            // fire the next stored request
            [self dumpNextFromQueue];
        }
        else
        {
            // the previous web request failed
            
            // if the queue is already being dumped
            if (self.dumpingQueue)
            {
                // stop the queue dumping if the max number of attempts have already been made
                self.dumpTriesFailures = self.dumpTriesFailures + 1;
                if (self.dumpTriesFailures > MAX_QUEUE_DUMP_TRIES_FAILURES)
                {
                    [self stopQueueDump];
                }
            }
            
            // Store to queue, so that the request may be fired when internet becomes available.
            [self enqueueNetworkRequestWithUrlString:connection.url.absoluteString andPOSTData:connection.postData];
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
    [dataString release]; dataString = nil;
#endif
    
    DLog(@"MATConnManager: didFinishLoading 2: connectionManager = %@", self);
    DLog(@"isLogId request = %d", connection.isInstallLogId);
    DLog(@"delegateTarget  = %@", NSStringFromClass(connection.delegateTarget));
    DLog(@"successSEL      = %@, responds = %d", NSStringFromSelector(connection.delegateSuccessSelector), [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector]);
    DLog(@"arg             = %@", connection.delegateArgument);
    DLog(@"call delegate   = %d", (connection.isAppToApp || connection.isInstallLogId)
                                    && connection.delegateTarget
                                    && connection.delegateSuccessSelector
                                    && [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector]);
    
    if((connection.isAppToApp || connection.isInstallLogId)
       && connection.delegateTarget
       && connection.delegateSuccessSelector
       && [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector])
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

    DLog(@"MATConnManager: calling delegate success callback: %d", (!connection.isAppToApp && !connection.isInstallLogId && [self.delegate respondsToSelector:@selector(connectionManager:didSucceedWithData:)]));
    
    if(!connection.isAppToApp && !connection.isInstallLogId && [self.delegate respondsToSelector:@selector(connectionManager:didSucceedWithData:)])
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
