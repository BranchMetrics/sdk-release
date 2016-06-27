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

extern NSString *const TuneHttpRequestMethodTypeGet;
extern NSString *const TuneHttpRequestMethodTypePost;
extern NSString *const TuneHttpRequestMethodTypeHead;
extern NSString *const TuneHttpRequestMethodTypePut;
extern NSString *const TuneHttpRequestMethodTypeDelete;
extern NSString *const TuneHttpRequestMethodTypeTrace;
extern NSString *const TuneHttpRequestMethodTypeOptions;
extern NSString *const TuneHttpRequestMethodTypeConnect;
extern NSString *const TuneHttpRequestMethodTypePatch;

extern NSString *const TuneHttpRequestHeaderPList;
extern NSString *const TuneHttpRequestHeaderJSON;

extern NSString *const TuneHttpRequestHeaderContentTypeApplicationUrlEncoded;
extern NSString *const TuneHttpRequestHeaderContentType;
extern NSString *const TuneHttpRequestHeaderContentLength;

extern NSString *const TuneHttpRequestHeaderAccept;

extern NSString *const TuneHttpRequestHeaderDeviceID;
extern NSString *const TuneHttpRequestHeaderAppID;
extern NSString *const TuneHttpRequestHeaderSdkVersion;
extern NSString *const TuneHttpRequestHeaderAppVersion;
extern NSString *const TuneHttpRequestHeaderOsVersion;
extern NSString *const TuneHttpRequestHeaderOsType;

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
