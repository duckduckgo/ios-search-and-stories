//
//  DDGHistoryItemCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/04/2013.
//
//

#import "DDGFixedSizeImageView.h"
#import "DDGUnderViewControllerCell.h"

@interface DDGHistoryItemCell : UITableViewCell
@property (nonatomic, strong, readonly) DDGFixedSizeImageView *fixedSizeImageView;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
@end
