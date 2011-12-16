//
//  DataHelper.h
//
//  Created by Chris Heimark on 10/13/09.
//  Copyright 2009 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "NetworkActivityStatus.h"
#include "CacheControl.h"
#include "UtilityCHS.h"


@protocol DataHelperDelegate

- (void)dataReceivedWith:(NSInteger)identifier andData:(NSData*)data andStatus:(NSInteger)status;
- (void)redirectReceived:(NSInteger)identifier withURL:(NSString*)url;
- (void)errorReceived:(NSInteger)identifier withError:(NSError*)error;

@optional
- (void)dataReceived:(NSInteger)identifier withStatus:(NSInteger)status;

@end

@interface DataHelper : NSObject
{
	id<DataHelperDelegate>		delegate;
	NSMutableSet				*connections;
}

- (id)initWithDelegate:(id<DataHelperDelegate>)delegate;

- (NSData*)retrieve:(id)urlOrRequest store:(NSUInteger)cacheStore name:(NSString*)cacheName returnData:(BOOL)returnData identifier:(NSInteger)ID bufferSize:(NSUInteger)capacity;

-(void)flushAllIO;
-(void)flushIdentifierIO:(NSInteger)ID;
-(BOOL)isIdentifierPendingIO:(NSInteger)ID;
-(BOOL)isRequestOutstandingForStore:(NSUInteger)cacheStore name:(NSString*)cacheName identifier:(NSInteger)ID;

@end

@interface DataHelper(Initialize)

+ (NSDictionary*)headerItemsForAllHTTPRequests;

@end

#define kCacheStoreIndexNoFileCache -1
