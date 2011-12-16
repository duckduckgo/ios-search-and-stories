//
//  NetworkActivityStatus.m
//  DuckDuckGo, Inc
//
//  Created by Chris Heimark on 8/31/09.
//  Copyright 2009 DuckDuckGo, Inc. All rights reserved.
//

#import "NetworkActivityStatus.h"


@implementation NetworkActivityStatus

static NetworkActivityStatus	*sharedNetworkActivityManager = nil;

// count activity
static NSInteger				activityCount = 0;

+ (NetworkActivityStatus*)sharedManager
{
	@synchronized(self)
	{
        if (!sharedNetworkActivityManager)
		{
			// assignment not done here
            [[self alloc] init]; 
        }
    }
    return sharedNetworkActivityManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
        if (!sharedNetworkActivityManager)
		{
            sharedNetworkActivityManager = [super allocWithZone:zone];
            return sharedNetworkActivityManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
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

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
