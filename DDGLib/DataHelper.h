//
//  DataHelper.h
//
//  Created by Chris Heimark on 10/13/09.
//  Copyright 2009 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "NetworkActivityStatus.h"
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

+(void)setHTTPHeaders:(NSDictionary *)headers;
- (id)initWithDelegate:(id<DataHelperDelegate>)delegate;

- (NSData*)retrieve:(id)urlOrRequest cache:(NSString *)cacheID name:(NSString*)name returnData:(BOOL)returnData identifier:(NSInteger)ID bufferSize:(NSUInteger)capacity;

-(void)flushAllIO;
-(void)flushIdentifierIO:(NSInteger)ID;
-(BOOL)isIdentifierPendingIO:(NSInteger)ID;
-(BOOL)isRequestOutstandingForCache:(NSString *)cacheID name:(NSString*)name identifier:(NSInteger)ID;

@end