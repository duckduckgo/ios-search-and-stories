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

+(void)updateObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache:cacheName];
        
        NSMutableDictionary *cache = [globalCache objectForKey:cacheName];
        
        if([cache objectForKey:key])
            [cache setObject:object forKey:key];
    }
}

+(void)setObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache:cacheName];
        
        NSMutableDictionary *cache = [globalCache objectForKey:cacheName];
        
        if(!object)
            [cache removeObjectForKey:key];
        else
            [cache setObject:object forKey:key];
    }
}

+(id)objectForKey:(NSString *)key inCache:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache:cacheName];
        
        return [[globalCache objectForKey:cacheName] objectForKey:key];
    }
}

+(NSDictionary *)cacheNamed:(NSString *)cacheName {
    @synchronized(globalCache) {
        [self loadCache:cacheName];
        
        return [globalCache objectForKey:cacheName];
    }
}

#pragma mark - Global cache management

+(void)loadCache:(NSString *)cacheName {
    if(!globalCache) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:self.cachePath];
        if(data) {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            globalCache = [[unarchiver decodeObjectForKey:@"key"] mutableCopy];
            [unarchiver finishDecoding];
        } else {
            globalCache = [[NSMutableDictionary alloc] init];
        }
    } else if(![globalCache objectForKey:cacheName]) {
        [globalCache setObject:[[NSMutableDictionary alloc] init] forKey:cacheName];
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
