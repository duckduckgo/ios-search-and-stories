//
//  DDGMenuItemCell.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 27/03/2014.
//
//

#import "DDGMenuItemCell.h"

@interface DDGMenuItemCell ()

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation DDGMenuItemCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = [UIColor duckRed];
    self.selectedBackgroundView = selectedBackgroundView;
    self.tintColor = [UIColor duckRed];
    [self.titleLabel setTextColor:[UIColor duckBlack]];
}

- (void)setIcon:(UIImage *)icon
{
    _icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.iconImageView setImage:_icon];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    self.tintColor = highlighted ? [UIColor whiteColor] : [UIColor duckRed];
    [self.titleLabel setTextColor:highlighted ? [UIColor whiteColor] : [UIColor duckBlack]];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    [self.titleLabel setText:_title];
}

@end
