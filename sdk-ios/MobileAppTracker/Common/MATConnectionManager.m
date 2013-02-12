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

/****************************************
 *  VERY IMPORTANT!
 *  These values should be zero for releases.
 ****************************************/
#define DEBUG_REQUEST_LOG                   0
#define DEBUG_LINK_LOG                      0

static const NSUInteger MAX_QUEUE_DUMP_TRIES_FAILURES       =   5;

int const MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL = 60;

/********* MNSURLConnection interface ********/
@interface MNSURLConnection : NSURLConnection
{
    NSURL * url;
    NSString * json;
}

@property (nonatomic, retain) NSURL * url;
@property (nonatomic, retain) NSString * json;

@end

/********* MNSURLConnection implementation ********/

@implementation MNSURLConnection

@synthesize url, json;

-(void) dealloc
{
    [url release]; url = nil;
    [json release]; json = nil;
    [super dealloc];
}

@end

static MATConnectionManager * instance__ = nil;

@interface MATConnectionManager()

@property (nonatomic, retain) MATRequestsQueue * requestsQueue;
@property (nonatomic, retain) MATReachability * reachability;
@property (assign) BOOL dumpingQueue;
@property (assign) NSUInteger dumpTriesFailures;

- (void)dumpQueue;
- (void)dumpNextFromQueue;
- (void)stopQueueDump;
- (void)handleNetworkChange:(NSNotification *)notice;
- (void)enqueueNetworkRequestWithUrlString:(NSString *)urlString andJsonData:(NSString *)json;

@end


@implementation MATConnectionManager

@synthesize requestsQueue = requestsQueue_;
@synthesize reachability = reachability_;
@synthesize status = status_;
@synthesize dumpingQueue = dumpingQueue_;
@synthesize dumpTriesFailures = dumpTriesFailures_;
@synthesize shouldDebug = _shouldDebug;
@synthesize shouldAllowDuplicates = _shouldAllowDuplicates;
@synthesize isAppToApp = _isAppToApp;
@synthesize delegate = _delegate;
@synthesize delegateTarget = _delegateTarget;
@synthesize delegateArgument = _delegateArgument;
@synthesize delegateSuccessSelector = _delegateSuccessSelector;
@synthesize delegateFailureSelector = _delegateFailureSelector;

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
        
        /// Initialize Reachability
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNetworkChange:)
                                                     name:kReachabilityChangedNotification object:nil];
        
        // When the app enters foreground, fire the requests stored in the request queue.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNetworkChange:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        self.reachability = [MATReachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        self.status = [self.reachability currentReachabilityStatus];
        [self handleNetworkChange:nil];
    }
    
    return self;
}

- (void)dealloc
{
    // stop observing network reachability notifications
    self.reachability = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    // stop observing app-entered-foreground notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // store pending requests to file
    [self.requestsQueue save];
    self.requestsQueue = nil;

    [_delegateTarget release]; _delegateTarget = nil;
    [_delegateArgument release]; _delegateArgument = nil;
    
    [super dealloc];
}

#pragma mark - Reachability Notification

- (void)handleNetworkChange:(NSNotification *)notice
{
    self.status = [self.reachability currentReachabilityStatus];
    
    // if network is available
    if (NotReachable != self.status)
    {
        // fire the stored web requests
        [self dumpQueue];
    }
}

#pragma mark -

-(void)dumpQueue
{
    self.dumpingQueue = YES;
    self.dumpTriesFailures = 0;
    
    // fire the first request from the queue
    [self dumpNextFromQueue];
}

- (void)dumpNextFromQueue
{
    NSDictionary * dict = [self.requestsQueue pop];
    
    // if a stored request is found
    if (dict)
    {
        // fire web request
        NSString * link = [dict objectForKey:KEY_URL];
        NSString * JSONData = [dict objectForKey:KEY_JSON];
        [self beginUrlRequest:link andData:JSONData withDelegate:self.delegate];
        
        // store request queue to file
        [self.requestsQueue save];
    }
    else
    {
        // the stored request queue is empty, so stop
        [self stopQueueDump];
    }
}

- (void)stopQueueDump
{
    self.dumpingQueue = NO;
}

- (void)beginRequestGetTrackingId:(NSString *)link
               withDelegateTarget:(id)target
              withSuccessSelector:(SEL)selectorSuccess
              withFailureSelector:(SEL)selectorFailure
                     withArgument:(NSMutableDictionary *)dict
                     withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    //http://engine.mobileapptracking.com/serve?action=click&publisher_advertiser_id=1587&package_name=com.HasOffers.matsdktestapp&response_format=json
    
    // create a flag for app to app tracking request
    
    self.isAppToApp = true;
    
    self.delegate = connectionDelegate;
    self.delegateTarget = target;
    self.delegateSuccessSelector = selectorSuccess;
    self.delegateFailureSelector = selectorFailure;
    self.delegateArgument = dict;
    
    DLog(@"%@", link);
    
    NSURL * url = [NSURL URLWithString:link];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
    
    //    NSLog(@"This is the request URL2: %@", request.URL.absoluteString);
    MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    connection.url = url;
    connection.json = STRING_EMPTY;
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [connection start];
    [connection release];
}

