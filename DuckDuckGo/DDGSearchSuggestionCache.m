//
//  DDGSearchSuggestionCache.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 12/27/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchSuggestionCache.h"

@implementation DDGSearchSuggestionCache

@synthesize serverCache;

- (id)init
{
	self = [super init];
	if (self)
	{
		serverCache = [[NSMutableDictionary alloc] initWithCapacity:8];
	}
	return self;
}

#define SINGLETON_CLASS_NAME		DDGSearchSuggestionCache
#define SINGLETON_INIT_SELECTOR		init
#import "Singleton.h"

@end
