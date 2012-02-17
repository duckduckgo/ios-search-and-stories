//
//  DDGAppDelegate.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "UtilityCHS.h"
#import "CacheController.h"
#import "DataHelper.h"
#import "SDURLCache.h"

@implementation DDGAppDelegate

@synthesize window = _window;

static void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    // global URL cache
    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024*2 // 2MB mem cache
                                                         diskCapacity:1024*1024*5 // 5MB disk cache
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:urlCache];
    
    // define caches
    [CacheController addCache:kCacheIDTransient lifetimeSeconds:0];
    [CacheController addCache:kCacheIDImages lifetimeSeconds:60*60*24*31];
	// create cache directories if they don't already exist
	[CacheController initializeCaches];

    // set HTTP headers for all requests
    [DataHelper setHTTPHeaders:[NSDictionary dictionaryWithObjectsAndKeys:
                                [@"DDG iOS App v" stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]], @"User-Agent", 
                                @"http://duckduckgo.com", @"Referer",
                                nil]];
    
    
    // load default settings from Defaults.plist (as of now, though, we have neither settings nor Defaults.plist)
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:bundlePath];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    return YES;
}

@end
