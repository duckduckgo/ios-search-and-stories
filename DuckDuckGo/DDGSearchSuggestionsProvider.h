//
//  DDGSearchSuggestionsProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 3/9/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDGSearchSuggestionsProvider : NSObject {
    NSMutableDictionary *suggestionsCache;
    NSMutableURLRequest *serverRequest;
    NSDictionary *bangs; 
}

+(DDGSearchSuggestionsProvider *)sharedProvider;

-(NSArray *)suggestionsForSearchText:(NSString *)searchText;
-(void)downloadSuggestionsForSearchText:(NSString *)searchText success:(void (^)(void))success;
-(void)emptyCache;

@end
