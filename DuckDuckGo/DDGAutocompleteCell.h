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

@property (nonatomic, weak, readonly) UIImageView *roundedImageView;
@property (nonatomic, readwrite) BOOL showsSeparatorLine;

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
- (void)setAdorned:(BOOL)adorned;

@end
