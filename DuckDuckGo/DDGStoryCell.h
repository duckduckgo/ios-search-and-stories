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

@class DDGStoriesViewController;

@interface DDGStoryCell : UICollectionViewCell

@property (nonatomic, assign) BOOL displaysDropShadow;
@property (nonatomic, assign) BOOL displaysInnerShadow;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) DDGStory* story;
@property (nonatomic, weak) DDGStoriesViewController* storiesController;

-(void)toggleSavedState;
-(void)share;
-(void)openInBrowser;

@end
