//
//  DDGHistoryItemCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/04/2013.
//
//

#import "DDGUnderViewControllerCell.h"
#import "DDGFixedSizeImageView.h"

@interface DDGHistoryItemCell : DDGUnderViewControllerCell
@property (nonatomic, getter = isDeleting) BOOL deleting;
@property (nonatomic, weak, readonly) UIButton *deleteButton;
@property (nonatomic, strong, readonly) DDGFixedSizeImageView *fixedSizeImageView;
- (void)setDeleting:(BOOL)deleting animated:(BOOL)animated;
@end
