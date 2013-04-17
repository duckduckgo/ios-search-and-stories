//
//  DDGHistoryItemCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/04/2013.
//
//

#import "DDGUnderViewControllerCell.h"
#import "DDGFixedSizeImageView.h"

typedef enum DDGHistoryItemCellMode {
    DDGHistoryItemCellModeNormal = 0,
    DDGHistoryItemCellModeUnder
} DDGHistoryItemCellMode;

@interface DDGHistoryItemCell : DDGUnderViewControllerCell
@property (nonatomic, getter = isDeleting) BOOL deleting;
@property (nonatomic, weak, readonly) UIButton *deleteButton;
@property (nonatomic, strong, readonly) DDGFixedSizeImageView *fixedSizeImageView;
- (void)setDeleting:(BOOL)deleting animated:(BOOL)animated;
- (id)initWithCellMode:(DDGHistoryItemCellMode)mode reuseIdentifier:(NSString *)reuseIdentifier;
@end
