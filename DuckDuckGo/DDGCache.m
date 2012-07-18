//
//  DDGCache.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/21/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGCache.h"

@implementation DDGCache

static NSMutableDictionary *globalCache;

+(void)setObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache];
        
        NSMutableDictionary *cache = [globalCache objectForKey:cacheName];
        if(!cache) {
            cache = [[NSMutableDictionary alloc] init];
            [globalCache setObject:cache forKey:cacheName];
        }
        
        if(!object)
            [cache removeObjectForKey:key];
        else
            [cache setObject:object forKey:key];
    }
}

+(id)objectForKey:(NSString *)key inCache:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache];
        
        return [[globalCache objectForKey:cacheName] objectForKey:key];
    }
}

#pragma mark - Global cache management

+(void)loadCache {
    if(globalCache)
        return; // already loaded
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:self.cachePath];
    if(data) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        globalCache = [[unarchiver decodeObjectForKey:@"key"] mutableCopy];
        [unarchiver finishDecoding];
    } else {
        globalCache = [[NSMutableDictionary alloc] init];
    }
}

+(void)saveCaches {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:globalCache forKey:@"key"];
    [archiver finishEncoding];
    
    [data writeToFile:self.cachePath atomically:YES];
}

+(NSString *)cachePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"cache"];
}

@end
