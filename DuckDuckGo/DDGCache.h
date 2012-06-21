//
//  DDGCache.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/21/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//


//TODO: implement a clearing mechanism
#import <Foundation/Foundation.h>

@interface DDGCache : NSObject

+(void)setObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName;
+(id)objectForKey:(NSString *)key inCache:(NSString *)cacheName;

@end
