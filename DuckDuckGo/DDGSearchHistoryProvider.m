//
//  DDGSearchHistoryProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 3/31/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchHistoryProvider.h"

@interface DDGSearchHistoryProvider (Private)
-(NSString *)historyPath;
-(void)removeOldHistoryItemsWithoutSaving;
-(void)save;
@end

@implementation DDGSearchHistoryProvider

-(id)init {
    self = [super init];
    if(self) {
        history = [[NSMutableArray alloc] initWithContentsOfFile:self.historyPath];
        if(!history)
            history = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)clear {
    history = [[NSMutableArray alloc] init];
    [self save];
}

-(void)logHistoryItem:(NSString *)historyItem {
    NSDictionary *historyItemDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"text",historyItem,@"date",[NSDate date]];
    
    for(int i=0; i<history.count; i++) {
        if([[[history objectAtIndex:i] objectForKey:@"text"] isEqualToString:historyItem]) {
            // add the new history item at the end to keep the array ordered
            [history removeObjectAtIndex:i];
            [history addObject:historyItemDictionary];
            return;
        }
    }
    [history addObject:historyItemDictionary];
    [self save];
}

-(NSArray *)pastHistoryItemsForPrefix:(NSString *)prefix {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    for(NSString *historyItem in history)
        if([[historyItem objectForKey:@"text"] hasPrefix:prefix])
            [results addObject:historyItem];

    // if the array is too large, remove the earliest n-3 items
    while(results.count > 3)
        [results removeObjectAtIndex:0];

    // the array is currently in ascending chronological order; reverse it
    results = [[results reverseObjectEnumerator] allObjects];

    return [results copy]; // return a non-mutable copy
}

-(void)removeOldHistoryItemsWithoutSaving {
    for(int i=history.count-1; i>=0; i--) {
        // TODO (ishaan): make history interval adjustable? it's currently hard-coded to 30 seconds
        if([[NSDate date] timeIntervalSinceDate:[history objectForKey:@"date"]] >= 30*24*60*60)
            [history removeObjectAtIndex:i];
    }
}

-(void)save {
    [self removeOldHistoryItemsWithoutSaving];
    [history writeToFile:self.historyPath atomically:YES];
}

-(NSString *)historyPath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"history.plist"];
}

@end
