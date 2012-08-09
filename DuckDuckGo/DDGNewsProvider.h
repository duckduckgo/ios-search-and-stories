//
//  DDGStoriesProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGNewsProvider : NSObject {
    NSManagedObjectContext *mainMOC;
    NSManagedObjectContext *backgroundMOC;
    dispatch_queue_t backgroundMOCQueue;
    
    NSArray *lastSectionOffsetsArray;
    NSArray *lastSectionOffsets;
}

+(DDGNewsProvider *)sharedProvider;

-(void)downloadSourcesFinished:(void (^)())finished;
-(NSDictionary *)sources;
-(NSArray *)enabledSourceIDs;
-(void)setSourceWithID:(NSString *)sourceID enabled:(BOOL)enabled;

-(NSArray *)customSources;
-(void)addCustomSource:(NSString *)customSource;
-(void)deleteCustomSourceAtIndex:(NSUInteger)index;

-(NSArray *)stories;
-(void)downloadStoriesInTableView:(UITableView *)tableView finished:(void (^)())finished;
-(void)downloadCustomStoriesForKeywords:(NSArray *)keywords toArray:(NSMutableArray *)newStories;

-(NSArray *)sectionDates;
-(void)generateSectionDates;
-(NSUInteger)numberOfStoriesInSection:(NSInteger)section inArray:(NSArray *)array;
-(NSDictionary *)storyAtIndexPath:(NSIndexPath *)indexPath inArray:(NSArray *)array;
-(NSIndexPath *)indexPathForStoryAtIndex:(NSUInteger)index inArray:(NSArray *)array;


@end
