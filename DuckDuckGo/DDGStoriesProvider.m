//
//  DDGStoriesProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import "DDGStoriesProvider.h"
#import "DDGCache.h"

#import "NSArray+ConcurrentIteration.h"

@implementation DDGStoriesProvider
static DDGStoriesProvider *sharedProvider;

#pragma mark - Lifecycle

+(DDGStoriesProvider *)sharedProvider {
    @synchronized(self) {
        if(!sharedProvider)
            sharedProvider = [[DDGStoriesProvider alloc] init];
        
        return sharedProvider;
    }
}

-(id)init {
    self = [super init];
    if(self) {
        NSData *storiesData = [NSData dataWithContentsOfFile:[DDGStoriesProvider storiesPath]];
        if(!storiesData) // NSJSONSerialization complains if it's passed nil, so we give it an empty NSData instead
            storiesData = [NSData data];
        self.stories = [NSJSONSerialization JSONObjectWithData:storiesData
                                                       options:0
                                                         error:nil];
    }
    return self;
}

#pragma mark - Downloading stories

-(void)downloadStoriesInTableView:(UITableView *)tableView success:(void (^)())success {
    // do everything in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        
        NSURL *url = [NSURL URLWithString:@"http://caine.duckduckgo.com/watrcoolr.js?o=json"];
        NSData *response = [NSData dataWithContentsOfURL:url];
        NSArray *newStories = [NSJSONSerialization JSONObjectWithData:response
                                                              options:0
                                                                error:nil];
        
        NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:self.stories];
        NSArray *removedStories = [self indexPathsofStoriesInArray:self.stories andNotArray:newStories];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // update the stories array
            self.stories = newStories;
            
            // update the table view with added and removed stories
            [tableView beginUpdates];
            [tableView insertRowsAtIndexPaths:addedStories
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView deleteRowsAtIndexPaths:removedStories
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView endUpdates];
            
            // save the new stories
            [response writeToFile:[DDGStoriesProvider storiesPath] atomically:YES];
            
            // execute the given callback
            success();
        });
        
        // download story images (this method doesn't return until all story images are downloaded)
        [newStories iterateConcurrentlyWithThreads:5 block:^(int i, id obj) {
            NSDictionary *story = (NSDictionary *)obj;
            BOOL reload = NO;
            
            if(![DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"storyImages"]) {
                
                // main image: download it and resize it as needed
                NSString *imageURL = [story objectForKey:@"image"];
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
                UIImage *image = [UIImage imageWithData:imageData];
                
                if(!image)
                    image = [UIImage imageNamed:@"noimage.png"];

                [DDGCache setObject:imageData forKey:[story objectForKey:@"id"] inCache:@"storyImages"];
                reload = YES;
            }
            
            if(![DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"faviconImages"]) {
                // favicon
                NSString *storyURL = [story objectForKey:@"url"];
                [self loadFaviconForURLString:storyURL storyID:[story objectForKey:@"id"]];
                reload = YES;
            }
            
            if(reload) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                });
            }
            
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // execute the given callback
            success();
        });
            
    });
}

-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    
    for(int i=0;i<newStories.count;i++) {
        NSString *storyID = [[newStories objectAtIndex:i] objectForKey:@"id"];
        
        BOOL matchFound = NO;
        for(NSDictionary *oldStory in oldStories) {
            if([storyID isEqualToString:[oldStory objectForKey:@"id"]]) {
                matchFound = YES;
                break;
            }
        }
        
        if(!matchFound)
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    return [indexPaths copy];
}

-(NSURL *)faviconURLForDomain:(NSString *)domain {
    // http://i2.duck.co/i/reddit.com.ico
    NSString *faviconURLString = [NSString stringWithFormat:@"http://i2.duck.co/i/%@.ico",domain];
    return [NSURL URLWithString:faviconURLString];
}

-(void)loadFaviconForURLString:(NSString *)urlString storyID:(NSString *)storyID {
    if(!urlString || [urlString isEqual:[NSNull null]])
        return;
    
    NSString *domain = [[NSURL URLWithString:urlString] host];
    
    while(![DDGCache objectForKey:storyID inCache:@"faviconImages"]) {
        NSData *response = [NSData dataWithContentsOfURL:[self faviconURLForDomain:domain]];
        [DDGCache setObject:response forKey:storyID inCache:@"faviconImages"];
        
        NSMutableArray *domainParts = [[domain componentsSeparatedByString:@"."] mutableCopy];
        if(domainParts.count == 1)
            return; // we're definitely down to just a TLD by now and still couldn't get a favicon.
        [domainParts removeObjectAtIndex:0];
        domain = [domainParts componentsJoinedByString:@"."];
    }
}

+(NSString *)storiesPath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"stories.json"];
}

@end
