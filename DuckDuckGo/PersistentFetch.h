//
//  PersistentFetch.h
//  T9
//
//  Created by Chris Heimark on 12/13/11.
//  Copyright (c) 2011 CHS Systems. All rights reserved.
//
// PersistentFetch.m
//
// Copyright (c) 2010 Adam Strzelecki
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

@class PersistentFetch;

@protocol PersistentFetchDelegate

- (void)fetch:(PersistentFetch *)fetch didFailWithError:(NSError *)error;
- (void)fetchDidFinishLoading:(PersistentFetch *)connection;
- (void)fetch:(PersistentFetch *)fetch didReceiveStatusCode:(NSInteger)statusCode contentLength:(NSInteger)contentLength;

@end

@interface PersistentFetch : NSObject

// Internal
@property (nonatomic, retain) id<PersistentFetchDelegate> delegate;
@property (assign) NSInteger tag;
@property (assign) CFReadStreamRef stream;
@property (assign) BOOL gotHeaders;

// Set by the user
@property (nonatomic, retain) NSMutableData *data;

- (id)initWithURL:(NSURL *)url delegate:(id<PersistentFetchDelegate>)_delegate tag:(NSInteger)_tag;

+ (PersistentFetch *)fetchURL:(NSURL *)url delegate:(id<PersistentFetchDelegate>)delegate tag:(NSInteger)tag;

- (void)cancel;
+ (void)cleanupPersistentConnections;

@end