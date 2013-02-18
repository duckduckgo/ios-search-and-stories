//
//  DDGStoriesProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import "DDGNewsProvider.h"
#import "DDGCache.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGStory.h"
#import "Constants.h"
#import "UIImage+Resizing.h"

@implementation DDGNewsProvider
static DDGNewsProvider *sharedProvider;

#pragma mark - Lifecycle

-(id)init {
    self = [super init];
    if(self) {
        if(![DDGCache objectForKey:@"customSources" inCache:@"misc"])
            [DDGCache setObject:[[NSArray alloc] init] forKey:@"customSources" inCache:@"misc"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(lowMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

+(DDGNewsProvider *)sharedProvider {
    @synchronized(self) {
        if(!sharedProvider)
            sharedProvider = [[DDGNewsProvider alloc] init];
        
        return sharedProvider;
    }
}

-(void)lowMemoryWarning {
    NSLog(@"Low memory warning received, unloading images...");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *stories = self.stories;
        for(DDGStory *story in stories)
            [story unloadImage];
    });
}

#pragma mark - Downloading sources

-(void)downloadSourcesFinished:(void (^)())finished {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSURL *url = [NSURL URLWithString:kDDGTypeInfoURLString];
        NSData *response = [NSData dataWithContentsOfURL:url];
        if(!response) {
            // could not fetch data
            if(finished) {
                NSLog(@"Download sources failed!");
                dispatch_async(dispatch_get_main_queue(), ^{
                    finished();
                });
            }
            return;
        }
        
        NSError *error = nil;
        NSArray *newSources = [NSJSONSerialization JSONObjectWithData:response 
                                                              options:NSJSONReadingMutableContainers 
                                                                error:&error];
        if(error) {
            NSLog(@"Error reading sources JSON! %@",error.userInfo);
            if(finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finished();
                });
            }
            return;
        }
        
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
                UIImage *image = [UIImage imageWithData:data];
                CGSize maxSize = CGSizeMake(24.0, 24.0);
                if (image.size.width > maxSize.width
                    || image.size.height > maxSize.height)
                    image = [image scaleToFitSize:CGSizeMake(24.0, 24.0)];
                [DDGCache setObject:image forKey:[source objectForKey:@"link"] inCache:@"sourceImages"];
            }
        }];
            
        NSArray *sortedCategories = [categories sortedArrayUsingSelector:@selector(compare:)];
        
        [DDGCache setObject:newSourcesDict forKey:@"sources" inCache:@"misc"];
        [DDGCache setObject:sortedCategories forKey:@"sourceCategories" inCache:@"misc"];
        
        if(finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finished();
            });
        }
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

- (NSString*)feedForURL:(NSString*)url
{
	// scan stories trying to find a match to url
	NSArray *stories = [self stories];
	for (DDGStory *story in stories)
		if ([story.url isEqualToString:url])
			// found story so return feed
			return story.feed;

	return nil;
}

