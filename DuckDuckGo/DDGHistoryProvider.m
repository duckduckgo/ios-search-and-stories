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
            [context deleteObject:item];
        }
    } save:YES];
}

- (void)logSearchResultWithTitle:(NSString *)title {
    NSArray *existingItems = [self itemsWithTitle:title];
    if ([existingItems count] > 0) {
        [self relogHistoryItem:[existingItems objectAtIndex:0]];
    } else {
        NSManagedObjectContext *context = self.managedObjectContext;
        [context performBlock:^{
            DDGHistoryItem *item = [DDGHistoryItem insertInManagedObjectContext:self.managedObjectContext];
            item.title = title;
            item.timeStamp = [NSDate date];
            [self save];
        }];        
    }
}

- (void)logStory:(DDGStory *)story {
    NSArray *existingItems = [self itemsForStory:story];
    if ([existingItems count] > 0) {
        [self relogHistoryItem:[existingItems objectAtIndex:0]];
    } else {        
        NSManagedObjectContext *context = self.managedObjectContext;
        [context performBlock:^{
            DDGHistoryItem *item = [DDGHistoryItem insertInManagedObjectContext:self.managedObjectContext];
            item.story = story;
            item.title = story.title;
            item.timeStamp = [NSDate date];
            [self save];
        }];
    }
}

- (void)relogHistoryItem:(DDGHistoryItem *)item {
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

-(NSArray *)pastHistoryItemsForPrefix:(NSString *)prefix {
    // there are certain cases in which we don't want to return any history
    if(nil == prefix || [prefix isEqualToString:@""] || ![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
        return @[];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    for(DDGHistoryItem *historyItem in [self allHistoryItems])
	{
        NSString *text = historyItem.title;
		// be case insensitive when comparing search strings (and not URL's)
        if ([[text lowercaseString] hasPrefix:[prefix lowercaseString]]			||
			[text hasPrefix:[@"http://" stringByAppendingString:prefix]]		||
			[text hasPrefix:[@"https://" stringByAppendingString:prefix]]		||
			[text hasPrefix:[@"http://www." stringByAppendingString:prefix]]	||
			[text hasPrefix:[@"https://www." stringByAppendingString:prefix]]
           )
            [results addObject:historyItem];
    }
    
    // if the array is too large, remove all but the 3 most recent items
    while(results.count > 3)
        [results removeObjectAtIndex:0];

    // the array is currently in ascending chronological order; reverse it and make it non-mutable
    return [[results reverseObjectEnumerator] allObjects];
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
