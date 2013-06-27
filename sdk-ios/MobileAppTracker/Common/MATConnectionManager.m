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
#import "MobileAppTracker.h"

static const NSUInteger MAX_QUEUE_DUMP_TRIES_FAILURES       =   5;

int const MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL = 60;

/********* MNSURLConnection interface ********/
@interface MNSURLConnection : NSURLConnection
{
}

@property (nonatomic, retain) NSURL * url;
@property (nonatomic, retain) NSString * json;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, assign) BOOL isAppToApp, isInstallLogId;
@property (nonatomic, assign) SEL delegateSuccessSelector, delegateFailureSelector;
@property (nonatomic, retain) id delegateTarget;
@property (nonatomic, retain) id delegateArgument;

@end

/********* MNSURLConnection implementation ********/

@implementation MNSURLConnection

@synthesize url, json;
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
    [json release], json = nil;
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
- (void)enqueueNetworkRequestWithUrlString:(NSString *)urlString andJsonData:(NSString *)json;

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
        [self.requestsQueue load];
        
#if DEBUG_LOG
        NSLog(@"MATConnManager.init(): requestsQueue = %@", requestsQueue_);
#endif
        
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
        
#if DEBUG_LOG
        NSLog(@"MATConnManager.init(): reachability = %@", self.reachability);
#endif
        
        [self.reachability startNotifier];
        self.status = [self.reachability currentReachabilityStatus];
        [self handleNetworkChange:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    // stop observing app-did-become-active notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
#if DEBUG_LOG
    NSLog(@"MATConnManager: dealloc: stop reachability notifier: self = %@, self.reachability = %@", self, self.reachability);
#endif
    
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
#if DEBUG_LOG
    NSLog(@"MATConnManager: handleNetworkChange: notice = %@", notice);
    NSLog(@"MATConnManager: handleNetworkChange: self.reachability = %@", self.reachability);
#endif
    self.status = [self.reachability currentReachabilityStatus];
    
    // if network is available
    if (NotReachable != self.status)
    {
        // fire the stored web requests
        [self dumpQueue];
    }
}

#pragma mark - Network Request Methods

- (void)beginRequestGetTrackingId:(NSString *)link
               withDelegateTarget:(id)target
              withSuccessSelector:(SEL)selectorSuccess
              withFailureSelector:(SEL)selectorFailure
                     withArgument:(NSMutableDictionary *)dict
                     withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    //http://engine.mobileapptracking.com/serve?action=click&publisher_advertiser_id=1587&package_name=com.HasOffers.matsdktestapp&response_format=json
    
    // ignore the request if the network is not reachable
    if(NotReachable != self.status)
    {
        self.delegate = connectionDelegate;
        
#if DEBUG_LINK_LOG
        NSLog(@"MATConnManager: beginRequestGetTrackingId: %@", link);
#endif
        
        NSURL * url = [NSURL URLWithString:link];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
        MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        connection.url = url;
        connection.json = STRING_EMPTY;
        // create a flag for app to app tracking request
        connection.isAppToApp = true;
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

- (void)beginRequestGetInstallLogId:(NSString *)link
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
        
        NSURL * url = [NSURL URLWithString:link];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
#if DEBUG_LINK_LOG
        NSLog(@"MATConnManager: beginRequestGetInstallLogId: This is the request URL2: %@", request.URL.absoluteString);
#endif
        
        MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        connection.url = url;
        connection.json = STRING_EMPTY;
        // create a flag for get install log id request
        connection.isInstallLogId = true;
        connection.responseData = [NSMutableData data];
        
        connection.delegateTarget = target;
        connection.delegateSuccessSelector = selectorSuccess;
        connection.delegateFailureSelector = selectorFailure;
        connection.delegateArgument = dict;

#if DEBUG_LINK_LOG
        NSLog(@"MATConnManager: beginRequestGetInstallLogId: connectionManager = %@", self);
#endif
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [connection start];
        [connection release];
    }
}

