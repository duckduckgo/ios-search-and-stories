//
//  DDGStoriesProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGStoriesProvider : NSObject
@property (nonatomic, strong) NSArray *stories;

+(DDGStoriesProvider *)sharedProvider;
+(NSString *)storiesPath;

-(void)downloadStoriesInTableView:(UITableView *)tableView success:(void (^)())success;

@end
