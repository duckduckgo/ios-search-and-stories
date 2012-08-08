//
//  DDGAppDelegate.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGSearchHistoryProvider.h"
#import "SDURLCache.h"
#import "DDGCache.h"
#import "DDGSettingsViewController.h"
#import "DDGSHKConfigurator.h"
#import "SHKConfiguration.h"
#import "DDGNewsProvider.h"

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
                                                         diskCapacity:1024*1024*5 // 5MB disk cache
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:urlCache];
    
    // load default settings
    [DDGSettingsViewController loadDefaultSettings];
    
    DefaultSHKConfigurator *configurator = [[DDGSHKConfigurator alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];

    
    // regenerate the news provider's dates now, before the table view loads, to minimize the chances of a change happening later (which would mean force-reloading the table view)
    [[DDGNewsProvider sharedProvider] generateSectionDates];
    
    return YES;
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
    [DDGCache saveCaches];
}

@end
