//
//  CacheControl.h
//
//  Created by Chris Heimark on 12/12/08.
//  Copyright 2008 © DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheControl : NSObject 
{
}

+ (void)addCache:(NSString *)cacheID lifetimeSeconds:(NSInteger)lifetimeSeconds;
+ (void)initializeCaches;

+ (void)purgeCache:(NSString *)cacheID flushAll:(BOOL)flushAll;
+ (void)purgeAllCaches;

+ (NSInteger)lifetimeSecondsForCache:(NSString *)cacheID;
+ (NSString *)pathForCache:(NSString *)cacheID;
+ (NSString *)pathForCache:(NSString *)cacheID entry:(NSString *)cacheEntry;

@end