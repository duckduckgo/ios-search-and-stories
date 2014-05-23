//
//  DDGStoryFetcher.m
//  Stories
//
//  Created by Johnnie Walker on 18/03/2013.
//  Copyright (c) 2013 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGStoryFetcher.h"
#import "AFNetworking.h"
#import "DDGStory.h"
#import "DDGStoryFeed.h"
#import "DDGUtility.h"

NSString * const DDGStoryFetcherStoriesLastUpdatedKey = @"storiesUpdated";
NSString * const DDGStoryFetcherSourcesLastUpdatedKey = @"sourcesUpdated";

@interface DDGStoryFetcher () {
    dispatch_queue_t _queue;
}
@property (nonatomic, readwrite, weak) NSManagedObjectContext *parentManagedObjectContext;
@property (nonatomic, strong) NSOperationQueue *networkOperationQueue;
@property (nonatomic, strong) NSOperationQueue *imageDownloadQueue;
@property (nonatomic, strong) NSMutableSet *enqueuedDownloadOperations;
@property (nonatomic, readwrite, getter = isRefreshing) BOOL refreshing;
@end

@implementation DDGStoryFetcher

- (id)initWithParentManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        self.networkOperationQueue = [NSOperationQueue new];
        self.networkOperationQueue.maxConcurrentOperationCount = 2;
        self.imageDownloadQueue = [NSOperationQueue new];
        self.imageDownloadQueue.maxConcurrentOperationCount = 2;
        self.parentManagedObjectContext = context;
        self.enqueuedDownloadOperations = [NSMutableSet new];
        _queue = dispatch_queue_create("", 0);
    }
    return self;
}

- (void)dealloc
{
    [self.networkOperationQueue cancelAllOperations];
    self.networkOperationQueue = nil;
}

- (void)refreshSources:(void (^)(NSDate *lastFetchDate))completion {
    
    dispatch_async(_queue, ^{
        NSURL *sourcesURL = [NSURL URLWithString:kDDGTypeInfoURLString];
        NSURLRequest *request = [DDGUtility requestWithURL:sourcesURL];
        
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [context setParentContext:self.parentManagedObjectContext];
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        void (^success)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) = ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            NSDate *feedDate = nil;
            
            if ([JSON isKindOfClass:[NSArray class]]) {
                NSArray *items = (NSArray *)JSON;
                
                feedDate = [NSDate date];
                
                for (NSDictionary *feedDict in items) {
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGStoryFeed entityName]];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@", [feedDict valueForKey:@"id"]];
                    [request setPredicate:predicate];
                    __block NSArray *results;
                    [context performBlockAndWait:^{
                        NSError *error = nil;
                        results = [context executeFetchRequest:request error:&error];
                        if (nil == results)
                            NSLog(@"error: %@", error);
                    }];
                    
                    DDGStoryFeed *feed = nil;
                    if ([results count]) {
                        feed = [results objectAtIndex:0];
                    } else {
                        feed = [DDGStoryFeed insertInManagedObjectContext:context];
                        feed.feedState = DDGStoryFeedStateDefault;
                    }
                                        
                    feed.urlString = [feedDict valueForKey:@"link"];
                    feed.id = [feedDict valueForKey:@"id"];
                    feed.enabledByDefault = [feedDict valueForKey:@"default"];
                    feed.category = [feedDict valueForKey:@"category"];
                    feed.title = [feedDict valueForKey:@"title"];
                    feed.descriptionString = [feedDict valueForKey:@"description"];
                    feed.imageURLString = [feedDict valueForKey:@"image"];
                    feed.feedDate = feedDate;                    
                }
                
                [self purgeSourcesOlderThanDate:feedDate inContext:context];                
                
                [[NSUserDefaults standardUserDefaults] setObject:feedDate forKey:DDGStoryFetcherSourcesLastUpdatedKey];
                
                [context performBlockAndWait:^{
                    NSError *error = nil;
                    BOOL success = [context save:&error];
                    if (!success)
                        NSLog(@"error: %@", error);
                }];
                
            }
            
            if (completion)
                dispatch_async(dispatch_get_main_queue(), ^{completion(feedDate);});            
        };
        
        void (^failure)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"error: %@", error);
            if (completion)
                dispatch_async(dispatch_get_main_queue(), ^{completion(nil);});
        };
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                            success:success
                                                                                            failure:failure];
        [operation setSuccessCallbackQueue:_queue];
        [self.networkOperationQueue addOperation:operation];
    });
}

