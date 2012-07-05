//
//  DDGCache.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/21/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGCache.h"
@interface DDGCache (Private)
+(void)loadCache:(NSString *)cacheName;
+(void)saveCache:(NSString *)cacheName;
+(NSString *)cachePath:(NSString *)cacheName;
@end

@implementation DDGCache

static NSMutableDictionary *globalCache;

// TODO: if performance ever becomes an issue, make the locking finer-grained
+(void)setObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache:cacheName];
        
        NSMutableDictionary *cache = [globalCache objectForKey:cacheName];
        if(!cache) {
            cache = [[NSMutableDictionary alloc] init];
            [globalCache setObject:cache forKey:cacheName];
        }
        if(!object)
            [cache removeObjectForKey:key];
        else
            [cache setObject:object forKey:key];
        
        [self saveCache:cacheName];
    }
}

+(id)objectForKey:(NSString *)key inCache:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache:cacheName];
        
        return [[globalCache objectForKey:cacheName] objectForKey:key];
    }
}

#pragma mark - Global cache management

+(void)loadCache:(NSString *)cacheName {
    if([globalCache objectForKey:cacheName])
        return; // already loaded
    
    if(!globalCache)
        globalCache = [[NSMutableDictionary alloc] initWithContentsOfFile:[self cachePath:nil]];
    if(!globalCache)
        globalCache = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *cache = [[NSMutableDictionary alloc] initWithContentsOfFile:[self cachePath:cacheName]];
    if(!cache)
        cache = [[NSMutableDictionary alloc] init];
    
    [globalCache setObject:cache forKey:cacheName];
}

+(void)saveCache:(NSString *)cacheName {
    [[globalCache objectForKey:cacheName] writeToFile:[self cachePath:cacheName] atomically:YES];
}

+(NSString *)cachePath:(NSString *)cacheName {
    if(cacheName)
        return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"cache%@.plist",cacheName]];
    else
        return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"cache.plist"];
}

@end
