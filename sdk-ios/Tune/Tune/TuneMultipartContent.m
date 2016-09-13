//
//  TuneMultipartContent.m
//  Tune
//
//  Created by Kevin Jenkins on 7/21/13.
//
//

#import "TuneMultipartContent.h"
#import "TuneHttpRequest.h"

NSString *const TuneMultipartContentDispositionFormData = @"form-data";

@implementation TuneMultipartContent

#pragma mark - Initialization
- (id)init {

    self = [super init];
    if (self) {
        self.disposition = nil;
        self.contentName = nil;
        self.contentValue = nil;
        self.contentType = nil;
        self.encoding = nil;
        self.data = nil;
        self.fileName = nil;
        self.contentEncoding = NSUTF8StringEncoding;

    }
    return self;
}
+ (id)content {
    return [[TuneMultipartContent alloc] init];
}


#pragma mark - Data Construction
- (BOOL)shouldAddContentType {
    return (self.contentType != nil);
}
- (BOOL)shouldAddContentEncoding {
    return (self.encoding != nil);
}
- (BOOL)shouldAddContentValue {
    return (self.contentValue != nil);
}
- (BOOL)shouldAddData {
    return (self.data != nil &&
            self.fileName != nil &&
            !self.shouldAddContentValue);
}
- (NSString *)contentDispositionString {

    if (self.shouldAddData) {
        return [NSString stringWithFormat:@"%@: %@; name=\"%@\"; filename=\"%@\"\r\n", TuneHttpRequestHeaderContentDisposition, self.disposition, self.contentName, self.fileName];
    } else {
        return [NSString stringWithFormat:@"%@: %@; name=\"%@\";\r\n", TuneHttpRequestHeaderContentDisposition, self.disposition, self.contentName];
    }
}
- (NSString *)contentTypeString {
    return [NSString stringWithFormat:@"%@: %@\r\n", TuneHttpRequestHeaderContentType, self.contentType];
}
- (NSString *)contentEncodingString {
    return [NSString stringWithFormat:@"%@: %@\r\n", TuneHttpRequestHeaderContentTransferEncoding, self.encoding];
}
- (NSString *)contentValueString {
    return [NSString stringWithFormat:@"\r\n%@\r\n", self.contentValue];
}

- (NSData *)multipartData {

    if (!self.disposition) { return nil; }

    NSString *dataString = [self contentDispositionString];

    if (self.shouldAddContentType) {
        dataString = [dataString stringByAppendingString:self.contentTypeString];
    }

    if (self.shouldAddContentEncoding) {
        dataString = [dataString stringByAppendingString:self.contentEncodingString];
    }

    if (self.shouldAddContentValue) {
        dataString = [dataString stringByAppendingString:self.contentValueString];
    }

    if (self.shouldAddData) {
        dataString = [dataString stringByAppendingString:@"\r\n"];
    }

    NSMutableData *data = [dataString dataUsingEncoding:self.contentEncoding].mutableCopy;

    if (self.shouldAddData) {
        [data appendData:self.data];
    }

    return data;
}

@end
