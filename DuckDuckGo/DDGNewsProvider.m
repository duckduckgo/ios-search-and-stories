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
#import "UIImage+DDG.h"
#import "Constants.h"
#import <CoreData/CoreData.h>
#import "DDGAppDelegate.h"
#import "NSManagedObjectContext+DDG.h"

@implementation DDGNewsProvider
static DDGNewsProvider *sharedProvider;

#pragma mark - Lifecycle

-(id)init {
    self = [super init];
    if(self) {
        if(![DDGCache objectForKey:@"customSources" inCache:@"misc"])
            [DDGCache setObject:[[NSArray alloc] init] forKey:@"customSources" inCache:@"misc"];
    
        self.managedObjectContext = [(DDGAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
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
                UIImage *image = [UIImage ddg_decompressedImageWithData:data];
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
        }
        
//        [self downloadCustomStoriesForKeywords:self.customSources toArray:newStories];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            for(NSDictionary *storyDict in newStories) {
                if([[_managedObjectContext fetchObjectsForEntityName:@"Story" withPredicate:@"id == '%@'",[storyDict objectForKey:@"id"]] anyObject])
                    continue;

                NSManagedObject *story = [NSEntityDescription insertNewObjectForEntityForName:@"Story"
                                                                       inManagedObjectContext:_managedObjectContext];
                
                [story setValue:[storyDict objectForKey:@"url"] forKey:@"url"];
                [story setValue:[storyDict objectForKey:@"title"] forKey:@"title"];
                [story setValue:[storyDict objectForKey:@"image"] forKey:@"imageURL"];
                if([storyDict objectForKey:@"feed"] != [NSNull null])
                    [story setValue:[storyDict objectForKey:@"feed"] forKey:@"feed"];
                [story setValue:[storyDict objectForKey:@"id"] forKey:@"id"];
                [story setValue:[formatter dateFromString:[storyDict objectForKey:@"timestamp"]] forKey:@"date"];
            }
            
            NSSet *noImages = [_managedObjectContext fetchObjectsForEntityName:@"Story" withPredicate:@"image == nil"];
            for(NSManagedObject *story in noImages) {
                NSString *imageURL = [story valueForKey:@"imageURL"];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
                    UIImage *image = [UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [story setValue:image forKey:@"image"];
                    });
                });
            }
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            finished();
        });
    });
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
                
                NSMutableDictionary *story = [NSMutableDictionary dictionaryWithCapacity:5];
                [story setObject:[newsItem objectForKey:@"title"] forKey:@"title"];
                [story setObject:[newsItem objectForKey:@"url"] forKey:@"url"];
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
