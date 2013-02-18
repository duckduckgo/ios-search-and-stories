//
//  DDGAppDelegate.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGHistoryProvider.h"
#import "SDURLCache.h"
#import "DDGCache.h"
#import "DDGSettingsViewController.h"
#import "DDGSHKConfigurator.h"
#import "DDGSHKFormController.h"
#import "SHKConfiguration.h"
#import "DDGNewsProvider.h"
#import "ECSlidingViewController.h"

@implementation DDGAppDelegate

static void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    // set the global URL cache to SDURLCache, which caches to disk
    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024*2 // 2MB mem cache
                                                         diskCapacity:1024*1024*10 // 10MB disk cache
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:urlCache];
    
    // load default settings
    [DDGSettingsViewController loadDefaultSettings];
    
    // initialize sharekit
    DefaultSHKConfigurator *configurator = [[DDGSHKConfigurator alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];
    
    // configure the sliding view controller
    ECSlidingViewController *slidingViewController = (ECSlidingViewController *)self.window.rootViewController;    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    slidingViewController.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];

    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header_tile.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header_lp_tile.png"] forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithRed:0.29 green:0.30 blue:0.32 alpha:1.0],
														UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
														UITextAttributeTextShadowColor : [UIColor whiteColor]
	 }];
    
    return YES;
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
    [DDGCache saveCaches];
}

@end