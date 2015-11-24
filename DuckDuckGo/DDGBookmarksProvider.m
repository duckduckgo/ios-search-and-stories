//
//  DDGBookmarksProvider.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import "DDGBookmarksProvider.h"
#import "DDGAppDelegate.h"

NSString * const DDGBookmarksKey = @"bookmarks";

@implementation DDGBookmarksProvider
static DDGBookmarksProvider *sharedProvider;

+(DDGBookmarksProvider *)sharedProvider {
    if(!sharedProvider)
        sharedProvider = [[DDGBookmarksProvider alloc] init];
    return sharedProvider;
}

-(NSArray *)bookmarks {
    if(![[NSUserDefaults standardUserDefaults] objectForKey:DDGBookmarksKey])
        [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:DDGBookmarksKey];
    return [[NSUserDefaults standardUserDefaults] objectForKey:DDGBookmarksKey];
}

-(BOOL)bookmarkExistsForPageWithURL:(NSURL *)url {
    NSArray *bookmarks = self.bookmarks;
    NSString *urlString = [url absoluteString];
    for(NSDictionary *bookmark in bookmarks) {
        if([[bookmark objectForKey:@"url"] isEqual:urlString])
            return YES;
    }
    
    return NO;
}

-(void)bookmarkPageWithTitle:(NSString *)title feed:(NSString*)feed URL:(NSURL *)url
{
    NSArray *bookmarks = self.bookmarks;
    bookmarks = [bookmarks arrayByAddingObject:
				 @{
                 @"title": title,
                 @"url": [url absoluteString],
				 @"feed": feed ? feed : @""
                 }];
    [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:DDGBookmarksKey];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [((DDGAppDelegate*)[[UIApplication sharedApplication] delegate]) updateShortcuts];
    });
}

-(void)unbookmarkPageWithURL:(NSURL *)url {
    NSArray *bookmarks = self.bookmarks;
    NSString *urlString = [url absoluteString];
    for(int i=0; i < bookmarks.count; i++) {
        if([[[bookmarks objectAtIndex:i] objectForKey:@"url"] isEqual:urlString]) {
            [self deleteBookmarkAtIndex:i];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [((DDGAppDelegate*)[[UIApplication sharedApplication] delegate]) updateShortcuts];
            });
            
            return;
        }
    }
}

-(void)deleteBookmarkAtIndex:(NSInteger)index {
    NSMutableArray *bookmarks = self.bookmarks.mutableCopy;
    [bookmarks removeObjectAtIndex:index];
    [[NSUserDefaults standardUserDefaults] setObject:bookmarks.copy forKey:DDGBookmarksKey];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [((DDGAppDelegate*)[[UIApplication sharedApplication] delegate]) updateShortcuts];
    });
}

-(void)moveBookmarkAtIndex:(NSInteger)from toIndex:(NSInteger)to {
    NSMutableArray *bookmarks = self.bookmarks.mutableCopy;
    NSDictionary *bookmark = [bookmarks objectAtIndex:from];
    [bookmarks removeObjectAtIndex:from];
    [bookmarks insertObject:bookmark atIndex:to];
    [[NSUserDefaults standardUserDefaults] setObject:bookmarks.copy forKey:DDGBookmarksKey];
}

@end
