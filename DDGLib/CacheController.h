//
//  CacheControl.h
//
//  Created by Chris Heimark on 12/12/08.
//  Copyright 2008 © DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheController : NSObject 
{
}

+ (void)addCache:(NSString *)cacheID lifetimeSeconds:(NSInteger)lifetimeSeconds;
+ (void)initializeCaches;

+ (void)purgeCache:(NSString *)cacheID flushAll:(BOOL)flushAll;
+ (void)purgeAllCaches;

// accessing cache properties
+ (NSInteger)lifetimeSecondsForCache:(NSString *)cacheID;
+ (BOOL)entryExistsForCache:(NSString *)cacheID entry:(NSString *)cacheEntry;

+(NSData *)dataForCache:(NSString *)cacheID entry:(NSString *)cacheEntry;
+(BOOL)writeData:(NSData *)data toCache:(NSString *)cacheID entry:(NSString *)cacheEntry;

@end