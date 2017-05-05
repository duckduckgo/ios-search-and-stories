//
//  DDGAppDelegate.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#ifdef __APPLE__
#import "TargetConditionals.h"
#endif

#import "DDGAppDelegate.h"
#import "DDGBookmarksProvider.h"
#import "DDGHistoryProvider.h"
#import "SDURLCache.h"
#import "DDGSettingsViewController.h"
#import "AFNetworking.h"
#import "DDGSearchController.h"
#import "DDGSearchHandler.h"
#import "NSString+URLEncodingDDG.h"
#import "DDGURLProtocol.h"
#import "DDGHomeViewController.h"
#import "DuckDuckGo-Swift.h"

@import UIKit;

@interface DDGAppDelegate ()
@property (nonatomic, strong) DDGHomeViewController* homeController;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *masterManagedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation DDGAppDelegate

static void uncaughtExceptionHandler(NSException *exception) {
    //Internal error reporting
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}

- (void)handleShortCutItem:(UIApplicationShortcutItem *)shortcutItem  {
    NSLog(@"handleShortCutItem: %@", shortcutItem.type);
    if([shortcutItem.type isEqualToString:@"com.duckduckgo.mobile.ios.search"]){
        [self.homeController.currentSearchHandler loadQueryOrURL:shortcutItem.localizedTitle];
    } else if ([shortcutItem.type isEqualToString:@"com.duckduckgo.mobile.ios.newSearch"]) {
        [self.homeController showSearchAndPrepareInput];
    } else if ([shortcutItem.type isEqualToString:@"com.duckduckgo.mobile.ios.saved"]) {
        [self.homeController showSaved];
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if (shortcutItem) {
        [self handleShortCutItem:shortcutItem];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setStatusBarStyle:UIStatusBarStyleLightContent];

    [NSURLProtocol registerClass:[DDGURLProtocol class]];
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"lastRefreshAttempt"];
    [defaults removeObjectForKey:@"lastRefreshFavorites"];
    [defaults removeObjectForKey:@"lastRefreshRecents"];
    [defaults removeObjectForKey:@"lastRefreshMisc"];
    
    //Set the global URL cache to SDURLCache, which caches to disk
    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024*2 // 2MB mem cache
                                                         diskCapacity:1024*1024*10 // 10MB disk cache
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:urlCache];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    //Audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok; //I like this. Naming a variable ok. Very subtle.
    NSError *error = nil;
    ok = [audioSession setActive:NO error:&error];
    if (!ok)
        NSLog(@"%s audioSession setActive:NO error=%@", __PRETTY_FUNCTION__, error);

    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback
                       withOptions:AVAudioSessionCategoryOptionMixWithOthers
                             error:&error];
    if (!ok)
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, error);
        
    //Active your audio session.
    ok = [audioSession setActive:YES error:&error];
    if(!ok) NSLog(@"%s audioSession setActive:YES error=%@", __PRETTY_FUNCTION__, error);
    
    
    // Load default settings.
    [DDGSettingsViewController loadDefaultSettings];
    [self.window setBackgroundColor:[UIColor duckSearchBarBackground]];
    
    // main view controller
    self.homeController = [DDGHomeViewController newHomeController];
    self.window.rootViewController = self.homeController;
    
    [self.window makeKeyAndVisible];
    
    
    //NSLog(@"Saved Shortcuts: %@", savedShortcuts);
    [self updateShortcuts];
    
    UIApplication* app = [UIApplication sharedApplication];
    if([app respondsToSelector:@selector(setShortcutItems:)]) { // only set shortcuts if there's support for it
        UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
        if (shortcutItem) {
            [self handleShortCutItem:shortcutItem];
        }
    }
    
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;
{

    //We can only open URLs from DDG.
    if(![[[url scheme] lowercaseString] isEqualToString:@"duckduckgo"])
        return NO;
    
    // Let's see what the query is.
    NSString *query = nil;
    NSArray *params = [[url query] componentsSeparatedByString:@"&"];
    for (NSString *param in params) {
        NSArray *pair = [param componentsSeparatedByString:@"="];
        if ([pair count] > 1 && [[[pair objectAtIndex:0] lowercaseString] isEqualToString:@"q"]) {
            query = [[pair objectAtIndex:1] URLDecodedStringDDG];
        }
    }
    
    if (query) {
        [self.homeController.currentSearchHandler loadQueryOrURL:query];
    } else {
        [self.homeController.currentSearchHandler prepareForUserInput];
    }

    return YES;
}


- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler
{
    NSURL* url = userActivity.webpageURL;
    NSLog(@"deep-linking invoked with URL: %@", url);
    if(url==nil) return NO;
    
    //We can only open URLs from DDG.
    BOOL isDDGURL = [[[url scheme] lowercaseString] isEqualToString:@"duckduckgo"];
    // Let's see what the query is.
    NSString *query = nil;
    if(isDDGURL) {
        NSArray *params = [[url query] componentsSeparatedByString:@"&"];
        for (NSString *param in params) {
            NSArray *pair = [param componentsSeparatedByString:@"="];
            if ([pair count] > 1 && [[[pair objectAtIndex:0] lowercaseString] isEqualToString:@"q"]) {
                query = [[pair objectAtIndex:1] URLDecodedStringDDG];
            }
        }
    } else {
        query = [DDGSearchController queryFromDDGURL:url];
    }
    
    if (query) {
        [self.homeController.currentSearchHandler loadQueryOrURL:query];
    } else {
        [self.homeController.currentSearchHandler loadQueryOrURL:[url absoluteString]];
    }
    
    return YES;
}


- (void)applicationWillTerminate:(UIApplication *)application;
{
    [self save];

    [self clearCacheAndCookies];
}

- (void)applicationWillResignActive:(UIApplication *)application;
{
    [self save];
}

- (void)applicationDidEnterBackground:(UIApplication *)application;
{
    [self save];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.homeController checkAndRefreshSettings];
    [self showSafariPopupIfNotSeen];
}
 

#pragma mark - Onboarding Flow
- (void)showSafariPopupIfNotSeen {
    OnboardingSettings *settings = [OnboardingSettings new];
    if (!settings.hasSeenOnboarding && settings.shouldShowOnboardingUponLaunch) {
        settings.hasSeenOnboarding = YES;
        [self showAddToSafariPopup];
    }
}

-(void)showAddToSafariPopup {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    UseDuckDuckGoViewController* useDDGController = [storyboard instantiateViewControllerWithIdentifier:@"UseDuckDuckGoViewController"];
    [self.homeController presentViewController:useDDGController animated:TRUE completion:NULL];
}

#pragma mark - 3DTouch Shortcuts
-(void)updateShortcuts {
    UIApplication* app = [UIApplication sharedApplication];
    if([app respondsToSelector:@selector(setShortcutItems:)]) { // only set shortcuts if there's support for it
        UIApplicationShortcutIcon *searchIcon = [UIApplicationShortcutIcon iconWithTemplateImageName: @"Tab-Search"];
        UIApplicationShortcutIcon *faveIcon = [UIApplicationShortcutIcon iconWithTemplateImageName: @"Tab-Favorites"];
        
        DDGHistoryProvider *historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
        NSMutableArray* recentQueries = [NSMutableArray new];
        for(DDGHistoryItem* recent in historyProvider.allHistoryItems) {
            if(!recent.story && recent.title && ![recentQueries containsObject:recent.title]) {
                [recentQueries addObject:recent.title];
            }
            if(recentQueries.count > 4) break;
        }
        
        // add some saved items.. well, the 6s only has room for one, so we'll add one saved/faved item
        NSArray* fetchedBookmarks = [[[DDGBookmarksProvider sharedProvider].bookmarks reverseObjectEnumerator] allObjects];
        NSMutableArray* bookmarkQueries = [NSMutableArray new];
        for (NSDictionary *bookmark in fetchedBookmarks) {
            NSString *savedSearch = [bookmark valueForKey:@"title"];
            if(![bookmarkQueries containsObject:savedSearch]) {
                [bookmarkQueries addObject:savedSearch];
            }
            if(bookmarkQueries.count > 4) break;
        }
        
        NSMutableArray *shortcuts = [NSMutableArray new];
        NSMutableArray *shortcutQueries = [NSMutableArray new];
        for(int i=0; i<bookmarkQueries.count; i++) {
            NSString* query = [bookmarkQueries objectAtIndex:i];
            UIApplicationShortcutItem *bookmarkShortcut = [[UIApplicationShortcutItem alloc]initWithType: @"com.duckduckgo.mobile.ios.search"
                                                                                          localizedTitle: query
                                                                                       localizedSubtitle: nil
                                                                                                    icon: faveIcon
                                                                                                userInfo: nil];
            [shortcuts addObject:bookmarkShortcut];
            [shortcutQueries addObject:query];
            if(shortcuts.count + recentQueries.count > 3) break; // no more than one bookmark shortcut, if there are any recent queries
        }
        
        for(NSString* query in recentQueries) {
            if([shortcutQueries containsObject:query]) continue; // don't re-add items that we already have
            UIApplicationShortcutItem *recentShortcut = [[UIApplicationShortcutItem alloc]initWithType: @"com.duckduckgo.mobile.ios.search"
                                                                                        localizedTitle: query
                                                                                     localizedSubtitle: nil
                                                                                                  icon: searchIcon
                                                                                              userInfo: nil];
            [shortcuts addObject:recentShortcut];
        }
        
        [[UIApplication sharedApplication] setShortcutItems: shortcuts];
    }
}


