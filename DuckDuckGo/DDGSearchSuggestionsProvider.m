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
static NSString *bangsURL = @"https://raw.github.com/gist/7a570ffb40cdf74a9796/64a7f458b17b74355b72e432280b92dda6e6eebd/gistfile1.json";

@interface DDGSearchSuggestionsProvider (Private)
-(NSString *)stripBangFromSearchText:(NSString *)rawSearchText;
-(NSString *)bangFromSearchText:(NSString *)rawSearchText;
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

        NSError *error = nil;
        bangs = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:bangsURL]] 
                                                options:0 
                                                  error:&error];
        NSLog(@"error: %@ : %@",error, [error userInfo]);
        NSLog(@"bangs: %@",bangs);
        return self;
    }
    return nil;
}

#pragma mark - Downloading and returning search suggestions

-(NSArray *)suggestionsForSearchText:(NSString *)searchText {
    NSString *bang = [self bangFromSearchText:searchText];
    searchText = [self stripBangFromSearchText:searchText];
    
    NSString *bestMatch = nil;
    
    for(NSString *suggestionText in suggestionsCache) {
        if([searchText hasPrefix:suggestionText] && (suggestionText.length > bestMatch.length))
            bestMatch = suggestionText;
    }
    
    NSMutableArray *suggestions = [(bestMatch ? [suggestionsCache objectForKey:bestMatch] : [NSArray array]) mutableCopy];
    if(!bang)
        return [suggestions copy];
    
    for(int i=0;i<suggestions.count;i++) {
        NSMutableDictionary *item = [[suggestions objectAtIndex:i] mutableCopy];
        NSString *phrase = [item objectForKey:ksDDGSearchControllerServerKeyPhrase];
        [item setObject:[NSString stringWithFormat:@"%@ %@",bang,phrase] 
                 forKey:ksDDGSearchControllerServerKeyPhrase];
        [suggestions replaceObjectAtIndex:i withObject:[item copy]];
    }
    return [suggestions copy];
}

-(void)downloadSuggestionsForSearchText:(NSString *)searchText success:(void (^)(void))success {
    searchText = [self stripBangFromSearchText:searchText];
    
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


#pragma -
#pragma mark Handling bangs

// TODO (ishaan): Bangs are half-working right now. Fix them, eventually...

-(NSString *)stripBangFromSearchText:(NSString *)rawSearchText {
    NSMutableArray *words = [[rawSearchText componentsSeparatedByString:@" "] mutableCopy];
    
    for(int i=0;i<[words count];i++) {
        NSString *word = [words objectAtIndex:i];
        if([bangs objectForKey:[word lowercaseString]]) {
            [words removeObjectAtIndex:i];
            
            return [words componentsJoinedByString:@" "];
        }
    }
    return rawSearchText;
}

-(NSString *)bangFromSearchText:(NSString *)rawSearchText {
    NSMutableArray *words = [[rawSearchText componentsSeparatedByString:@" "] mutableCopy];
    
    for(int i=0;i<[words count];i++) {
        NSString *word = [words objectAtIndex:i];
        if([bangs objectForKey:[word lowercaseString]]) {
            NSLog(@"returning %@",word);
            return word;
        }
    }

    return nil;
}

@end