- (void)purgeSourcesOlderThanDate:(NSDate *)date inContext:(NSManagedObjectContext *)context {
    [context performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGStoryFeed entityName]];
        NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"feedDate < %@", date];
        NSPredicate *savedPredicate = [NSPredicate predicateWithFormat:@"enabled != %i", DDGStoryFeedStateEnabled];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[datePredicate, savedPredicate]];
        [request setPredicate:predicate];        
        
        NSError *error = nil;
        NSArray *feeds = [context executeFetchRequest:request error:&error];
        if (nil == feeds)
            NSLog(@"error: %@", error);
        
        for (DDGStoryFeed *feed in feeds)
            [context deleteObject:feed];
    }];
}

- (void)refreshStories:(void (^)())willSave completion:(void (^)(NSDate *lastFetchDate))completion {
    dispatch_async(_queue, ^{

        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [context setParentContext:self.parentManagedObjectContext];
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        NSDictionary *feedsByID = [self feedsByIDInContext:context enabledFeedsOnly:YES];
        
        NSURL *storiesURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kDDGStoriesURLString, [[feedsByID allKeys] componentsJoinedByString:@","]]];
        NSURLRequest *request = [DDGUtility requestWithURL:storiesURL];
        
        void (^success)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) = ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            NSDate *feedDate= nil;
            
            if ([JSON isKindOfClass:[NSArray class]]) {
                NSArray *items = (NSArray *)JSON;
                                
                NSDictionary *feedsByID = [self feedsByIDInContext:context enabledFeedsOnly:NO];
                
                feedDate = [NSDate date];
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                
                for (id storyDict in items) {
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGStory entityName]];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@", [storyDict valueForKey:@"id"]];
                    [request setPredicate:predicate];

                    __block NSArray *results;
                    [context performBlockAndWait:^{
                        NSError *error = nil;
                        results = [context executeFetchRequest:request error:&error];
                        if (nil == results)
                            NSLog(@"error: %@", error);
                    }];
                    
                    DDGStory *story = nil;
                    if ([results count]) {
                        story = [results objectAtIndex:0];
                    } else {
                        story = [DDGStory insertInManagedObjectContext:context];
                    }
                    
                    // If appropriate, configure the new managed object.
                    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
                    
                    NSString *feedID = [storyDict valueForKey:@"type"];
                    [story setValue:[feedsByID objectForKey:feedID] forKey:@"feed"];
                    
                    story.descriptionString = [storyDict valueForKey:@"description"];
                    story.imageURLString = [storyDict valueForKey:@"image"];
                    story.urlString = [storyDict valueForKey:@"url"];
                    story.title = [storyDict valueForKey:@"title"];
                    story.id = [storyDict valueForKey:@"id"];
                    [story setValue:[storyDict valueForKey:@"id"] forKey:@"id"];
                    NSDate *date = [formatter dateFromString:[[storyDict objectForKey:@"timestamp"] substringToIndex:19]];
                    story.timeStamp = date;
                    story.articleURLString = [storyDict objectForKey:@"article_url"];
                    story.feedDate = feedDate;
                }
                
                [self purgeStoriesOlderThanDate:feedDate inContext:context];
                
                if (willSave)
                    dispatch_sync(dispatch_get_main_queue(), willSave);
                
                [context performBlockAndWait:^{
                    NSError *error = nil;
                    BOOL success = [context save:&error];
                    if (!success)
                        NSLog(@"error: %@", error);
                }];
                
                [[NSUserDefaults standardUserDefaults] setObject:feedDate forKey:DDGStoryFetcherStoriesLastUpdatedKey];
            }
            
            if (completion)
                dispatch_async(dispatch_get_main_queue(), ^{completion(feedDate);});
        };
        
        void (^failure)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"error: %@", error);
            if (completion)
                dispatch_async(dispatch_get_main_queue(), ^{completion(nil);});
        };
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                            success:success
                                                                                            failure:failure];
        [operation setSuccessCallbackQueue:_queue];
        [self.networkOperationQueue addOperation:operation];
    });
}

