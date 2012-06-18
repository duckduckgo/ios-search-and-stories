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
static NSString *officialSitesBaseURL = @"https://duckduckgo.com/?o=json&q=";

@interface DDGSearchSuggestionsProvider (Private)
-(void)addOfficialSitesToSuggestionsCacheForKey:(NSString *)searchText success:(void (^)(void))success;
@end

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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self addOfficialSitesToSuggestionsCacheForKey:searchText success:success];        
        });
        
    } failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@",[error userInfo]);
    }];
    [operation start];
    
}

-(void)addOfficialSitesToSuggestionsCacheForKey:(NSString *)searchText success:(void (^)(void))success {
    NSMutableArray *suggestions = [[suggestionsCache objectForKey:searchText] mutableCopy];
    for(int i=0;i<suggestions.count;i++) {
        NSDictionary *item = [suggestions objectAtIndex:i];
        NSString *officialSitesURL = [officialSitesBaseURL stringByAppendingString:AFURLEncodedStringFromStringWithEncoding([item objectForKey:@"phrase"], NSUTF8StringEncoding)];
        NSData *officialSitesResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:officialSitesURL]];
        if(!officialSitesResponse) {
            NSLog(@"Error: official sites server didn't respond; %@",officialSitesURL);
            break;
        }
        
        NSDictionary *officialSites = [NSJSONSerialization JSONObjectWithData:officialSitesResponse options:0 error:nil];
        for(NSDictionary *result in [officialSites objectForKey:@"Results"]) {
            if([[result objectForKey:@"Text"] isEqualToString:@"Official site"]) {
                NSMutableDictionary *newItem = [item mutableCopy];
                [newItem setObject:[result objectForKey:@"FirstURL"] forKey:@"officialsite"];
                [suggestions replaceObjectAtIndex:i withObject:newItem];
                [suggestionsCache setObject:suggestions forKey:searchText];
                dispatch_sync(dispatch_get_main_queue(), ^(void) {
                    success();
                });
                break;
            }
        }
    }
}

-(void)emptyCache {
    [suggestionsCache removeAllObjects];
}

@end
