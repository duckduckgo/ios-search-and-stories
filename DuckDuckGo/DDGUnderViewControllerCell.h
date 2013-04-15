//
//  DDGUnderViewControllerCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 08/03/2013.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "DDGFixedSizeImageView.h"

@interface DDGUnderViewControllerCell : UITableViewCell
@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic) CGFloat overhangWidth;
@property (nonatomic, weak, readonly) DDGFixedSizeImageView *fixedSizeImageView;
@property (nonatomic, weak, readonly) UIImageView *backgroundImageView;
@property (nonatomic, weak, readonly) UIImageView *selectedBackgroundImageView;
@end
