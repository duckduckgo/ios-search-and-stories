//
//  DDGCache.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/21/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGCache.h"
@interface DDGCache (Private)
+(void)loadCache;
+(void)saveCache;
+(NSString *)cachePath;
@end

@implementation DDGCache

static NSMutableDictionary *globalCache;

+(void)setObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName {
    [self loadCache];
    
    NSMutableDictionary *cache = [globalCache objectForKey:cacheName];
    if(!cache) {
        cache = [[NSMutableDictionary alloc] init];
        [globalCache setObject:cache forKey:cacheName];
    }
    [cache setObject:object forKey:key];
    
    [self saveCache];
}

+(id)objectForKey:(NSString *)key inCache:(NSString *)cacheName {
    [self loadCache];
    
    return [[globalCache objectForKey:cacheName] objectForKey:key];
}

#pragma mark - Global cache management

+(void)loadCache {
    if(globalCache)
        return; // already loaded
    
    globalCache = [[NSMutableDictionary alloc] initWithContentsOfFile:[self cachePath]];
    if(!globalCache)
        globalCache = [[NSMutableDictionary alloc] init];
}

+(void)saveCache {
    [globalCache writeToFile:[self cachePath] atomically:YES];
}

+(NSString *)cachePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"cache.plist"];
}

@end
