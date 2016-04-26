//
//  TuneHttpResponse.h
//  Tune
//
//  Created by Kevin Jenkins on 4/11/13.
//
//

#import <Foundation/Foundation.h>

@interface TuneHttpResponse : NSObject

@property (nonatomic, strong) NSHTTPURLResponse *urlResponse;
@property (nonatomic, copy) NSDictionary *responseDictionary;
@property (nonatomic, strong) NSError *error;

- (id)initWithURLResponse:(NSHTTPURLResponse*)response andError:(NSError*)error;

- (BOOL)wasSuccessful;
- (BOOL)failed;

@end
