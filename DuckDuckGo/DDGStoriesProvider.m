//
//  DDGStoriesProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import "DDGStoriesProvider.h"
#import "DDGCache.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSArray+ConcurrentIteration.h"
#import "UIImage-DDG.h"

@implementation DDGStoriesProvider
static DDGStoriesProvider *sharedProvider;

#pragma mark - Lifecycle

-(id)init {
    self = [super init];
    if(self) {
        if(![DDGCache objectForKey:@"customSources" inCache:@"misc"])
            [DDGCache setObject:[[NSArray alloc] init] forKey:@"customSources" inCache:@"misc"];
    }
    return self;
}

+(DDGStoriesProvider *)sharedProvider {
    @synchronized(self) {
        if(!sharedProvider)
            sharedProvider = [[DDGStoriesProvider alloc] init];
        
        return sharedProvider;
    }
}

#pragma mark - Downloading sources

-(void)downloadSourcesFinished:(void (^)())finished {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSURL *url = [NSURL URLWithString:@"http://caine.duckduckgo.com/watrcoolr.js?o=json&type_info=1"];
        NSData *response = [NSData dataWithContentsOfURL:url];
        if(!response)
            return; // could not fetch data
        
        NSArray *newSources = [NSJSONSerialization JSONObjectWithData:response 
                                                              options:NSJSONReadingMutableContainers 
                                                                error:nil];
        NSMutableDictionary *newSourcesDict = [[NSMutableDictionary alloc] init];
        NSMutableArray *categories = [[NSMutableArray alloc] init];
        
        
        for(NSMutableDictionary *source in newSources) {

            NSMutableArray *category = [newSourcesDict objectForKey:[source objectForKey:@"category"]];
            if(!category) {
                category = [[NSMutableArray alloc] init];
                [newSourcesDict setObject:category forKey:[source objectForKey:@"category"]];
                [categories addObject:[source objectForKey:@"category"]];
            }
            [category addObject:source];
            
            if(![DDGCache objectForKey:[source objectForKey:@"id"] inCache:@"enabledSources"])
                [self setSourceWithID:[source objectForKey:@"id"] enabled:([[source objectForKey:@"default"] intValue] == 1)];
        }
        
        [newSources iterateConcurrentlyWithThreads:6 block:^(int i, id obj) {
            NSDictionary *source = (NSDictionary *)obj;
            if(![DDGCache objectForKey:[source objectForKey:@"link"] inCache:@"sourceImages"]) {
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[source objectForKey:@"image"]]];
                UIImage *image = [UIImage ddg_decompressedImageWithData:data];
                [DDGCache setObject:image forKey:[source objectForKey:@"link"] inCache:@"sourceImages"];
            }
        }];
            
        NSArray *sortedCategories = [categories sortedArrayUsingSelector:@selector(compare:)];
        
        [DDGCache setObject:newSourcesDict forKey:@"sources" inCache:@"misc"];
        [DDGCache setObject:sortedCategories forKey:@"sourceCategories" inCache:@"misc"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            finished();
        });
    });
}

-(NSDictionary *)sources {
    return [DDGCache objectForKey:@"sources" inCache:@"misc"];
}

-(NSArray *)enabledSourceIDs {
    NSDictionary *sources = [DDGCache cacheNamed:@"enabledSources"];
    NSMutableArray *enabledSources = [[NSMutableArray alloc] initWithCapacity:sources.count];
    for(NSString *sourceID in sources) {
        if([[sources objectForKey:sourceID] boolValue])
            [enabledSources addObject:sourceID];
    }
    return enabledSources;
}

-(void)setSourceWithID:(NSString *)sourceID enabled:(BOOL)enabled {
    [DDGCache setObject:@(enabled) forKey:sourceID inCache:@"enabledSources"];
}

#pragma mark - Downloading stories

-(NSArray *)stories {
    return [DDGCache objectForKey:@"stories" inCache:@"misc"];
}

