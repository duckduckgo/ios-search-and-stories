//
//  DDGBookmarksProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import "DDGBookmarksProvider.h"
#import "DDGCache.h"

@implementation DDGBookmarksProvider
static DDGBookmarksProvider *sharedProvider;

+(DDGBookmarksProvider *)sharedProvider {
    if(!sharedProvider)
        sharedProvider = [[DDGBookmarksProvider alloc] init];
    return sharedProvider;
}

-(NSArray *)bookmarks {
    if(![DDGCache objectForKey:@"bookmarks" inCache:@"misc"])
        [DDGCache setObject:@[] forKey:@"bookmarks" inCache:@"misc"];
    return [DDGCache objectForKey:@"bookmarks" inCache:@"misc"];
}

-(BOOL)bookmarkExistsForPageWithURL:(NSURL *)url {
    NSArray *bookmarks = self.bookmarks;
    for(NSDictionary *bookmark in bookmarks) {
        if([[bookmark objectForKey:@"url"] isEqual:url])
            return YES;
    }
    
    return NO;
}

-(void)bookmarkPageWithTitle:(NSString *)title URL:(NSURL *)url {
    NSArray *bookmarks = self.bookmarks;
    bookmarks = [bookmarks arrayByAddingObject:@{
                 @"title": title,
                 @"url": url,
                 @"date": [NSDate date]
                 }];
    [DDGCache setObject:bookmarks forKey:@"bookmarks" inCache:@"misc"];
}

-(void)unbookmarkPageWithURL:(NSURL *)url {
    NSArray *bookmarks = self.bookmarks;
    for(int i=0; i < bookmarks.count; i++) {
        if([[[bookmarks objectAtIndex:i] objectForKey:@"url"] isEqual:url]) {
            [self deleteBookmarkAtIndex:i];
            return;
        }
    }
}

-(void)deleteBookmarkAtIndex:(NSInteger)index {
    NSMutableArray *bookmarks = self.bookmarks.mutableCopy;
    [bookmarks removeObjectAtIndex:index];
    [DDGCache setObject:bookmarks.copy forKey:@"bookmarks" inCache:@"misc"];
}

@end
