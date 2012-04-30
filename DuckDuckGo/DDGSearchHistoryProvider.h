//
//  DDGSearchHistoryProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 3/31/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDGSearchHistoryProvider : NSObject {
    NSMutableArray *history;
}

+(id)sharedInstance;
-(void)clear;
-(void)logHistoryItem:(NSString *)historyItem;
-(NSArray *)pastHistoryItemsForPrefix:(NSString *)prefix;

@end
