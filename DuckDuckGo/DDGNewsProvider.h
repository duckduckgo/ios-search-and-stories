//
//  DDGStoriesProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGNewsProvider : NSObject {
    NSArray *lastSectionOffsetsArray;
    NSArray *lastSectionOffsets;
}
@property (nonatomic, copy) NSString *sourceFilter;

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
- (NSString*)feedForURL:(NSString*)url;

@end
