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
#import "DDGNewsProvider.h"
#import "ECSlidingViewController.h"
#import "AFNetworking.h"
#import "DDGUnderViewController.h"
#import "DDGSearchController.h"

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
    [TestFlight takeOff:@"a6dad165-a8d4-495c-89c6-f3812248d554"];
    
    // set the global URL cache to SDURLCache, which caches to disk
    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024*2 // 2MB mem cache
                                                         diskCapacity:1024*1024*10 // 10MB disk cache
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:urlCache];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // audio session
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok;
    NSError *error = nil;
    ok = [audioSession setActive:NO error:&error];
    if (!ok)
        NSLog(@"%s audioSession setActive:NO error=%@", __PRETTY_FUNCTION__, error);

    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback
                             error:&error];
    if (!ok)
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, error);
    
    // Active your audio session
    ok = [audioSession setActive:YES error:&error];
    if (!ok)
        NSLog(@"%s audioSession setActive:YES error=%@", __PRETTY_FUNCTION__, error);
    
    
    // load default settings
    [DDGSettingsViewController loadDefaultSettings];
            
    // theme
    
    [[UINavigationBar appearance] setShadowImage:[[UIImage imageNamed:@"toolbar_shadow"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2.0, 0.0, 2.0)]];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolbar_bg"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolbar_bg_32"] forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithRed:0.29 green:0.30 blue:0.32 alpha:1.0],
														UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
														UITextAttributeTextShadowColor : [UIColor whiteColor]
	 }];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(5.0, 3.0, 5.0, 3.0);
    
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"button_bg"] resizableImageWithCapInsets:insets]
                                            forState:UIControlStateNormal
                                          barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"button_bg_highlighted"] resizableImageWithCapInsets:insets]
                                            forState:UIControlStateHighlighted
                                          barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"button_bg_32"] resizableImageWithCapInsets:insets]
                                            forState:UIControlStateNormal
                                          barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"button_bg_highlighted_32"] resizableImageWithCapInsets:insets]
                                            forState:UIControlStateHighlighted
                                          barMetrics:UIBarMetricsLandscapePhone];
    
//    [[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, 1.0) forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, 1.0) forBarMetrics:UIBarMetricsLandscapePhone];    

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithRed:0.403 green:0.406 blue:0.427 alpha:1.000],
                        UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                         UITextAttributeTextShadowColor : [UIColor whiteColor]
	 } forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithRed:0.581 green:0.585 blue:0.607 alpha:1.000],
                        UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                         UITextAttributeTextShadowColor : [UIColor whiteColor]
	 } forState:UIControlStateDisabled];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{	UITextAttributeTextColor :	[UIColor colorWithWhite:0.992 alpha:1.000],
                        UITextAttributeTextShadowOffset :	[NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
                         UITextAttributeTextShadowColor : [UIColor colorWithRed:0.169 green:0.180 blue:0.192 alpha:1.000]
	 } forState:UIControlStateHighlighted];
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor redColor];
    
    // configure the sliding view controller
    DDGUnderViewController *under = [[DDGUnderViewController alloc] init];
    
    
    ECSlidingViewController *slidingViewController = [[ECSlidingViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = slidingViewController;
    
    slidingViewController.underLeftViewController = under;
    slidingViewController.anchorRightRevealAmount = 258.0;
    
    UIViewController *homeController = [under viewControllerForType:DDGViewControllerTypeHome];
    
    slidingViewController.topViewController = homeController;
    [under configureViewController:homeController];
    
    [self.window makeKeyAndVisible];
    
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