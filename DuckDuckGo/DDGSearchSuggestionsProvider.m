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

static NSString *officialSitesBaseURL = @"https://duckduckgo.com/?o=json&q=";

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
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [self addOfficialSitesToSuggestionsCacheForSearchText:searchText success:success];
            });
        });
    } failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@",[error userInfo]);
    }];
    [operation start];
    
}

#pragma mark - Official sites

-(void)addOfficialSitesToSuggestionsCacheForSearchText:(NSString *)searchText success:(void (^)(void))success {
    NSMutableArray *suggestions = [[suggestionsCache objectForKey:searchText] mutableCopy];
    
    for(int i=0;i<suggestions.count;i++) {
        
        NSDictionary *item = [suggestions objectAtIndex:i];
        NSLog(@"finding official site for %@",item);
        NSString *officialSite = [self officialSiteForItem:[item objectForKey:@"phrase"]];
        NSLog(@"found %@",officialSite);
        if(officialSite) {
            NSMutableDictionary *newItem = [item mutableCopy];
            [newItem setObject:officialSite forKey:@"officialsite"];
            [suggestions replaceObjectAtIndex:i withObject:newItem];
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                [suggestionsCache setObject:suggestions forKey:searchText];
                success();
            });
        }
    }
}

-(NSString *)officialSiteForItem:(NSString *)suggestion {
    // in the cache, @"" means the server returned no official sites, and nil means there's just no cached response. But this method is always and only supposed to return nil when there's no official site.
    NSString *cachedOfficialSite = [DDGCache objectForKey:suggestion inCache:@"officialSites"];
    
    if([cachedOfficialSite isEqualToString:@""])
        return nil;
    else if(cachedOfficialSite)
        return cachedOfficialSite;
    
    NSString *requestURL = [officialSitesBaseURL stringByAppendingString:AFURLEncodedStringFromStringWithEncoding(suggestion, NSUTF8StringEncoding)];
    NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:requestURL]];
    if(!response) {
        NSLog(@"Error: official sites server didn't respond; %@",requestURL);
        return nil;
    }

    NSDictionary *officialSites = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
    
    NSString *officialSite;
    for(NSDictionary *result in [officialSites objectForKey:@"Results"]) {
        if([[result objectForKey:@"Text"] isEqualToString:@"Official site"]) {
            officialSite = [result objectForKey:@"FirstURL"];
            break;
        }
    }
    
    if(officialSite)
        [DDGCache setObject:officialSite forKey:suggestion inCache:@"officialSites"];
    else
        [DDGCache setObject:@"" forKey:suggestion inCache:@"officialSites"];
        
    return officialSite;
}

-(void)emptyCache {
    [suggestionsCache removeAllObjects];
}

-(NSString *)officialSitesCachePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"officialSites.plist"];
}

@end
