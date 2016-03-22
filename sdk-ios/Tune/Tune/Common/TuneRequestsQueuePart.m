//
//  TuneRequestsQueuePart.m
//  Tune
//
//  Created by Pavel Yurchenko on 7/26/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "TuneRequestsQueuePart.h"
#import "TuneKeyStrings.h"
#import "TuneXmlHelper.h"

const NSUInteger REQUESTS_MAX_COUNT_IN_PART =  50;

const NSUInteger MAX_LEGACY_QUEUE_PART_XML_SIZE = 51200; // 50 KB

NSString * const XML_NODE_QUEUEPART = @"QueuePart";
NSString * const XML_NODE_REQUEST = @"Request";

@interface TuneRequestsQueuePart()

@property (nonatomic, retain) NSMutableArray * requests;

@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, assign) NSUInteger loadedRequestsCount;

- (NSString*)generateFileName;

@end


@implementation TuneRequestsQueuePart

@dynamic index;
@dynamic requestsLimitReached;
@dynamic empty;
@dynamic queuedRequestsCount;

@synthesize modified = modified_;
@synthesize fileName = fileName_;
@synthesize filePathName = filePathName_;
@synthesize parentFolder = parentFolder_;

@synthesize requests = requests_;
@synthesize loaded = loaded_;
@synthesize shouldLoadOnRequest = shouldLoadOnRequest_;
@synthesize loadedRequestsCount = loadedRequestsCount_;

- (NSInteger)index
{
    return index_;
}

- (void)setIndex:(NSInteger)targetIndex
{
    index_ = targetIndex;
    [self generateFileName];
    self.modified = YES;
}

- (BOOL)requestsLimitReached
{
    @synchronized( requests_ ) {
        return ([self.requests count] >= REQUESTS_MAX_COUNT_IN_PART);
    }
}

- (BOOL)empty
{
    @synchronized( requests_ ) {
        return ([self.requests count] == 0);
    }
}

- (NSUInteger)queuedRequestsCount
{
    @synchronized( requests_ ) {
        if (self.requests && [self.requests count] > 0)
        {
            return [self.requests count];
        }
    }
    
    return self.loadedRequestsCount;
}

- (void)setQueuedRequestsCount:(NSUInteger)count
{
    self.loadedRequestsCount = count;
}

+ (id)partWithIndex:(NSInteger)targetIndex parentFolder:(NSString *)parentFolder
{
    return [[TuneRequestsQueuePart alloc] initWithIndex:targetIndex parentFolder:parentFolder];
}

- (id)initWithIndex:(NSInteger)targetIndex parentFolder:(NSString *)parentDir
{
    self = [super init];
    
    if (self)
    {
        index_ = targetIndex;
        self.parentFolder = parentDir;
        [self generateFileName];
        modified_ = NO;
        self.requests = [NSMutableArray array];
    }
    
    return self;
}


- (BOOL)push:(NSDictionary*)requestData
{
    DLog(@"TuneReqQuePart: push: %@", requestData);
    
    if (self.requestsLimitReached)
        return NO;
    
    @synchronized( requests_ ) {
        [requests_ addObject:requestData];
    }
    
    self.modified = YES;
    
    return YES;
}

- (BOOL)pushToHead:(NSDictionary*)requestData
{
    DLog(@"TuneReqQuePart: pushToHead: %@", requestData);
    
    if (self.requestsLimitReached) return NO;
    
    @synchronized( requests_ ) {
        [requests_ insertObject:requestData atIndex:0];
    }
    
    self.modified = YES;
    
    return YES;
}

- (NSDictionary*)pop
{
    NSDictionary * requestData = nil;
    
    DLog(@"TuneReqQuePart: pop: filePath      = %@", self.filePathName);
    DLog(@"TuneReqQuePart: pop: requestsCnt   = %lu", (unsigned long)self.requests.count);
    DLog(@"TuneReqQuePart: pop: loadedReqCnt  = %lu", (unsigned long)self.loadedRequestsCount);
    DLog(@"TuneReqQuePart: pop: shouldLoad    = %d", self.shouldLoadOnRequest);
    
    /// Load requests from file if should load is set
    @synchronized( requests_ ) {
        if ([requests_ count] == 0 && self.shouldLoadOnRequest)
        {
            [self load];
        }
    
        if ([requests_ count] > 0)
        {
            requestData = [requests_ objectAtIndex:0];
        
            [requests_ removeObjectAtIndex:0];
            self.modified = YES;
        }
    }
    
    DLog(@"TuneReqQuePart: pop: remaining requests queue size = %lu", (unsigned long)requests_.count);
    
    DLog(@"TuneReqQuePart: pop: %@", requestData);
    return requestData;
}

- (BOOL)load
{
    DLog(@"TuneReqQuePart: load: fileName = %@, is already loaded: %d", self.fileName, self.loaded);
    if (!self.loaded)
    {
        NSData * fileData = [NSData dataWithContentsOfFile:self.filePathName];
        
#if DEBUG_LOG
        NSLog(@"TuneReqQuePart: load: data length = %lu", (unsigned long)fileData.length);
        
        NSString *strFileData = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        NSLog(@"TuneReqQuePart: load: data to be parsed = %@", strFileData);
#endif
        
        if (fileData)
        {
            // ignore the legacy queue xml file if it's too big to parse,
            // so that the NSXMLParser does not run out of memory
            if(fileData.length < MAX_LEGACY_QUEUE_PART_XML_SIZE)
            {
                NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:fileData];
                [xmlParser setDelegate:self];
                [xmlParser parse];
            }
#if DEBUG_LOG
            else
            {
                DLog(@"ignore xml file, too big to parse = %d", (int)fileData.length);
            }
#endif
            
            self.loaded = YES;
            self.shouldLoadOnRequest = NO;
        }
    }
    
    return self.loaded;
}

