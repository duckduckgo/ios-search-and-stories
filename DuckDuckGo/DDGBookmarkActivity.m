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

@interface DDGBookmarkActivityItem ()
@property (nonatomic, copy, readwrite) NSURL *URL;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *feed;
@end

@interface DDGBookmarkActivity ()
@property (nonatomic, strong) NSArray *items;
@end

@implementation DDGBookmarkActivityItem

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

@end

@implementation DDGBookmarkActivity

- (NSString *)activityType {
    return @"com.duckduckgo.bookmark-activity";
}

- (NSString *)activityTitle {
    switch (self.bookmarkActivityState) {
        case DDGBookmarkActivityStateUnsave:
            return NSLocalizedString(@"Unsave", @"Bookmark Activity Title: Unsave");
            break;
            
        case DDGBookmarkActivityStateSave:
        default:
            return NSLocalizedString(@"Save", @"Bookmark Activity Title: Save");
            break;
    }
}

- (UIImage *)activityImage {
    switch (self.bookmarkActivityState) {
        case DDGBookmarkActivityStateUnsave:
            return [UIImage imageNamed:@"swipe-un-save"];
            break;
            
        case DDGBookmarkActivityStateSave:
        default:
            return [UIImage imageNamed:@"swipe-save"];
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
                [provider unbookmarkPageWithURL:item.URL];
                break;
                
            case DDGBookmarkActivityStateSave:
            default:
                [provider bookmarkPageWithTitle:item.title feed:item.feed URL:item.URL];
                break;
        }
    }        
    
    NSString *status = (self.bookmarkActivityState == DDGBookmarkActivityStateSave) ? NSLocalizedString(@"Saved", @"Bookmark Activity Confirmation: Saved") : NSLocalizedString(@"Unsaved", @"Bookmark Activity Confirmation: Unsaved");
    [SVProgressHUD showSuccessWithStatus:status];
    
    [self activityDidFinish:YES];
}

@end
