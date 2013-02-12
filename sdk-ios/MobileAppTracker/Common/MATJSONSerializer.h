#import <Foundation/Foundation.h>

@interface MATJSONSerializer : NSObject {
}

+ (id)serializer;

- (NSString *)serializeObject:(id)inObject;

- (NSString *)serializeNull:(NSNull *)inNull;
- (NSString *)serializeNumber:(NSNumber *)inNumber;
- (NSString *)serializeString:(NSString *)inString;
- (NSString *)serializeArray:(NSArray *)inArray;
- (NSString *)serializeDictionary:(NSDictionary *)inDictionary;

@end