- (void)beginUrlRequest:(NSString *)link andData:(NSString*)data withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    self.delegate = connectionDelegate;
    
    // debug on or off
    if (self.shouldDebug)
    {
        link = [link stringByAppendingFormat:@"&%@=1", KEY_DEBUG];
    }
    if (self.shouldAllowDuplicates)
    {
        link = [link stringByAppendingFormat:@"&%@=1", KEY_SKIP_DUP];
    }
    
    // Append json format to the url
    // This in the future, can be overridden by developer
    link = [link stringByAppendingFormat:@"&%@=%@", KEY_RESPONSE_FORMAT, KEY_JSON];
    
    NSURL * url = [NSURL URLWithString:link];
    
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];
    
#if DEBUG_REQUEST_LOG
    NSRange range = [link rangeOfString:[NSString stringWithFormat:@"&%@=", KEY_DATA]];
    range.length = [link length] - range.location;
    NSString * debugString = [link stringByReplacingCharactersInRange:range withString:STRING_EMPTY];
    NSLog(@"URL: %@", debugString); 
#endif
    
#if DEBUG_LINK_LOG
    NSLog(@"URL Link=%@", link);
#endif
    
    //Check if params is nil
    if(data)
    {
#if DEBUG_REQUEST_LOG
        NSLog(@"This is the data: %@", data);
#endif
        NSData *myRequestData = [NSData dataWithBytes:[data UTF8String] length:[data length]];

        request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:HTTP_METHOD_POST];
        [request setValue:HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:HTTP_CONTENT_TYPE];
        [request setHTTPBody:myRequestData];
    }
    else
    {
        data = STRING_EMPTY;
    }
    
    // Fire a network request only if the internet is currently available, otherwise store the request for later.
    if(NotReachable == self.status)
    {
#if DEBUG_REQUEST_LOG
      NSLog(@"Network not reachable, store the request for now.");
#endif
        MobileAppTracker *mat = [MobileAppTracker sharedManager];
        
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:KEY_ERROR_MAT_NETWORK_NOT_REACHABLE forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"Network not reachable, store the request for now." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1201 userInfo:errorDetails];
        [mat performSelector:NSSelectorFromString(@"notifyDelegateFailureWithError:") withObject:error];
        
        // Store to queue, so that the request may be fired when internet becomes available.
        [self enqueueNetworkRequestWithUrlString:url.absoluteString andJsonData:data];
    }
    else
    {
        //    NSLog(@"This is the request URL2: %@", request.URL.absoluteString);
        MNSURLConnection * connection = [[MNSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        connection.url = url;
        connection.json = data;
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [connection start];
        [connection release];
    }
}

#pragma mark - NSURLConnection delegate

-(void)connection:(MNSURLConnection *)connection didFailWithError:(NSError *)error
{
    // do not requeue failed request to fetch tracking id for app to app tracking
    if(self.isAppToApp)
    {
        // suppress the memory leak warning -- we do not expect a memory leak since we are dealing with Class object and SEL.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if(self.delegateTarget
           && self.delegateFailureSelector
           && [self.delegateTarget respondsToSelector:self.delegateFailureSelector])
        {
            [self.delegateTarget performSelector:self.delegateFailureSelector withObject:self.delegateArgument withObject:error];
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
        
#if DEBUG_REQUEST_LOG
        NSLog(@"THIS FAILED: %@", connection.url.absoluteString);
#endif
        
        // Store to queue, so that the request may be fired when internet becomes available.
        [self enqueueNetworkRequestWithUrlString:connection.url.absoluteString andJsonData:connection.json];
    }
    
    if(!self.isAppToApp && [self.delegate respondsToSelector:@selector(connectionManager:didFailWithError:)])
    {
        [self.delegate connectionManager:self didFailWithError:error];
    }
}

- (void)enqueueNetworkRequestWithUrlString:(NSString *)urlString andJsonData:(NSString *)json
{
    NSDictionary * connectionObject = [NSDictionary dictionaryWithObjectsAndKeys:urlString, KEY_URL, json, KEY_JSON, nil];
    [self.requestsQueue push:connectionObject];
    [self.requestsQueue save];
}

-(void)connection:(MNSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.shouldDebug)
    {
        NSString * dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"========Server Response==========\n %@", dataString);
        
#if DEBUG_REQUEST_LOG
        NSLog(@"Response: %@", dataString);
#endif
        [dataString release]; dataString = nil;
    }
    
    if(self.isAppToApp
       && self.delegateTarget
       && self.delegateSuccessSelector
       && self.delegateArgument
       && [self.delegateTarget respondsToSelector:self.delegateSuccessSelector])
    {
        [self.delegateArgument setValue:data forKey:KEY_SERVER_RESPONSE];
        
        // suppress the memory leak warning -- we do not expect a memory leak since we are dealing with Class object and SEL.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegateTarget performSelector:self.delegateSuccessSelector withObject:self.delegateArgument];
#pragma clang diagnostic pop
    }
    
    if(!self.isAppToApp && [self.delegate respondsToSelector:@selector(connectionManager:didSucceedWithData:)])
    {
        [self.delegate connectionManager:self didSucceedWithData:data];
    }
}

-(void)connection:(MNSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if(!self.isAppToApp)
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int code = [httpResponse statusCode];
        
#if DEBUG_REQUEST_LOG
        NSLog(@"did receive response: http response code = %d", code);
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

@end
