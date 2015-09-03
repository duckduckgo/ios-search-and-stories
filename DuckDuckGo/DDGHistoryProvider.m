//
//  DDGSearchHistoryProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 3/31/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGHistoryProvider.h"
#import "DDGSettingsViewController.h"
#import "DDGStory.h"

@interface DDGHistoryProvider ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@end

@implementation DDGHistoryProvider

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
    self = [super init];
    if(self) {
        NSParameterAssert(nil != moc);
        self.managedObjectContext = moc;
    }
    return self;
}

-(void)clearHistory {
    NSManagedObjectContext *context = self.managedObjectContext;
    [self performBlockWithHistoryItems:^(NSArray *history) {
        for (DDGHistoryItem *item in history) {
            DDGStory* story = item.story;
            if(story) story.readValue = NO;
            [context deleteObject:item];
        }
    } save:YES];
}

- (void)logSearchResultWithTitle:(NSString *)title {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
        return;
    NSArray *existingItems = [self itemsWithTitle:title];
    if ([existingItems count] > 0) {
        [self relogHistoryItem:[existingItems objectAtIndex:0]];
    } else {
        NSManagedObjectContext *context = self.managedObjectContext;
        [context performBlock:^{
            DDGHistoryItem *item = [DDGHistoryItem insertInManagedObjectContext:self.managedObjectContext];
            item.title = title;
            item.section = DDGHistoryItemSectionNameSearches;
            item.timeStamp = [NSDate date];
            [self save];
        }];        
    }
}

- (void)logStory:(DDGStory *)story {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
        return;    
    NSArray *existingItems = [self itemsForStory:story];
    if ([existingItems count] > 0) {
        [self relogHistoryItem:[existingItems objectAtIndex:0]];
    } else {
        NSManagedObjectContext *context = self.managedObjectContext;
        [context performBlock:^{
            DDGHistoryItem *item = [DDGHistoryItem insertInManagedObjectContext:self.managedObjectContext];
            item.story = story;
            item.title = story.title;
            item.section = DDGHistoryItemSectionNameStories;
            item.timeStamp = [NSDate date];
            [self save];
        }];
    }
}

- (void)relogHistoryItem:(DDGHistoryItem *)item {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
        return;    
    NSManagedObjectContext *context = self.managedObjectContext;
    [context performBlock:^{
        item.timeStamp = [NSDate date];
        [self save];
    }];
}

- (NSArray *)itemsWithTitle:(NSString *)title {
    __block NSArray *items = nil;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [self fetchRequest];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@", title];
        [fetchRequest setPredicate:predicate];
        NSError *error = nil;
        items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (nil == items)
            NSLog(@"Failed to fetch history items: %@", error);
    }];
    return items;
}

- (NSArray *)itemsForStory:(DDGStory *)story {
    __block NSArray *items = nil;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [self fetchRequest];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"story == %@", story];
        [fetchRequest setPredicate:predicate];
        NSError *error = nil;
        items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (nil == items)
            NSLog(@"Failed to fetch history items: %@", error);
    }];    
    return items;
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGHistoryItem entityName]];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO];
    [request setSortDescriptors:@[sort]];
    return request;
}

- (void)performBlockWithHistoryItems:(void (^)(NSArray *history))block save:(BOOL)save {
    NSManagedObjectContext *context = self.managedObjectContext;
    NSFetchRequest *request = [self fetchRequest];
    
    [context performBlock:^{
        NSError *error = nil;
        NSArray *history = [context executeFetchRequest:request error:&error];
        if (nil != history) {
            block(history);
        } else {
            NSLog(@"Failed to fetch history items: %@", error);
        }
        
        if (save) {
            NSError *error = nil;
            if (![context save:&error])
                NSLog(@"save error: %@", error);
        }
    }];
}

-(NSArray *)allHistoryItems {
    __block NSArray *history = nil;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [self fetchRequest];
        NSError *error = nil;
        history = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (nil == history)
            NSLog(@"Failed to fetch history items: %@", error);
    }];
    
    return history;
}

-(NSArray*)pastHistoryItemsForPrefix:(NSString *)prefix
{
    CGRect f = [[[[UIApplication sharedApplication] windows] firstObject] frame];
    return [self pastHistoryItemsForPrefix:prefix excludeStories:FALSE withMaximumCount:(f.size.height > 645 ? 5 : 3)];
}

-(NSArray *)pastHistoryItemsForPrefix:(NSString *)prefix
                       excludeStories:(BOOL)excludeStories
                     withMaximumCount:(NSInteger)maxItems {
    // if we don't track the history, don't bother querying
    if(![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory]) return @[];
    if(nil == prefix) return @[];
    
    NSMutableArray *history = [[NSMutableArray alloc] init];
    if(prefix.length<=0) {
        if(excludeStories) {
            for(DDGHistoryItem *historyItem in [self allHistoryItems]) {
                if(excludeStories && historyItem.story!=nil) continue;
                [history addObject:historyItem];
            }
        } else {
            [history addObjectsFromArray:[self allHistoryItems]];
        }
    } else {
        NSString* lowerPrefix = [prefix lowercaseString];
        for(DDGHistoryItem *historyItem in [self allHistoryItems]) {
            if(excludeStories && historyItem.story!=nil) continue;
            NSString *text = historyItem.title;
            // be case insensitive when comparing search strings (and not URL's)
            if ([[text lowercaseString] hasPrefix:lowerPrefix]			||
                [text hasPrefix:[@"http://" stringByAppendingString:prefix]]		||
                [text hasPrefix:[@"https://" stringByAppendingString:prefix]]		||
                [text hasPrefix:[@"http://www." stringByAppendingString:prefix]]	||
                [text hasPrefix:[@"https://www." stringByAppendingString:prefix]] ) {
                [history addObject:historyItem];
            }
        }
    }
    
    // if the array is too large, remove all but the 3 most recent items
    NSArray* results = history;
    if(maxItems>0 && history.count > maxItems) {
        results = [history objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, maxItems)]];
    }
    
    return results;
}

-(void)removeOldHistoryItemsWithoutSaving {
    NSManagedObjectContext *context = self.managedObjectContext;
    NSDate *now = [NSDate date];
    [self performBlockWithHistoryItems:^(NSArray *history) {
        for (DDGHistoryItem *item in history) {
            if([now timeIntervalSinceDate:[item timeStamp]] >= 30*24*60*60)
                [context deleteObject:item];
        }
    } save:YES];
}

-(void)save {
    [self removeOldHistoryItemsWithoutSaving];    
}

@end
