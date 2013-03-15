//
//  DDGStoriesProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import <Foundation/Foundation.h>

@class DDGStory;
@interface DDGNewsProvider : NSObject {
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

- (NSArray *)stories;
- (NSArray *)storiesMatchingSourceFilter:(NSString *)sourceFilter;

-(void)downloadStoriesFinished:(void (^)())finished;
-(void)downloadCustomStoriesForKeywords:(NSArray *)keywords toArray:(NSMutableArray *)newStories;
- (NSString*)feedForURL:(NSString*)url;

//-(NSArray *)savedStories;
//-(BOOL)storyIsSaved:(DDGStory *)story;
//-(void)saveStory:(DDGStory *)story;
//-(void)unsaveStory:(DDGStory *)story;

@end
