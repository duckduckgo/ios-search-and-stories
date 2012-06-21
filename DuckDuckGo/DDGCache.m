//
//  DDGCache.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/21/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGCache.h"
@interface DDGCache (Private)
+(void)load;
+(void)save;
+(NSString *)cachePath;
@end

@implementation DDGCache

static NSMutableDictionary *globalCache;

+(void)storeObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName {
    [self load];
    
    NSMutableDictionary *cache = [globalCache objectForKey:cacheName];
    if(!cache) {
        cache = [[NSMutableDictionary alloc] init];
        [globalCache setObject:cache forKey:cacheName];
    }
    [cache setObject:object forKey:key];
    
    [self save];
}

+(id)object:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName {
    [self load];
    
    return [[globalCache objectForKey:cacheName] objectForKey:key];
}

+(void)load {
    if(globalCache)
        return; // already loaded
    
    globalCache = [NSMutableDictionary dictionaryWithContentsOfFile:[self cachePath]];
    if(!globalCache)
        globalCache = [[NSMutableDictionary alloc] init];
}

+(void)save {
    [globalCache writeToFile:[self cachePath] atomically:YES];
}

-(NSString *)cachePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"cache.plist"];
}

@end
