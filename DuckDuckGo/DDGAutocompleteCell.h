//
//  DDGAutocompleteCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 22/05/2013.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class DDGPlusButton;
@interface DDGAutocompleteCell : UITableViewCell
@property (nonatomic, strong, readonly) DDGPlusButton *plusButton;
@property (nonatomic, weak, readonly) UIImageView *roundedImageView;
@property (nonatomic, readwrite) BOOL showsPlusButton;
@end
