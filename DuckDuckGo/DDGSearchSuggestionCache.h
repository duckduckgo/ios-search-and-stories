//
//  DDGSearchSuggestionCache.h
//  DuckDuckGo
//
//  Created by Chris Heimark on 12/27/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDGSearchSuggestionCache : NSObject
{
	NSMutableDictionary			*serverCache;
}

+ (DDGSearchSuggestionCache*) sharedInstance;

@property (nonatomic, readonly) NSMutableDictionary			*serverCache;


@end