- (NSString*)serialize
{
    NSMutableString *strDescr = [NSMutableString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@>", XML_NODE_QUEUEPART];
    
    @synchronized( requests_ ) {
        for (NSDictionary * request in self.requests)
        {
            // clean up the text to make it compliant with XML
            NSString *urlValue = [request valueForKey:TUNE_KEY_URL];
            NSString *encodedUrl = [TuneXmlHelper tuneGtm_stringBySanitizingAndEscapingForXML:urlValue];
            
            NSString *encrypt = [request valueForKey:TUNE_KEY_DATA];
            NSString *encodedEncrypt = [TuneXmlHelper tuneGtm_stringBySanitizingAndEscapingForXML:encrypt];
            encodedEncrypt = encodedEncrypt ? [NSString stringWithFormat:@" %@=\"%@\"", TUNE_KEY_DATA, encodedEncrypt] : TUNE_STRING_EMPTY;
            
            NSString *jsonValue = [request valueForKey:TUNE_KEY_JSON];
            NSString *encodedJson = [TuneXmlHelper tuneGtm_stringBySanitizingAndEscapingForXML:jsonValue];
            encodedJson = encodedJson ? [NSString stringWithFormat:@" %@=\"%@\"", TUNE_KEY_JSON, encodedJson] : TUNE_STRING_EMPTY;
            
            NSDate *runDate = [request valueForKey:TUNE_KEY_RUN_DATE];
            NSString *encodedDate = [runDate description];
            encodedDate = encodedDate ? [NSString stringWithFormat:@" %@=\"%@\"", TUNE_KEY_RUN_DATE, encodedDate] : TUNE_STRING_EMPTY;
            
            // serialize the request
            [strDescr appendFormat:@"<%@ %@=\"%@\"%@%@%@></%@>", XML_NODE_REQUEST, TUNE_KEY_URL, encodedUrl, encodedEncrypt, encodedJson, encodedDate, XML_NODE_REQUEST];
        }
    }
    
    [strDescr appendFormat:@"</%@>", XML_NODE_QUEUEPART];
    
    DLog(@"TuneRequestsQueuePart serialize output = %@", strDescr);
    
    return strDescr;
}

- (void)save
{
    DLog(@"TuneReqQuePart save");
    NSError * error = nil;
    NSString *strDescr = [self serialize];
    [strDescr writeToFile:self.filePathName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
#if DEBUG_LOG
    
    if (error)
    {
        NSLog(@"TuneReqQuePart: save: error = %@", [error localizedDescription]);
    }
    
    NSError *error1 = nil;
    NSString *content = [NSString stringWithContentsOfFile:self.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error1];
    NSLog(@"TuneReqQuePart: save: read: error1  = %@", error1);
    NSLog(@"TuneReqQuePart: save: read: path    = %@", self.filePathName);
    NSLog(@"TuneReqQuePart: save: read: content = %@", content);
#endif
    
    self.modified = NO;
}

- (NSString*)description
{
    return [self serialize];
}


- (NSString*)generateFileName
{
    self.fileName = [NSString stringWithFormat:@"queue_part_%ld.xml", (long)self.index];
    
    DLog(@"TuneReqQuePart: generateFileName: dir  = %@", self.parentFolder);
    DLog(@"TuneReqQuePart: generateFileName: file = %@", self.fileName);
    
    self.filePathName = [self.parentFolder stringByAppendingPathComponent:self.fileName];
    
#if DEBUG_LOG
    NSLog(@"TuneReqQuePart: generateFileName: fileName     = %@", self.fileName);
    NSLog(@"TuneReqQuePart: generateFileName: filePathName = %@", self.filePathName);
    
    NSError *error2 = nil;
    NSString* content = [NSString stringWithContentsOfFile:self.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error2];
    NSLog(@"TuneReqQuePart: generateFileName: read: error2  = %@", error2);
    NSLog(@"TuneReqQuePart: generateFileName: read: path    = %@", self.filePathName);
    NSLog(@"TuneReqQuePart: generateFileName: read: content = %@", content);
#endif
    
    return self.fileName;
}

- (NSComparisonResult)indexComparator:(TuneRequestsQueuePart*)other
{
    if (self.index < other.index)
    {
        return NSOrderedAscending;
    }
    else if (self.index > other.index)
    {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}

#pragma mark mark - NSXMLParser Delegate Methods

// sent when the parser finds an element start tag.
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    DLog(@"TuneReqQuePart: parser: elementName = %@", elementName);
    
    if([elementName isEqualToString:XML_NODE_REQUEST])
    {
        DLog(@"TuneReqQuePart: parser: create object using: %@", attributeDict);
        
        [self push:[NSDictionary dictionaryWithDictionary:attributeDict]];
    }
}

@end
