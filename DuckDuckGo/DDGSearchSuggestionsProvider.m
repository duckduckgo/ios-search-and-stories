//
//  DDGSearchSuggestionsProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 3/9/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchSuggestionsProvider.h"
#import "AFNetworking.h"
#import "DDGCache.h"
#import "Constants.h"

@implementation DDGSearchSuggestionsProvider

-(id)init {
    self = [super init];
    if(self) {
        suggestionsCache = [[NSMutableDictionary alloc] init];
        
        serverRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://duckduckgo.com"]
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:10.0];
		
		[serverRequest setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
		[serverRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
		[serverRequest setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Accept"];
        return self;
    }
    return nil;
}

#pragma mark - Downloading and returning search suggestions

-(NSArray *)suggestionsForSearchText:(NSString *)searchText {    
    NSString *bestMatch = nil;
    
    for(NSString *suggestionText in suggestionsCache) {
        if([searchText hasPrefix:suggestionText] && (suggestionText.length > bestMatch.length))
            bestMatch = suggestionText;
    }
    
    return (bestMatch ? [suggestionsCache objectForKey:bestMatch] : @[]);
}

-(void)downloadSuggestionsForSearchText:(NSString *)searchText success:(void (^)(void))success {
    // check the cache before querying the server
    if([suggestionsCache objectForKey:searchText])
        return;
    
    NSString *urlString = [kDDGSuggestionsURLString stringByAppendingString:[searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    serverRequest.URL = [NSURL URLWithString:urlString];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:serverRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [suggestionsCache setObject:JSON forKey:searchText];
            success(); // run callback
        });
    } failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@",[error userInfo]);
    }];
    [operation start];
    
}

-(void)emptyCache {
    [suggestionsCache removeAllObjects];
}

@end
