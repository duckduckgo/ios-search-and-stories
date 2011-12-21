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
	return [[NSDictionary dictionaryWithObjectsAndKeys:
			 [@"DDG iOS App v" stringByAppendingString:[UtilityCHS versionOfSoftware]],	@"User-Agent", 
			 @"http://duckduckgo.com",													@"Referer",
			 nil] retain];
}

@end

@implementation CacheControl(Initialize)

+ (NSArray*)userInitializePaths
{
	return [[NSArray arrayWithObjects:@"transient", @"images",	@"topics", nil] retain];
}

+ (NSArray*)userInitializeDays
{
	return [[NSArray arrayWithObjects:
			 [NSNumber numberWithInt:0],
			 [NSNumber numberWithInt:86400*31],
			 [NSNumber numberWithInt:86400*1],
			 nil] retain];
}

@end

@implementation DDGAppDelegate

@synthesize window = _window;

- (void)dealloc
{
	[_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// turn off completely standard URL cacheing -- we use our own cacheing
	NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
	[NSURLCache setSharedURLCache:sharedCache];
	[sharedCache release];
	
    // Override point for customization after app launch    
	// create any caches needed -- only realy does anything first time through
	[CacheControl setupCaches];
	
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:bundlePath];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dict];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

@end
