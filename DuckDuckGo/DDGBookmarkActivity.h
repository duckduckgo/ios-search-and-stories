//
//  DDGBookmarkActivity.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/03/2013.
//
//

#import <UIKit/UIKit.h>

typedef enum DDGBookmarkActivityState {
    DDGBookmarkActivityStateSave = 0,
    DDGBookmarkActivityStateUnsave
} DDGBookmarkActivityState;

@class DDGStory;
@interface DDGBookmarkActivityItem : NSObject
@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *feed;
@property (nonatomic, strong, readonly) DDGStory *story;
+ (id)itemWithStory:(DDGStory *)story;
+ (id)itemWithTitle:(NSString *)title URL:(NSURL *)URL feed:(NSString *)feed;

- (id)initWithStory:(DDGStory *)story;
- (id)initWithTitle:(NSString *)title URL:(NSURL *)URL feed:(NSString *)feed;
@end

@interface DDGBookmarkActivity : UIActivity
@property (nonatomic) DDGBookmarkActivityState bookmarkActivityState;
@end
