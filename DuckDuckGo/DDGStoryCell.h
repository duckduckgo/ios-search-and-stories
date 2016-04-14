//
//  DDGStoryCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/02/2013.
//
//

#import <UIKit/UIKit.h>
#import "DDGStory.h"
#import "DDGPopoverViewController.h"

extern NSString *const DDGStoryCellIdentifier;

#define DDGTitleBarHeight 57.0f
#define DDGTitleBarHeightMosaicLarge 118.0f;

@protocol DDGStoryCellDelegate <NSObject>

@property (readonly) NSUInteger storiesListMode;

-(void)shareStory:(DDGStory*)story fromView:(UIView*)sourceView;
-(void)toggleStorySaved:(DDGStory*)story;
-(void)openStoryInBrowser:(DDGStory*)story;
-(void)removeHistoryItem:(DDGHistoryItem*)historyItem;
-(void)toggleCategoryPressed:(NSString*)categoryName onStory:(DDGStory*)story;

@end


@interface DDGStoryCell : UICollectionViewCell <DDGPopoverViewControllerDelegate>

@property (nonatomic) BOOL isShowingMenu;
@property (nonatomic) BOOL shouldGoToDetail;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) DDGStory* story;
@property (nonatomic) BOOL mosaicMode;
@property (nonatomic, strong) DDGHistoryItem* historyItem;
@property (nonatomic, weak) id<DDGStoryCellDelegate> storyDelegate;
@property (nonatomic, strong) UIView* touchPassthroughView;

-(void)saveStoryAndClose;
-(void)share;
-(void)openInBrowser;
-(void)removeHistoryItem;

@end
