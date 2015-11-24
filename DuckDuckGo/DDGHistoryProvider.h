//
//  DDGSearchHistoryProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 3/31/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDGHistoryItem.h"

@class DDGStory;
@interface DDGHistoryProvider : NSObject {}
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)clearHistory;
- (void)relogHistoryItem:(DDGHistoryItem *)item;
- (void)logSearchResultWithTitle:(NSString *)title;
- (void)logStory:(DDGStory *)story;

-(NSUInteger)countHistoryItems;
-(NSArray*)pastHistoryItemsForPrefix:(NSString *)prefix;
-(NSArray*)pastHistoryItemsForPrefix:(NSString *)prefix
                         onlyQueries:(BOOL)onlyQueries
                    withMaximumCount:(NSInteger)maxItems;
-(NSArray*)allHistoryItems;
@end
