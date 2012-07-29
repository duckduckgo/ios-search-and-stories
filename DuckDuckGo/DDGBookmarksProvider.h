//
//  DDGBookmarksProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGBookmarksProvider : NSObject

+(DDGBookmarksProvider *)sharedProvider;

-(BOOL)bookmarkExistsForPageWithURL:(NSURL *)url;
-(void)bookmarkPageWithTitle:(NSString *)title URL:(NSURL *)url;
-(void)unbookmarkPageWithURL:(NSURL *)url;

-(NSArray *)bookmarks;
-(void)deleteBookmarkAtIndex:(NSInteger)index;

@end
