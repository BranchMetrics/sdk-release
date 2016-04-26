//
//  NSURLSession+SynchronousTask.h
//
//  Copyright (c) 2015 Florian Schliep (http://floschliep.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>

@interface NSURLSession (SynchronousTask)

#pragma mark - NSURLSessionDataTask

#if IDE_XCODE_7_OR_HIGHER
- (nullable NSData *)sendSynchronousDataTaskWithURL:(nonnull NSURL *)url returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error;
- (nullable NSData *)sendSynchronousDataTaskWithRequest:(nonnull NSURLRequest *)request returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error;
#else
- (nullable NSData *)sendSynchronousDataTaskWithURL:(nonnull NSURL *)url returningResponse:( NSURLResponse * __nonnull * __nonnull)response error:(NSError * __nullable * __nullable)error;
- (nullable NSData *)sendSynchronousDataTaskWithRequest:(nonnull NSURLRequest *)request returningResponse:(NSURLResponse * __nonnull * __nonnull)response error:(NSError * __nullable * __nullable)error;
#endif

#pragma mark - NSURLSessionDownloadTask

#if IDE_XCODE_7_OR_HIGHER
- (nullable NSURL *)sendSynchronousDownloadTaskWithURL:(nonnull NSURL *)url returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error;
- (nullable NSURL *)sendSynchronousDownloadTaskWithRequest:(nonnull NSURLRequest *)request returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error;
#else
- (nullable NSURL *)sendSynchronousDownloadTaskWithURL:(nonnull NSURL *)url returningResponse:(NSURLResponse * __nonnull * __nonnull)response error:(NSError * __nullable * __nullable)error;
- (nullable NSURL *)sendSynchronousDownloadTaskWithRequest:(nonnull NSURLRequest *)request returningResponse:(NSURLResponse * __nonnull* __nonnull)response error:(NSError * __nullable * __nullable)error;
#endif

#pragma mark - NSURLSessionUploadTask

#if IDE_XCODE_7_OR_HIGHER
- (nullable NSData *)sendSynchronousUploadTaskWithRequest:(nonnull NSURLRequest *)request fromFile:(nonnull NSURL *)fileURL returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error;
- (nullable NSData *)sendSynchronousUploadTaskWithRequest:(nonnull NSURLRequest *)request fromData:(nonnull NSData *)bodyData returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error;
#else
- (nullable NSData *)sendSynchronousUploadTaskWithRequest:(nonnull NSURLRequest *)request fromFile:(nonnull NSURL *)fileURL returningResponse:(NSURLResponse * __nonnull * __nonnull)response error:(NSError * __nullable * __nullable)error;
- (nullable NSData *)sendSynchronousUploadTaskWithRequest:(nonnull NSURLRequest *)request fromData:(nonnull NSData *)bodyData returningResponse:(NSURLResponse * __nonnull * __nonnull)response error:(NSError * __nullable * __nullable)error;
#endif

@end
