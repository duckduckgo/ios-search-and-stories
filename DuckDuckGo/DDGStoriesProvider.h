//
//  DDGStoriesProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/17/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGStoriesProvider : NSObject

+(DDGStoriesProvider *)sharedProvider;

-(NSArray *)stories;
-(void)downloadStoriesInTableView:(UITableView *)tableView success:(void (^)())success;

@end
