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

@implementation DDGNewsProvider
static DDGNewsProvider *sharedProvider;

#pragma mark - Lifecycle

-(id)init {
    self = [super init];
    if(self) {
        if(![DDGCache objectForKey:@"customSources" inCache:@"misc"])
            [DDGCache setObject:[[NSArray alloc] init] forKey:@"customSources" inCache:@"misc"];

        if(![NSThread isMainThread]) {
            mainMOC = [[NSManagedObjectContext alloc] init];
            mainMOC.persistentStoreCoordinator = [(DDGAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                mainMOC = [[NSManagedObjectContext alloc] init];
                mainMOC.persistentStoreCoordinator = [(DDGAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
            });
        }
        
        backgroundMOCQueue = dispatch_queue_create("DDGNewsProviderBackgroundMOCQueue", NULL);
        dispatch_async(backgroundMOCQueue, ^{
            backgroundMOC = [[NSManagedObjectContext alloc] init];
            backgroundMOC.persistentStoreCoordinator = [(DDGAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
        });
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
        
        [self downloadCustomStoriesForKeywords:self.customSources toArray:newStories];
        [newStories sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj2 objectForKey:@"timestamp"] compare:[obj1 objectForKey:@"timestamp"]
                                                     options:0
                                                       range:NSMakeRange(0, 19)];
        }];
                        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *oldSectionDates = self.sectionDates;
            [self generateSectionDates];

            NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:self.stories];
            NSMutableArray *removedStories = [self indexPathsofStoriesInArray:self.stories andNotArray:newStories].mutableCopy;
            
            // if generateSectionDates actually changed the dates, the entire table view is now out of date and messed up, so we need to fix with a reload before proceeding.
            // alternately, you could try to figure out what changed in code and notify the table view, which would make the animation smoother, but it's a headache to code
            // TODO: consider this solution: rewrite generateSectionDates/sectionOffsets to make a date group for every single day that has stories (instead of a catch-all "earlier" category). then the changes from generateSectionDates will be limited to adding sections in the front and deleting sections in the back and we can try to figure those out. OR just switch to core data (probably the better option in the long term)
            if(![self.sectionDates isEqualToArray:oldSectionDates])
                [tableView reloadData];
            
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
                    [DDGCache setObject:image forKey:[story objectForKey:@"id"] inCache:@"storyImages"];
                    reload = YES;
                }
                            
                if(reload) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [tableView reloadRowsAtIndexPaths:@[[self indexPathForStoryAtIndex:i inArray:self.stories]] withRowAnimation:UITableViewRowAnimationFade];
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
            [indexPaths addObject:[self indexPathForStoryAtIndex:i inArray:newStories]];
    }
    return [indexPaths copy];
}

#pragma mark - Grouping stories

-(NSArray *)sectionDates {
    NSArray *dates = [DDGCache objectForKey:@"sectionDates" inCache:@"misc"];
    if(!dates) {
        [self generateSectionDates];
        dates = [DDGCache objectForKey:@"sectionDates" inCache:@"misc"];
    }
    return dates;
}

-(void)generateSectionDates {
    NSArray *oldSectionDates = [DDGCache objectForKey:@"sectionDates" inCache:@"misc"];
    
    NSMutableArray *dates = @[[self dateAtBeginningOfDayForDate:[NSDate date]]].mutableCopy;
    for(int i=0;i<5;i++)
        [dates addObject:[self dateByAddingDays:-1 toDate:[dates lastObject]]];
    [dates addObject:[NSDate distantPast]];
    
    [DDGCache setObject:dates.copy forKey:@"sectionDates" inCache:@"misc"];
    
    // if we actually changed something, be sure to clear the section offsets cache
    if(![self.sectionDates isEqualToArray:oldSectionDates]) {
        lastSectionOffsetsArray = nil;
        lastSectionOffsets = nil;
    }
}

-(NSArray *)sectionOffsetsForArray:(NSArray *)array {
    if(!array)
        array = self.stories;
    
    if(array != lastSectionOffsetsArray) {
        NSArray *dates = self.sectionDates;
        NSMutableArray *offsets = @[@0, @0, @0, @0, @0, @0, @0, @(array.count)].mutableCopy;
        
        int dateIdx = 0;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        for(int i=0; i<array.count; i++) {
            NSDictionary *story = [array objectAtIndex:i];
            NSString *timestamp = [[story objectForKey:@"timestamp"] substringToIndex:19];
            NSDate *date = [formatter dateFromString:timestamp];

            while([date timeIntervalSince1970] < [[dates objectAtIndex:dateIdx] timeIntervalSince1970]) {
                dateIdx++;
                [offsets replaceObjectAtIndex:dateIdx withObject:@(i)];
            }
        }
        
        lastSectionOffsetsArray = array;
        lastSectionOffsets = offsets.copy;
    }
    
    return lastSectionOffsets;
}

-(NSUInteger)numberOfStoriesInSection:(NSInteger)section inArray:(NSArray *)array {
    NSArray *offsets = [self sectionOffsetsForArray:array];
    return [[offsets objectAtIndex:section+1] intValue] - [[offsets objectAtIndex:section] intValue];
}

-(NSDictionary *)storyAtIndexPath:(NSIndexPath *)indexPath inArray:(NSArray *)array {
    if(!array)
        array = self.stories;
    
    NSArray *offsets = [self sectionOffsetsForArray:array];
    return [array objectAtIndex:[[offsets objectAtIndex:indexPath.section] intValue]+indexPath.row];
}

-(NSIndexPath *)indexPathForStoryAtIndex:(NSUInteger)index inArray:(NSArray *)array {
    if(!array)
        array = self.stories;
    
    NSArray *offsets = [self sectionOffsetsForArray:array];
    int section = 0;
    while([[offsets objectAtIndex:section+1] intValue] <= index)
        section++;
    
    return [NSIndexPath indexPathForRow:index-[[offsets objectAtIndex:section] intValue]
                              inSection:section];
}

// http://oleb.net/blog/2011/12/tutorial-how-to-sort-and-group-uitableview-by-date/
- (NSDate *)dateAtBeginningOfDayForDate:(NSDate *)inputDate {
    // Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];
    
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:inputDate];
    
    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    
    // Convert back, add 1 day, and subtract 1 second
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
    return beginningOfDay;
}

- (NSDate *)dateByAddingDays:(NSInteger)numberOfDays toDate:(NSDate *)inputDate {
    // Use the user's current calendar
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *dateComps = [[NSDateComponents alloc] init];
    [dateComps setDay:numberOfDays];
    
    NSDate *newDate = [calendar dateByAddingComponents:dateComps toDate:inputDate options:0];
    return newDate;
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
