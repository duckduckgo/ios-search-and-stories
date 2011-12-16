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

+ (void)setupCaches;
+ (void)purgeCache:(NSInteger)cacheID flushAll:(BOOL)flushAll;
+ (void)purgeCaches;

+ (NSString *)cacheName:(NSInteger)cacheID;
+ (NSInteger)cacheSeconds:(NSInteger)cacheID;
+ (NSString *)cacheRootPathForStore:(NSUInteger)cacheStore;
+ (NSString *)cachePathForStore:(NSUInteger)cacheStore name:(NSString*)cacheEntry;

@end

@interface CacheControl(Initialize)

+ (NSArray*)userInitializePaths;
+ (NSArray*)userInitializeDays;

@end