-(void)downloadStoriesInTableView:(UITableView *)tableView finished:(void (^)())finished {
    // do everything in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {

        
        NSString *urlStr = kDDGStoriesURLString;
        urlStr = [urlStr stringByAppendingString:[[self enabledSourceIDs] componentsJoinedByString:@","]];
        
        NSURL *url = [NSURL URLWithString:urlStr];
        NSData *response = [NSData dataWithContentsOfURL:url];
        if(!response) {
            NSLog(@"Download stories failed!");
            dispatch_async(dispatch_get_main_queue(), ^{
                if(finished)
                    finished();
            });
            return; // could not download stories
        }
        NSError *error = nil;
        NSMutableArray *newStories = [NSJSONSerialization JSONObjectWithData:response
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&error];
        if(error) {
            NSLog(@"Error generating stories JSON: %@",error.userInfo);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(finished)
                    finished();
            });
            return;
        }

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        for(int i=0; i<newStories.count; i++) {
            NSDictionary *storyDict = [newStories objectAtIndex:i];
            // if it exists, try to use an existing old story object because it has a preloaded image
            DDGStory *story;
            NSArray *stories = self.stories;
            for(DDGStory *oldStory in stories) {
                if([oldStory.storyID isEqualToString:[storyDict objectForKey:@"id"]]) {
                    story = oldStory;
                }
            }
            if(!story) {
                story = [[DDGStory alloc] init];
                story.storyID = [storyDict objectForKey:@"id"];
                story.title = [storyDict objectForKey:@"title"];
                story.url = [storyDict objectForKey:@"url"];
                if([storyDict objectForKey:@"feed"] && [storyDict objectForKey:@"feed"] != [NSNull null])
                    story.feed = [storyDict objectForKey:@"feed"];
                story.date = [formatter dateFromString:[[storyDict objectForKey:@"timestamp"] substringToIndex:19]];
                story.imageURL = [storyDict objectForKey:@"image"];
            }
            [newStories replaceObjectAtIndex:i withObject:story];
        }
        
        [self downloadCustomStoriesForKeywords:self.customSources toArray:newStories];
        
        [newStories sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            DDGStory *story1 = (DDGStory *)obj1;
            DDGStory *story2 = (DDGStory *)obj2;
            return [story2.date compare:story1.date];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:self.stories];
            NSArray *removedStories = [self indexPathsofStoriesInArray:self.stories andNotArray:newStories];
            
            // delete old story images
            NSArray *oldStories = self.stories;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                for(NSIndexPath *indexPath in removedStories) {
                    DDGStory *removedStory = [oldStories objectAtIndex:indexPath.row];
                    [removedStory deleteImage];
                }                
            });
            
            // update the stories array and last-updated time
            [DDGCache setObject:newStories forKey:@"stories" inCache:@"misc"];
            [DDGCache setObject:[NSDate date] forKey:@"storiesUpdated" inCache:@"misc"];
            
            // update the table view with added and removed stories
            [tableView beginUpdates];
            [tableView insertRowsAtIndexPaths:addedStories
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView deleteRowsAtIndexPaths:removedStories
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView endUpdates];
        });
        
        // download story images
        [newStories iterateConcurrentlyWithThreads:6 priority:DISPATCH_QUEUE_PRIORITY_BACKGROUND block:^(int i, id obj) {
            if([(DDGStory *)obj downloadImage])
                dispatch_async(dispatch_get_main_queue(), ^{
                    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                });
        }];
        
        
        // and we're done!
        dispatch_async(dispatch_get_main_queue(), ^{
           if(finished)
               finished();
        });
    });
}

// this method ignores stories from custom sources
-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    
    for(int i=0;i<newStories.count;i++) {
        NSString *storyID = [[newStories objectAtIndex:i] storyID];
        
        BOOL matchFound = NO;
        for(DDGStory *oldStory in oldStories) {
            if([storyID isEqualToString:[oldStory storyID]]) {
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

-(void)downloadCustomStoriesForKeywords:(NSArray *)keywords toArray:(NSMutableArray *)newStories {
    
    [keywords iterateConcurrentlyWithThreads:6 block:^(int i, id obj) {
        NSString *newsKeyword = (NSString *)obj;
        NSString *urlString = [kDDGCustomStoriesURLString stringByAppendingString:[newsKeyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        if(!response) {
            NSLog(@"Download custom stories from %@ failed!",urlString);
        } else {
            NSError *error = nil;
            NSArray *news = [NSJSONSerialization JSONObjectWithData:response
                                                            options:0
                                                              error:&error];
            if(error) {
                NSLog(@"Error reading custom stories from %@: %@",urlString,error.userInfo);
                return;
            }
            for(NSDictionary *newsItem in news) {
                // TODO: when i get back, make sure all of the keys in newsItem actually exist before attempting to do any of this. (data robustness)
                for(NSString *key in @[ @"title", @"url", @"image", @"date" ]) {
                    if(![newsItem objectForKey:key]) {
                        NSLog(@"Error: news item doesn't have %@ attribute!",key);
                        return;
                    }
                }
                
                DDGStory *story = [[DDGStory alloc] init];
                story.storyID = [@"CustomSource" stringByAppendingString:[self sha1:[[newsItem allValues] componentsJoinedByString:@"~"]]];
                story.title = [newsItem objectForKey:@"title"];
                story.url = [newsItem objectForKey:@"url"];
                story.imageURL = [newsItem objectForKey:@"image"];
                story.date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[[newsItem objectForKey:@"date"] intValue]];
                
                @synchronized(newStories) {
                    [newStories addObject:story];
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