- (void)purgeStoriesOlderThanDate:(NSDate *)date inContext:(NSManagedObjectContext *)context {
    [context performBlock:^{        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGStory entityName]];
        NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"feedDate < %@", date];
        NSPredicate *savedPredicate = [NSPredicate predicateWithFormat:@"saved == %@", @(NO)];
        NSPredicate *recentPredicate = [NSPredicate predicateWithFormat:@"recents.@count == %@", @(0)];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[datePredicate, savedPredicate, recentPredicate]];
        [request setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *stories = [context executeFetchRequest:request error:&error];
        if (nil == stories)
            NSLog(@"error: %@", error);
        
        for (DDGStory *story in stories)
            [context deleteObject:story];
    }];
}

#pragma mark - Fetching

- (NSDictionary *)feedsByIDInContext:(NSManagedObjectContext *)context enabledFeedsOnly:(BOOL)enabledOnly {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Feed"];
    if (enabledOnly)
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"enabled = %i", DDGStoryFeedStateEnabled]];
    
    __block NSArray *results;
    [context performBlockAndWait:^{
        NSError *error = nil;
        results = [context executeFetchRequest:fetchRequest error:&error];
        if (nil == results)
            NSLog(@"error: %@", error);
    }];
    
    NSMutableDictionary *feedsByID = [NSMutableDictionary dictionaryWithCapacity:[results count]];
    for (NSManagedObject *feed in results) {
        NSString *feedID = [feed valueForKey:@"id"];
        [feedsByID setObject:feed forKey:feedID];
    }
    
    return feedsByID;
}

- (void)downloadIconForFeed:(DDGStoryFeed *)feed {
    NSURL *imageURL = feed.imageURL;
    NSManagedObjectID *objectID = [feed objectID];
    
    if (!feed.imageDownloadedValue && ![self.enqueuedDownloadOperations containsObject:imageURL]) {
        NSURLRequest *request = [DDGUtility requestWithURL:imageURL];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [context setParentContext:self.parentManagedObjectContext];
            [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
            
            NSData *responseData = (NSData *)responseObject;
            
            __block DDGStoryFeed *feed;
            [context performBlockAndWait:^{
                feed = (DDGStoryFeed *)[context objectWithID:objectID];
            }];
            
            [feed writeImageData:responseData completion:^(BOOL success) {
                if (success) {
                    feed.imageDownloadedValue = YES;
                    
                    [context performBlock:^{
                        NSError *error = nil;
                        BOOL success = [context save:&error];
                        if (!success)
                            NSLog(@"error: %@", error);
                    }];
                }
            }];
            [self.enqueuedDownloadOperations removeObject:imageURL];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.enqueuedDownloadOperations removeObject:imageURL];
        }];
        
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            [self.enqueuedDownloadOperations removeObject:imageURL];
        }];
        
        [operation setSuccessCallbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        [self.enqueuedDownloadOperations addObject:imageURL];
        [self.imageDownloadQueue addOperation:operation];
    }
    
}

- (void)downloadImageForStory:(DDGStory *)story {
    NSURL *imageURL = story.imageURL;    
    NSManagedObjectID *objectID = [story objectID];
        
    if (!story.imageDownloadedValue && ![self.enqueuedDownloadOperations containsObject:imageURL]) {
        NSURLRequest *request = [DDGUtility requestWithURL:imageURL];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [context setParentContext:self.parentManagedObjectContext];
            [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];            
            
            NSData *responseData = (NSData *)responseObject;
            
            __block DDGStory *story;
            [context performBlockAndWait:^{
                story = (DDGStory *)[context objectWithID:objectID];
            }];            
            
            [story writeImageData:responseData completion:^(BOOL success) {
                if (success) {
                    story.imageDownloadedValue = YES;
                    [context performBlock:^{
                        NSError *error = nil;
                        BOOL success = [context save:&error];
                        if (!success)
                            NSLog(@"error: %@", error);
                    }];
                }
            }];
            [self.enqueuedDownloadOperations removeObject:imageURL];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.enqueuedDownloadOperations removeObject:imageURL];
        }];
        
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            [self.enqueuedDownloadOperations removeObject:imageURL];
        }];
        
        [operation setSuccessCallbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];        
        [self.enqueuedDownloadOperations addObject:imageURL];
        [self.imageDownloadQueue addOperation:operation];
    }
    
}

@end
