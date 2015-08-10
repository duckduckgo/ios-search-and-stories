//
//  DDGStoryCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/02/2013.
//
//

#import <UIKit/UIKit.h>
#import "DDGStory.h"

extern NSString *const DDGStoryCellIdentifier;

@protocol DDGStoryCellDelegate <NSObject>

-(void)shareStory:(DDGStory*)story;
-(void)toggleStorySaved:(DDGStory*)story;
-(void)openStoryInBrowser:(DDGStory*)story;
-(void)toggleCategoryPressed:(NSString*)categoryName onStory:(DDGStory*)story;

@end


@interface DDGStoryCell : UICollectionViewCell

@property (nonatomic, assign) BOOL displaysDropShadow;
@property (nonatomic, assign) BOOL displaysInnerShadow;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) DDGStory* story;
@property (nonatomic, weak) id<DDGStoryCellDelegate> storyDelegate;

-(void)toggleSavedState;
-(void)share;
-(void)openInBrowser;

@end
