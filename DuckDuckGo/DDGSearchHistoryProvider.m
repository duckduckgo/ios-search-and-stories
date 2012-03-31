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
    if([history indexOfObjectIdenticalTo:historyItem]==NSNotFound) {
        [history addObject:historyItem];
        [self save];
    }
}

-(NSArray *)pastSearchesForPrefix:(NSString *)prefix {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    for(NSString *historyItem in history)
        if([historyItem hasPrefix:prefix])
            [results addObject:historyItem];

    return [results copy]; // return a non-mutable copy
}

-(void)save {
    [history writeToFile:self.historyPath atomically:YES];
}

-(NSString *)historyPath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"history.plist"];
}

@end
