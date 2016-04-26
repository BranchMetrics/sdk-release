//
//  TuneApi.h
//  Tune
//
//  Created by Kevin Jenkins on 4/11/13.
//
//

#import <Foundation/Foundation.h>

// Include these in the header, since you'll pretty much always
// need them when including this class.
#import "TuneHttpRequest.h"
#import "TuneHttpResponse.h"
#import "TuneAnalyticsEvent.h"

/**
 This class provides an easy interface to all of our server side endpoints. It makes
 use of two key classes: TuneHttpRequest and TuneHttpResponse.

 The API builds requests for you based on the typical parameters for each endpoint
 request. If a request requires an authentication token, the request object will
 make sure that is has one. If no token exists, it will block until it can reauthenticate
 the user. Endpoints that require authentication are endpoints that are used by people
 with login credentials only, so blocking in this case is ok.

 You can choose to run these requests sychronously or asynchronously and with or without
 a block. (see TuneHttpRequest)

 NOTE: Endpoint strings are exciting and magical. Since our endpoints utilize the URL
 to encapsulate data and concatenating strings is a messy and dangerous process (nil
 strings will create exceptions when appended), we provide a mapping process.

 Ex: /api/v/{version}/app/{app_id}/user/{user_id}/

 The above string has mustachioed components. These are the key half of a key-value pairing
 defining in the endpointArguments dictionary. If a value is not present in the dictionary, it will
 not be replaced. This will result in an invalid URL that will just return a 404.
 */
@interface TuneApi : NSObject

#pragma mark - GET Requests
+ (TuneHttpRequest *)getConfigurationRequest;
+ (TuneHttpRequest *)getPlaylistRequest;
+ (TuneHttpRequest *)getConnectedPlaylistRequest;
+ (TuneHttpRequest *)getGeocodeRequest;

#pragma mark - POST Requests
+ (TuneHttpRequest *)getSyncSDKRequest:(NSDictionary *)toSync;
+ (TuneHttpRequest *)getDiscoverEventRequest:(NSDictionary *)eventDictionary;
+ (TuneHttpRequest *)getConnectDeviceRequest;
+ (TuneHttpRequest *)getDisconnectDeviceRequest;


@end