-(void)downloadStoriesInTableView:(UITableView *)tableView finished:(void (^)())finished {
    // do everything in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {

        
        NSString *urlStr = @"http://caine.duckduckgo.com/watrcoolr.js?o=json&s=";
        urlStr = [urlStr stringByAppendingString:[[self enabledSourceIDs] componentsJoinedByString:@","]];
        
        NSURL *url = [NSURL URLWithString:urlStr];
        NSData *response = [NSData dataWithContentsOfURL:url];
        if(!response) {
            NSLog(@"downloading stories failed!");
            dispatch_async(dispatch_get_main_queue(), ^{
                finished();
            });
            return; // could not download stories
        }
        NSMutableArray *newStories = [NSJSONSerialization JSONObjectWithData:response
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:nil];
        
        [self downloadCustomStoriesToArray:newStories];
        [newStories sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj2 objectForKey:@"timestamp"] compare:[obj1 objectForKey:@"timestamp"]
                                                     options:0
                                                       range:NSMakeRange(0, 19)];
        }];
        
        
        NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:self.stories];
        NSMutableArray *removedStories = [self indexPathsofStoriesInArray:self.stories andNotArray:newStories].mutableCopy;
                
        dispatch_async(dispatch_get_main_queue(), ^{
            // update the stories array
            [DDGCache setObject:newStories forKey:@"stories" inCache:@"misc"];
            
            // record the last-updated time
            [DDGCache setObject:[NSDate date] forKey:@"storiesUpdated" inCache:@"misc"];
            
            // update the table view with added and removed stories
            [tableView beginUpdates];
            [tableView insertRowsAtIndexPaths:addedStories
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView deleteRowsAtIndexPaths:removedStories
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView endUpdates];
        });
        
        // download story images (this method doesn't return until all story images are downloaded)
        // synchronize to prevent multiple simultaneous refreshes from downloading images on top of each other and wasting bandwidth
        @synchronized(self) {
            [newStories iterateConcurrentlyWithThreads:6 block:^(int i, id obj) {
                NSDictionary *story = (NSDictionary *)obj;
                BOOL reload = NO;

                if(![DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"storyImages"]) {
                    
                    // main image: download it and resize it as needed
                    NSString *imageURL = [story objectForKey:@"image"];
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
                    UIImage *image = [UIImage ddg_decompressedImageWithData:imageData];

                    if(!image)
                        image = [UIImage imageNamed:@"noimage.png"];

                    [DDGCache setObject:image forKey:[story objectForKey:@"id"] inCache:@"storyImages"];
                    reload = YES;
                }
                            
                if(reload) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    });
                }
            }];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            finished();
        });
    });
}

// this method ignores stories from custom sources
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

#pragma mark - Custom sources

-(NSArray *)customSources {
    return [DDGCache objectForKey:@"customSources" inCache:@"misc"];
}

-(void)addCustomSource:(NSString *)customSource {
    [DDGCache setObject:[self.customSources arrayByAddingObject:customSource]
                 forKey:@"customSources"
                inCache:@"misc"];
}

-(void)deleteCustomSourceAtIndex:(NSUInteger)index {
    NSMutableArray *customSources = [self.customSources mutableCopy];
    [customSources removeObjectAtIndex:index];
    [DDGCache setObject:customSources.copy forKey:@"customSources" inCache:@"misc"];
}

-(void)downloadCustomStoriesToArray:(NSMutableArray *)newStories {
    
    [self.customSources iterateConcurrentlyWithThreads:6 block:^(int i, id obj) {
        NSString *newsKeyword = (NSString *)obj;
        NSString *urlString = [@"http://caine.duckduckgo.com/news.js?o=json&t=m&q=" stringByAppendingString:[newsKeyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        if(!response)
            NSLog(@"download custom stories from source failed!");
        if(response) {
            NSArray *news = [NSJSONSerialization JSONObjectWithData:response
                                                            options:0
                                                              error:nil];
            for(NSDictionary *newsItem in news) {
                NSMutableDictionary *story = [NSMutableDictionary dictionaryWithCapacity:5];
                [story setObject:[newsItem objectForKey:@"title"] forKey:@"title"];
                [story setObject:[newsItem objectForKey:@"url"] forKey:@"url"];
                if([newsItem objectForKey:@"image"])
                    [story setObject:[newsItem objectForKey:@"image"] forKey:@"image"];
                NSString *date = [[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[[newsItem objectForKey:@"date"] intValue]] description];
                [story setObject:date forKey:@"timestamp"];
                NSString *storyID = [@"CustomSource" stringByAppendingString:[self sha1:[[newsItem allValues] componentsJoinedByString:@"~"]]];
                [story setObject:storyID forKey:@"id"];
                @synchronized(newStories) {
                    [newStories addObject:story.copy];
                }
            }
        }
    }];
}

#pragma mark - Helpers

-(NSString*)sha1:(NSString*)input {
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}
@end
