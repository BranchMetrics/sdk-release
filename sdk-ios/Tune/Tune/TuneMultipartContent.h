//
//  TuneMultipartContent.h
//  Tune
//
//  Created by Kevin Jenkins on 7/21/13.
//
//

#import <Foundation/Foundation.h>

extern NSString *const TuneMultipartContentDispositionFormData;

@interface TuneMultipartContent : NSObject

@property (nonatomic, copy) NSString *disposition;
@property (nonatomic, copy) NSString *contentName;
@property (nonatomic, copy) NSString *contentValue;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, copy) NSString *encoding;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSData *data;
@property (assign, nonatomic) NSStringEncoding contentEncoding;

+ (id)content;
- (NSData *)multipartData;

@end