- (void)beginUrlRequest:(NSString *)link andEventItems:(NSString*)eventItems withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    self.delegate = connectionDelegate;
    
    // Fire a network request only if the internet is currently available, otherwise store the request for later.
    if(NotReachable == self.status)
    {
#if DEBUG_REQUEST_LOG
      NSLog(@"MATConnManager: beginUrlRequest: Network not reachable, store the request for now.");
#endif
        MobileAppTracker *mat = [MobileAppTracker sharedManager];
        
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:KEY_ERROR_MAT_NETWORK_NOT_REACHABLE forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"Network not reachable, store the request for now." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1201 userInfo:errorDetails];
        [mat performSelector:NSSelectorFromString(@"notifyDelegateFailureWithError:") withObject:error];
        
        // Store to queue, so that the request may be fired when internet becomes available.
        [self enqueueNetworkRequestWithUrlString:link andJsonData:eventItems];
    }
    else
    {
        // debug on or off
        if (self.shouldDebug)
        {
            link = [link stringByAppendingFormat:@"&%@=1", KEY_DEBUG];
        }
        
        // duplicate installs/events/ref_ids allowed or not
        if (self.shouldAllowDuplicates)
        {
            link = [link stringByAppendingFormat:@"&%@=1", KEY_SKIP_DUP];
        }
        
        // Append json format to the url
        // This in the future, can be overridden by developer
        link = [link stringByAppendingFormat:@"&%@=%@", KEY_RESPONSE_FORMAT, KEY_JSON];
        
        NSURL * url = [NSURL URLWithString:link];
        
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
        
#if DEBUG_REQUEST_LOG
        NSRange range = [link rangeOfString:[NSString stringWithFormat:@"&%@=", KEY_DATA]];
        range.length = [link length] - range.location;
        NSString * debugString = [link stringByReplacingCharactersInRange:range withString:STRING_EMPTY];
        NSLog(@"MATConnManager: beginUrlRequest: URL: %@", debugString);
#endif
        
#if DEBUG_LINK_LOG
        NSLog(@"MATConnManager: beginUrlRequest: URL Link=%@", link);
#endif
        
        //Check if params is nil
        if(eventItems)
        {
#if DEBUG_REQUEST_LOG
            NSLog(@"MATConnManager: beginUrlRequest: eventItems = %@", eventItems);
#endif
            request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:HTTP_METHOD_POST];
            [request setValue:HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:HTTP_CONTENT_TYPE];
            [request setHTTPBody:[eventItems dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else
        {
            eventItems = STRING_EMPTY;
        }
        
        MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        connection.url = url;
        connection.json = eventItems;
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
    NSDictionary * dict = [requestsQueue_ pop];
    
    // if a stored request is found
    if (dict)
    {
        // fire web request
        NSString * link = [dict objectForKey:KEY_URL];
        NSString * JSONData = [dict objectForKey:KEY_JSON];
        [self beginUrlRequest:link andEventItems:JSONData withDelegate:self.delegate];
        
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

- (void)enqueueNetworkRequestWithUrlString:(NSString *)urlString andJsonData:(NSString *)json
{
    NSDictionary * connectionObject = [NSDictionary dictionaryWithObjectsAndKeys:urlString, KEY_URL, json, KEY_JSON, nil];
    [self.requestsQueue push:connectionObject];
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
        
#if DEBUG_LINK_LOG
        NSLog(@"MATConnManager: connection:didFailWithError: failed url = %@", connection.url.absoluteString);
#endif
        
        // Store to queue, so that the request may be fired when internet becomes available.
        [self enqueueNetworkRequestWithUrlString:connection.url.absoluteString andJsonData:connection.json];
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
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int code = [httpResponse statusCode];
    NSLog(@"MATConnManager: didReceiveResponse: connectionManager = %@", self);
    NSLog(@"MATConnManager: didReceiveResponse: http response code = %d", code);
#endif
    if(!connection.isAppToApp && !connection.isInstallLogId)
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int code = [httpResponse statusCode];
        
#if DEBUG_REQUEST_LOG
        NSLog(@"MATConnManager: did receive response: http response code = %d", code);
#endif
        
        // if the network request was successful
        if(200 == code)
        {
            self.dumpTriesFailures = 0;
            
            // fire the next stored request
            [self dumpNextFromQueue];
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
            
            // Store to queue, so that the request may be fired when internet becomes available.
            [self enqueueNetworkRequestWithUrlString:connection.url.absoluteString andJsonData:connection.json];
        }
    }
}

- (void)connectionDidFinishLoading:(MNSURLConnection *)connection
{
#if DEBUG_LOG
    NSLog(@"MATConnManager: didFinishLoading: connectionManager = %@", self);
#endif

#if DEBUG_LINK_LOG
        NSLog(@"MATConnManager: didFinishLoading: url = %@", connection.url.absoluteString);
#endif

#if DEBUG_LOG
    NSString *dataString = [[NSString alloc] initWithData:connection.responseData encoding:NSASCIIStringEncoding];
    NSLog(@"========Server Response==========");
    NSLog(@"MATConnManager: didFinishLoading: %@", dataString);
    [dataString release]; dataString = nil;
#endif
    
#if DEBUG_LOG
    NSLog(@"MATConnManager: didFinishLoading 2: connectionManager = %@", self);
    NSLog(@"isLogId request = %d", connection.isInstallLogId);
    NSLog(@"delegateTarget  = %@", NSStringFromClass(connection.delegateTarget));
    NSLog(@"successSEL      = %@, responds = %d", NSStringFromSelector(connection.delegateSuccessSelector), [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector]);
    NSLog(@"arg             = %@", connection.delegateArgument);
    NSLog(@"call delegate   = %d", (connection.isAppToApp || connection.isInstallLogId)
                                    && connection.delegateTarget
                                    && connection.delegateSuccessSelector
                                    && [connection.delegateTarget respondsToSelector:connection.delegateSuccessSelector]);
#endif
    
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
        
#if DEBUG_LOG
        NSLog(@"MATConnManager: calling delegateTarget success selector: arg = %@", connection.delegateArgument);
#endif
        
        // suppress the memory leak warning -- we do not expect a memory leak since we are dealing with Class object and SEL.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [connection.delegateTarget performSelector:connection.delegateSuccessSelector withObject:connection.delegateArgument];
#pragma clang diagnostic pop
    }

#if DEBUG_LOG
    NSLog(@"MATConnManager: calling delegate success callback: %d", (!connection.isAppToApp && !connection.isInstallLogId && [self.delegate respondsToSelector:@selector(connectionManager:didSucceedWithData:)]));
#endif
    
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
