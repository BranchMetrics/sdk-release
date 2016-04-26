//
//  CWorks.m
//  CWorks
//
//  Created by Anupam Tulsyan on 3/28/12.
//  Copyright (c) 2012 ConversionWorks.org.
//

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "TuneCWorks.h"

static NSString * kConversionWorksKey = @"CWorks";
static NSString * kConversionWorksDomain = @"Conversionworks.org";

//private utility functions
@interface TuneCWorks (Private)

+ (NSString *)TUNE_getMD5:(NSString *) str;
+ (NSMutableDictionary *)TUNE_getDictFromPasteBoard:(id)pboard;
+ (void)TUNE_setDict:(id)dict forPasteboard:(id)pboard;

@end

@implementation TuneCWorks

/*
 private method to get the md5 of a string.
 it is used to hash the appid and network name before storing to the pasteboard.
 */

+ (NSString *)TUNE_getMD5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (unsigned int)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

/*
 Private method to get the existing dictionary for a given pasteboard.
 returns nil if the dictionary is not present.
 */
+ (NSMutableDictionary*)TUNE_getDictFromPasteboard:(id)pboard
{
    id item = nil;

#if TARGET_OS_IOS
    item = [pboard dataForPasteboardType:kConversionWorksDomain];

    if (item)
    {
        item = [NSKeyedUnarchiver unarchiveObjectWithData:item];
    }
#endif
    // return an instance of a MutableDictionary
    return [NSMutableDictionary dictionaryWithDictionary:(item == nil || [item isKindOfClass:[NSDictionary class]]) ? item : nil];
}

/*
 Private method to set the dictionary for the given pasteboard. It overrides the existing dictionary if any
 */

+ (void)TUNE_setDict:(id)dict forPasteboard:(id)pboard
{
#if TARGET_OS_IOS
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:dict] forPasteboardType:kConversionWorksDomain];
#endif
}

/*
 Public Method to return all the clicks for a particular app ID.
 This method needs to be called when the app is first activated by the user.
 It returns a dictionary of key value where key is composed of network name
 and timestamp.
 
 Note:
    !!
        After returning the dictionary this method clears the existing
        pasteboard for all the clicks generated for this app.
    !!
 */
+ (NSDictionary*)TUNE_getClicks:(NSString*) appID
{
    NSMutableDictionary *dictClicks = nil;
    
#if TARGET_OS_IOS
    @synchronized(self) {
        if([appID length] > 0)
        {
            NSString *pbName = [NSString stringWithFormat:@"%@.%@", kConversionWorksKey, [self TUNE_getMD5:appID]];
            
            UIPasteboard *convPB = [UIPasteboard pasteboardWithName:pbName create:NO];
            
            dictClicks = [NSMutableDictionary new];
            
            if(convPB != nil)
            {
                NSMutableDictionary *dict = [self TUNE_getDictFromPasteboard:convPB];
                
                //get all the clicks
                for(NSString *key in dict)
                {
                    if([key hasPrefix:@"c"])
                    {
                        NSString * value = (NSString *)[dict objectForKey:key];
                        if(value != nil)
                        {
                            [dictClicks setObject:value forKey:key];
                        }
                    }
                }
                [dict removeObjectsForKeys:[dictClicks allKeys]];
                //not removing the pasteboard because if there is a re-install event the pasteboard will be invalid
                [self TUNE_setDict:dict forPasteboard:convPB];
            }
        }
    }
#endif
    
    return dictClicks;
}

/*
 Public Method to return all the Impressions for a particular app ID. This method needs to be called 
 when the app is first activated by the user.
 It returns a dictionary of key value where key is composed of network name
 and timestamp. After returning the dictionary this method clears the existing pasteboard 
 for all the impressions generate for this app.
 */
+ (NSDictionary*)TUNE_getImpressions:(NSString*) appID
{
    NSMutableDictionary *dictImpressions = nil;
#if TARGET_OS_IOS
    if([appID length] > 0)
    {
        NSString *pbName = [NSString stringWithFormat:@"%@.%@", kConversionWorksKey, [self TUNE_getMD5:appID]];

        UIPasteboard *convPB = [UIPasteboard pasteboardWithName:pbName create:NO];
        dictImpressions = [NSMutableDictionary new];
        if(convPB != nil)
        {
            NSMutableDictionary * dict = [self TUNE_getDictFromPasteboard:convPB];

            //get all the impressions
            for(NSString *key in dict)
            {
                if([key hasPrefix:@"i"])
                {
                    NSString * value = (NSString *)[dict objectForKey:key];
                    if(value != nil)
                    {
                        [dictImpressions setObject:value forKey:key];
                    }
                }
            }

            //remove all the impressions from the dict
            [dict removeObjectsForKeys:[dictImpressions allKeys]];

            //not removi ng the pasteboard because if there is a re-install event the pasteboard will be invalid
            [self TUNE_setDict:dict forPasteboard:convPB];
        }
    }
#endif
    return dictImpressions;
}
@end
