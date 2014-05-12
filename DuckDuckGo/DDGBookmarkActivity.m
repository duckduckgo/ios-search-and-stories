//
//  DDGBookmarkActivity.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/03/2013.
//
//

#import "DDGBookmarkActivity.h"
#import "DDGBookmarksProvider.h"
#import "SVProgressHUD.h"
#import "DDGStory.h"

@interface DDGBookmarkActivityItem ()
@property (nonatomic, copy, readwrite) NSURL *URL;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *feed;
@property (nonatomic, strong, readwrite) DDGStory *story;
@end

@interface DDGBookmarkActivity ()
@property (nonatomic, strong) NSArray *items;
@end

@implementation DDGBookmarkActivityItem

+ (id)itemWithStory:(DDGStory *)story {
    return [[DDGBookmarkActivityItem alloc] initWithStory:story];
}

+ (id)itemWithTitle:(NSString *)title URL:(NSURL *)URL feed:(NSString *)feed {
    return [[DDGBookmarkActivityItem alloc] initWithTitle:title URL:URL feed:feed];
}

- (id)initWithTitle:(NSString *)title URL:(NSURL *)URL feed:(NSString *)feed {
    self = [super init];
    if (self) {
        self.title = title;
        self.URL = URL;
        self.feed = feed;
    }
    return self;
}

- (id)initWithStory:(DDGStory *)story {
    self = [super init];
    if (self) {
        self.title = story.title;
        self.story = story;
    }
    return self;
}

@end

@implementation DDGBookmarkActivity

- (NSString *)activityType {
    return @"com.duckduckgo.bookmark-activity";
}

- (NSString *)activityTitle {
    switch (self.bookmarkActivityState) {
        case DDGBookmarkActivityStateUnsave:
            return NSLocalizedString(@"Unfavorite", @"Bookmark Activity Title: Unsave");
            break;
            
        case DDGBookmarkActivityStateSave:
        default:
            return NSLocalizedString(@"Favorite", @"Bookmark Activity Title: Save");
            break;
    }
}

- (UIImage *)activityImage {
    switch (self.bookmarkActivityState) {
        case DDGBookmarkActivityStateUnsave:
            return [UIImage imageNamed:@"Unfavorite"];
            break;
            
        case DDGBookmarkActivityStateSave:
        default:
            return [UIImage imageNamed:@"Favorite"];
            break;
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id object in activityItems) {
        if ([object isKindOfClass:[DDGBookmarkActivityItem class]]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[activityItems count]];
    for (id object in activityItems) {
        if ([object isKindOfClass:[DDGBookmarkActivityItem class]]) {
            [items addObject:object];
        }
    }
    self.items = items;
}

- (void)performActivity {
    DDGBookmarksProvider *provider = [DDGBookmarksProvider sharedProvider];
    
    for (DDGBookmarkActivityItem *item in self.items) {
        switch (self.bookmarkActivityState) {
            case DDGBookmarkActivityStateUnsave:
                if (item.story) {
                    item.story.savedValue = NO;
                } else {
                    [provider unbookmarkPageWithURL:item.URL];
                }
                break;
                
            case DDGBookmarkActivityStateSave:
            default:
                if (item.story) {
                    item.story.savedValue = YES;
                } else {
                    [provider bookmarkPageWithTitle:item.title feed:item.feed URL:item.URL];
                }
                break;
        }
        
        if (nil != item.story) {
            NSManagedObjectContext *context = item.story.managedObjectContext;
            [context performBlock:^{
                NSError *error = nil;
                if (![context save:&error])
                    NSLog(@"error: %@", error);
            }];
        }
    }        
    
    NSString *status = (self.bookmarkActivityState == DDGBookmarkActivityStateSave) ? NSLocalizedString(@"Saved", @"Bookmark Activity Confirmation: Saved") : NSLocalizedString(@"Unsaved", @"Bookmark Activity Confirmation: Unsaved");
    [SVProgressHUD showSuccessWithStatus:status];
    
    [self activityDidFinish:YES];
}

@end
