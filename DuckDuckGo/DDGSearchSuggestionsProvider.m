//
//  DDGSearchSuggestionsProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 3/9/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchSuggestionsProvider.h"
#import "DDGAutocompleteServerKeys.h"
#import "AFNetworking.h"

static NSString *suggestionServerBaseURL = @"http://swass.duckduckgo.com:6767/face/suggest/?q=";

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
    
    return (bestMatch ? [suggestionsCache objectForKey:bestMatch] : [NSArray array]);
}

-(void)downloadSuggestionsForSearchText:(NSString *)searchText success:(void (^)(void))success {
    // check the cache before querying the server
    if([suggestionsCache objectForKey:searchText])
        return;
    
    NSString *urlString = [suggestionServerBaseURL stringByAppendingString:[searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    serverRequest.URL = [NSURL URLWithString:urlString];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:serverRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [suggestionsCache setObject:JSON forKey:searchText];
        success(); // run callback        
    } failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@",[error userInfo]);
    }];
    [operation start];
    
}

-(void)emptyCache {
    [suggestionsCache removeAllObjects];
}

@end
