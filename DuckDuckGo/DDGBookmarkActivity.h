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

@interface DDGBookmarkActivityItem : NSObject
@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *feed;
+ (id)itemWithTitle:(NSString *)title URL:(NSURL *)URL feed:(NSString *)feed;
- (id)initWithTitle:(NSString *)title URL:(NSURL *)URL feed:(NSString *)feed;
@end

@interface DDGBookmarkActivity : UIActivity
@property (nonatomic) DDGBookmarkActivityState bookmarkActivityState;
@end
