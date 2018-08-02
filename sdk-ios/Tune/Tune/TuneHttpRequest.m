//
//  TuneHttpRequest.m
//  Tune
//
//  Created by Kevin Jenkins on 4/9/13.
//
//

#import "TuneHttpRequest.h"
#import "TuneHttpResponse.h"
#import "TuneHttpUtils.h"
#import "TuneConfiguration.h"
#import "TuneStringUtils.h"
#import "TuneUtils.h"

NSString *const TuneHttpRequestMethodTypeGet = @"GET";
NSString *const TuneHttpRequestMethodTypePost = @"POST";
NSString *const TuneHttpRequestMethodTypeHead = @"HEAD";
NSString *const TuneHttpRequestMethodTypePut = @"PUT";
NSString *const TuneHttpRequestMethodTypeDelete = @"DELETE";
NSString *const TuneHttpRequestMethodTypeTrace = @"TRACE";
NSString *const TuneHttpRequestMethodTypeOptions = @"OPTIONS";
NSString *const TuneHttpRequestMethodTypeConnect = @"CONNECT";
NSString *const TuneHttpRequestMethodTypePatch = @"PATCH";

NSString *const TuneHttpRequestHeaderPList = @"application/x-plist";
NSString *const TuneHttpRequestHeaderJSON = @"application/json";

NSString *const TuneHttpRequestHeaderContentTypeApplicationUrlEncoded = @"application/x-www-form-urlencoded";

NSString *const TuneHttpRequestHeaderAccept = @"Accept";
NSString *const TuneHttpRequestHeaderContentDisposition = @"Content-Disposition";
NSString *const TuneHttpRequestHeaderContentEncoding = @"Content-Encoding";
NSString *const TuneHttpRequestHeaderContentType = @"Content-Type";
NSString *const TuneHttpRequestHeaderContentLength = @"Content-Length";
NSString *const TuneHttpRequestHeaderContentTransferEncoding = @"Content-Transfer-Encoding";

NSString *const TuneHttpRequestHeaderDeviceID = @"X-ARTISAN-DEVICEID";
NSString *const TuneHttpRequestHeaderAppID = @"X-ARTISAN-APPID";
NSString *const TuneHttpRequestHeaderSdkVersion = @"X-TUNE-SDKVERSION";
NSString *const TuneHttpRequestHeaderAppVersion = @"X-TUNE-APPVERSION";
NSString *const TuneHttpRequestHeaderOsVersion = @"X-TUNE-OSVERSION";
NSString *const TuneHttpRequestHeaderOsType = @"X-TUNE-OSTYPE";

@implementation TuneHttpRequest

#pragma mark - Initialization
- (id)init {
    self = [super init];
    if (self) {
        _domain = @"https://playlist.ma.tune.com";
        _endpoint = @"";
        _endpointArguments = @{};
        _parameters = @{};
        _authenticated = YES;
        _bodyOverride = YES;
    }
    return self;
}

#pragma mark - End Point Processing
- (NSString*)stripMustache:(NSString*)mustacheString {
    return [[mustacheString stringByReplacingOccurrencesOfString:@"{" withString:@""]
                            stringByReplacingOccurrencesOfString:@"}" withString:@""];
}

- (NSString*)urlEndpoint {
    NSArray *chunks = [_endpoint componentsSeparatedByString:@"/"];
    NSString *urlPath = [NSString stringWithString:_endpoint];

    for (NSString *string in chunks) {
        if ([string hasPrefix:@"{"]) {
            NSString *key = [self stripMustache:string];
            NSString *replaceValue = _endpointArguments[key];
            
            if (replaceValue) {
                urlPath = [urlPath stringByReplacingOccurrencesOfString:string withString:replaceValue];
            }
        }
    }
    
    return [TuneStringUtils addPercentEncoding:urlPath];
}

#pragma mark - Parameter Processing
- (NSString*)parameterString {
    return [TuneUtils dictionaryAsQueryString:_parameters withNamespace:nil];
}
- (BOOL)shouldAppendParameters {
    return (([TuneHttpRequestMethodTypeGet isEqualToString:[self HTTPMethod]] ||
            [TuneHttpRequestMethodTypePut isEqualToString:[self HTTPMethod]]) &&
            0 < [[self parameterString] length]);
}

- (void)applyPostBody {
    if (self.HTTPBodyStream) { return; }
    NSString *postString = [self parameterString];
    NSData *postData = [NSData dataWithBytes:[postString UTF8String] length:[postString length]];
    [self setHTTPBody:postData];
}

#pragma mark - Request Building
- (void)prepareRequest {
    if (!self.URL) { [self updateURL]; }

    [TuneHttpUtils addIdentifyingHeaders:self];

    if ([TuneHttpRequestMethodTypePost isEqualToString:[self HTTPMethod]] && self.bodyOverride)  {
        [self applyPostBody];
    }
}

- (void)updateURL {
    NSString *urlString = [self urlEndpoint];
    if ([self shouldAppendParameters]) {
        urlString = [NSString stringWithFormat:@"%@?%@", urlString, [self parameterString]];
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", _domain, urlString]];
    [self setURL:url];
}

#pragma mark - Helper Methods
- (NSDictionary *)responseDictionaryForResult:(NSData *)resultData withError:(NSError *)error {
    if ([TuneHttpRequestHeaderPList isEqualToString:[self valueForHTTPHeaderField:TuneHttpRequestHeaderAccept]]) {
        return [NSPropertyListSerialization propertyListWithData:resultData
                                                         options:NSPropertyListImmutable
                                                          format:nil
                                                           error:&error];
    } else if ([TuneHttpRequestHeaderJSON isEqualToString:[self valueForHTTPHeaderField:TuneHttpRequestHeaderAccept]] ||
               [TuneHttpRequestHeaderContentTypeApplicationUrlEncoded isEqualToString:[self valueForHTTPHeaderField:TuneHttpRequestHeaderContentType]]) {

        id tmp = [NSJSONSerialization JSONObjectWithData:resultData options:0 error:nil];
        if ([tmp isKindOfClass:NSDictionary.class]) {
            return tmp;
        }
    }
    return nil;
}

#pragma mark - Send Methods
- (TuneHttpResponse *)sendRequest {
    [self prepareRequest];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *result = [TuneHttpUtils sendSynchronousRequest:self response:&response error:&error];
    
    if (error) {
        NSLog(@"HTTP request error: %@", error);
    }
    
    NSDictionary *responseDictionary = [self responseDictionaryForResult:result withError:error];
    
    if (error) {
        NSLog(@"Error parsing HTTP response: %@", error);
    }
    
    TuneHttpResponse *tuneResponse = [[TuneHttpResponse alloc] initWithURLResponse:response andError:error];
    [tuneResponse setResponseDictionary:responseDictionary];
    
    return tuneResponse;
}

- (void)performAsynchronousRequestWithCompletionBlock:(void (^)(TuneHttpResponse* response))completionBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        TuneHttpResponse *response = [self sendRequest];
        if (completionBlock != nil) {
            completionBlock(response);
        }
    });
}

- (void)performAsynchronousRequest {
    [self performAsynchronousRequestWithCompletionBlock:nil];
}

- (TuneHttpResponse*)performSynchronousRequest {
    return [self sendRequest];
}


@end
