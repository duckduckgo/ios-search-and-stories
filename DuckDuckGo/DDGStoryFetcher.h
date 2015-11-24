//
//  DDGStoryFetcher.h
//  Stories
//
//  Created by Johnnie Walker on 18/03/2013.
//  Copyright (c) 2013 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const DDGStoryFetcherStoriesLastUpdatedKey;
extern NSString * const DDGStoryFetcherSourcesLastUpdatedKey;

@class DDGStory, DDGStoryFeed;
@interface DDGStoryFetcher : NSObject
@property (nonatomic, readonly, weak) NSManagedObjectContext *parentManagedObjectContext;
@property (nonatomic, readonly, getter = isRefreshing) BOOL refreshing;

- (id)initWithParentManagedObjectContext:(NSManagedObjectContext *)context;
- (void)refreshSources:(void (^)(NSDate *lastFetchDate))completion;

// async, runs on a private queue
// willSave is called synchronously on the main queue
// didSave is called asynchronously on the main queue
- (void)refreshStories:(void (^)())willSave completion:(void (^)(NSDate *lastFetchDate))completion;

- (void)downloadImageForStory:(DDGStory *)story;
- (void)downloadImageForStory:(DDGStory *)story completion:(void (^)(BOOL success))completion;

- (void)downloadIconForFeed:(DDGStoryFeed *)feed;


+ (void)resetSourceFeedsToDefaultInContext:(NSManagedObjectContext*)context;

@end
