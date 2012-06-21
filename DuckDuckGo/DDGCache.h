//
//  DDGCache.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/21/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDGCache : NSObject

+(void)storeObject:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName;
+(id)object:(id)object forKey:(NSString *)key inCache:(NSString *)cacheName;

@end