#pragma mark - Clean up

- (void)clearCacheAndCookies
{
    __block UIBackgroundTaskIdentifier identifier = UIBackgroundTaskInvalid;

    identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
    {
        identifier = UIBackgroundTaskInvalid;
    }];

    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies])
    {
       [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[UIApplication sharedApplication] endBackgroundTask:identifier];
}

#pragma mark - Core Data stack

- (void)save;
{
    __block UIBackgroundTaskIdentifier identfier = UIBackgroundTaskInvalid;
    
    identfier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        identfier = UIBackgroundTaskInvalid;
    }];
    
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.managedObjectContext performBlock:^{
        if (self.managedObjectContext.hasChanges) {
            NSError *error = nil;
            BOOL success = [self.managedObjectContext save:&error];
            if (!success && nil != error)
                NSLog(@"error: %@", error);
        }
        
        [self.masterManagedObjectContext performBlock:^{
            if (self.masterManagedObjectContext.hasChanges) {
                NSError *error = nil;
                BOOL success = [self.masterManagedObjectContext save:&error];
                if (!success && nil != error)
                    NSLog(@"error: %@", error);
            }
            [[UIApplication sharedApplication] endBackgroundTask:identfier];
        }];
    }];
}

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    __block UIBackgroundTaskIdentifier identfier = UIBackgroundTaskInvalid;
    
    identfier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        identfier = UIBackgroundTaskInvalid;
    }];
    
    [self.masterManagedObjectContext performBlock:^{
        if (self.masterManagedObjectContext.hasChanges) {
            NSError *error = nil;
            BOOL success = [self.masterManagedObjectContext save:&error];
            if (!success && nil != error)
                NSLog(@"error: %@", error);
        }
        [[UIApplication sharedApplication] endBackgroundTask:identfier];
    }];
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{    
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (!_masterManagedObjectContext) {
        _masterManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_masterManagedObjectContext setPersistentStoreCoordinator:coordinator];        
    }    
    
    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setParentContext:_masterManagedObjectContext];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:_managedObjectContext];
    }
    
    return _managedObjectContext;
}

+(NSManagedObjectContext*)sharedManagedObjectContext {
    return ((DDGAppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if(_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Stories" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if(_persistentStoreCoordinator){
        return _persistentStoreCoordinator;
    }
    
    NSFileManager* fm = [NSFileManager defaultManager];
    NSURL* docsDir = [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    DLog(@"documents directory: %@", docsDir);
    NSString *storeName = @"Stories.sqlite";
    NSURL *storeURL = [docsDir URLByAppendingPathComponent:storeName];
    NSURL *storeWriteAheadLogURL = [docsDir URLByAppendingPathComponent:[storeName stringByAppendingString:@"-wal"]];
    NSURL *storeSharedMemoryURL = [docsDir URLByAppendingPathComponent:[storeName stringByAppendingString:@"-shm"]];
    
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @"YES"};
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
#ifdef DISALLOW_ICLOUD_BACKUP
    BOOL success = NO;
    if([[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        error = nil;
        success = [storeURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [storeURL lastPathComponent], error);
        }
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:[storeSharedMemoryURL path]]) {
        error = nil;
        success = [storeSharedMemoryURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [storeSharedMemoryURL lastPathComponent], error);
        }
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:[storeWriteAheadLogURL path]]) {
        error = nil;
        success = [storeWriteAheadLogURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [storeWriteAheadLogURL lastPathComponent], error);
        }
    }
#endif
    
    
    return _persistentStoreCoordinator;
}

@end
