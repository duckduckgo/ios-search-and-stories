//
//  NetworkActivityStatus.m
//  DuckDuckGo, Inc
//
//  Created by Chris Heimark on 8/31/09.
//  Copyright 2009 DuckDuckGo, Inc. All rights reserved.
//

#import "NetworkActivityStatus.h"


@implementation NetworkActivityStatus

static NetworkActivityStatus *sharedNetworkActivityManager = nil;
static NSInteger activityCount = 0; // count activity

+ (NetworkActivityStatus*)sharedManager
{
	@synchronized(self)
	{
        if (!sharedNetworkActivityManager)
		{
			sharedNetworkActivityManager = [[self alloc] init];
        }
    }
    return sharedNetworkActivityManager;
}

- (void)activityStarted:(BOOL)started
{
	if (started)
	{
		// activity is beginning
		++activityCount;

		// explicitly set this in case outside thread activity may have stopped before it should have
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
	else
	{
		if (--activityCount <= 0)
		{
			// stop indicator ONLY if our count gets back to 0 OR less
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
			// unbalanced calls require a stop at 0
			activityCount = 0;
		}
	}
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
