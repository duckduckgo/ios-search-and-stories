//
//  DDGAppDelegate.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "UtilityCHS.h"
#import "CacheControl.h"
#import "DataHelper.h"

@implementation DataHelper(Initialize)

+ (NSDictionary*)headerItemsForAllHTTPRequests
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			 [@"DDG iOS App v" stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]], @"User-Agent", 
			 @"http://duckduckgo.com", @"Referer",
			 nil];
}

@end

@implementation CacheControl(Initialize)

+ (NSArray*)userInitializePaths
{
	return [NSArray arrayWithObjects:@"transient", @"images", nil];
}

+ (NSArray*)userInitializeDays
{
	return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:0],
            [NSNumber numberWithInt:86400*31],
            nil];
}

@end

@implementation DDGAppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// turn off completely standard URL cacheing -- we use our own caching
	NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
	[NSURLCache setSharedURLCache:sharedCache];
	
	// create any caches needed -- only realy does anything first time through
	[CacheControl setupCaches];

    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:bundlePath];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dict];
    
    return YES;
}

@end
