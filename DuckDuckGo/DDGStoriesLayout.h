//
//  DDGStoriesLayout.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//  Extended by Josiah Clumont from 21/04/16.
//
//

#import <UIKit/UIKit.h>
#import "DDGStoriesViewController.h"

extern NSString* const DDGStoriesLayoutKind;
extern NSString* const DDGOnboardingBannerViewKindID;

@interface DDGStoriesLayout : UICollectionViewLayout

@property (nonatomic, weak) DDGStoriesViewController* storiesController;
@property BOOL mosaicMode;
@property (nonatomic, strong) NSDictionary *layoutInfo;
@property NSUInteger bannerHeight;

- (CGRect)frameForStoryAtIndexPath:(NSIndexPath *)indexPath;

@end
