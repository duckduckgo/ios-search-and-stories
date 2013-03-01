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
#import "AFNetworking.h"

@implementation DDGAppDelegate

static void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
#if DEBUG == 1
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // use deprecated uniqueIdentifier call for debug purposes only
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang diagnostic pop
#endif
    [TestFlight takeOff:@"7ed983ce368c469fdc805f409ddd5230_Njk5NDUyMDEyLTAzLTA5IDEwOjExOjU1LjY0NzQ1Mg"];    
    
    // set the global URL cache to SDURLCache, which caches to disk
    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024*2 // 2MB mem cache
                                                         diskCapacity:1024*1024*10 // 10MB disk cache
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:urlCache];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];    
    
    // load default settings
    [DDGSettingsViewController loadDefaultSettings];
    
    // initialize sharekit
    DefaultSHKConfigurator *configurator = [[DDGSHKConfigurator alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];
    
    // configure the sliding view controller
    ECSlidingViewController *slidingViewController = (ECSlidingViewController *)self.window.rootViewController;    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    slidingViewController.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];

    [[UINavigationBar appearance] setShadowImage:[UIImage imageNamed:@"header_shadow"]];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header_tile"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header_lp_tile"] forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithRed:0.29 green:0.30 blue:0.32 alpha:1.0],
														UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
														UITextAttributeTextShadowColor : [UIColor whiteColor]
	 }];
    
    UIImage *bg = [[UIImage imageNamed:@"button-bg"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:0.0];
    UIImage *bgh = [[UIImage imageNamed:@"button-bg-highlighted"] stretchableImageWithLeftCapWidth:2.0 topCapHeight:0.0];
    
    [[UIBarButtonItem appearance] setBackgroundImage:bg forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:bgh forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, 1.0) forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithRed:0.403 green:0.406 blue:0.427 alpha:1.000],
                        UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                         UITextAttributeTextShadowColor : [UIColor whiteColor]
	 } forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithRed:0.581 green:0.585 blue:0.607 alpha:1.000],
                        UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                         UITextAttributeTextShadowColor : [UIColor whiteColor]
	 } forState:UIControlStateDisabled];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithWhite:0.995 alpha:1.000],
                        UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
                         UITextAttributeTextShadowColor : [UIColor colorWithRed:0.170 green:0.185 blue:0.199 alpha:1.000]
	 } forState:UIControlStateHighlighted];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [DDGCache saveCaches];
}

-(void)applicationWillResignActive:(UIApplication *)application {
    [DDGCache saveCaches];    
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
    [DDGCache saveCaches];
}

@end