//
//  DDGBangsProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGBangsProvider.h"

// for now this class is a stub; eventually it will handle downloading lists of bangs, custom user-defined bangs, etc.
// the hard-coded list of bangs was copied from https://duckduckgo.com/bang.html

@interface DDGBangsProvider (Private)
+(NSString *)bangsFilePath;
+(void)downloadBangsJSON;
@end

@implementation DDGBangsProvider

static NSArray *bangs;

+(NSArray *)bangsWithPrefix:(NSString *)prefix {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSArray *bangsArray = self.bangs;
    for(NSDictionary *bang in bangsArray)
        if([[bang objectForKey:@"name"] hasPrefix:prefix])
            [result addObject:bang];
    
    NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score"
                                                                    ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:firstDescriptor, nil];
    NSArray *sortedResult = [result sortedArrayUsingDescriptors:sortDescriptors];
    if(sortedResult.count > 50)
        return [sortedResult subarrayWithRange:NSMakeRange(0, 50)];
    else
        return sortedResult;
}

+(NSArray *)bangs {
    if(!bangs) {
        NSData *bangsJSON = [NSData dataWithContentsOfFile:[self bangsFilePath]];
        if(!bangsJSON) {
            [self downloadBangsJSON];
            bangsJSON = [NSData dataWithContentsOfFile:[self bangsFilePath]];
        } else {
            [self performSelectorInBackground:@selector(downloadBangsJSON) withObject:nil];
        }
        NSArray *unsortedBangs = [NSJSONSerialization JSONObjectWithData:bangsJSON options:0 error:nil];
        
        bangs = [unsortedBangs sortedArrayUsingComparator:^(id obj1, id obj2) {
            return [(NSNumber *)[(NSDictionary *)obj1 objectForKey:@"score"] compare:[(NSDictionary *)obj2 objectForKey:@"score"]];
        }];

    }
    return bangs;
}

+(void)downloadBangsJSON {
    // TODO: once there's an actual URL to copy bangs from, uncomment the line below, insert the URL, and delete the line below it.
    //NSData *bangsJSON = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://example.com"]];
    NSData *bangsJSON = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bangs" ofType:@"json"]];
    [bangsJSON writeToFile:[self bangsFilePath] atomically:YES];
    @synchronized(self) {
        bangs = nil; // clear the bangs array so it gets reloaded from the file next time
    }
}

+(NSString *)bangsFilePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"bangs.json"];
}

                             
@end
