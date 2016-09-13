//
//  TuneHttpRequest.h
//  Tune
//
//  Created by Kevin Jenkins on 4/9/13.
//
//

#import <Foundation/Foundation.h>

/**
 This class mitigates some of the complexities in making HTTP requests to our
 server-side endpoints.

 ENDPOINT:
 ex: /api/v/{version}/user/{user_id}/

 Mustaches! A mustache defines a variable to be replaced by a matching key-value
 pair in the endpointArgument dictionary. This is expounded upon a bit more in
 TuneApi.
 */

FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypeGet;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypePost;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypeHead;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypePut;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypeDelete;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypeTrace;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypeOptions;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypeConnect;
FOUNDATION_EXPORT NSString *const TuneHttpRequestMethodTypePatch;

FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderPList;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderJSON;

FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderContentTypeApplicationUrlEncoded;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderContentDisposition;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderContentEncoding;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderContentType;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderContentLength;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderContentTransferEncoding;

FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderAccept;

FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderDeviceID;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderAppID;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderSdkVersion;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderAppVersion;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderOsVersion;
FOUNDATION_EXPORT NSString *const TuneHttpRequestHeaderOsType;

@class TuneHttpResponse;
@class TuneManager;

@interface TuneHttpRequest : NSMutableURLRequest

/** The domain to send the request to. Without the endpoint specified.
    Defaults to the current 'playlistHostPort' in TuneConfiguration.*/
@property (nonatomic, copy) NSString *domain;

/** An optionally mustachioed url string, without domain information. Defaults to an empty string. */
@property (nonatomic, copy) NSString *endpoint;

/** Key-value pairs for parameters to be passed in through a GET or POST method. */
@property (nonatomic, copy) NSDictionary *parameters;

/** Key-value pairs for replacing mustachioed variables in the endpoint string. */
@property (nonatomic, copy) NSDictionary *endpointArguments;

/** Indicates whether or no this request requires an authentication token. If set to YES, the token will automatically be added to the request parameters. */
@property (nonatomic) BOOL authenticated;

@property (nonatomic) BOOL bodyOverride;

/**
 Synchronously makes the request.

 @returns an TuneHttpResponse object that contains an NSError, NSURLResponse
 object, and a dictionary containing the response.
 */
- (TuneHttpResponse*)performSynchronousRequest;

/**
 Executes the request on a background thread with no return or callback.
 */
- (void)performAsynchronousRequest;

/**
 Executes the request on a background thread with a callback block that has an
 TuneHttpResponse object. This provides access to any NSError that may have
 occured, the base NSURLResponse and a dictionary response containing any data
 returned (either plist or JSON).

 @param completionBlock a block that takes an TuneHttpResponse object as an
 argument that will execute when the request has completed.
 */
- (void)performAsynchronousRequestWithCompletionBlock:(void (^)(TuneHttpResponse* response))completionBlock;



- (void)prepareRequest;

@end
