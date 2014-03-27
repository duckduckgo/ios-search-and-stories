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
    self.tintColor = [UIColor duckRed];
    [self.titleLabel setTextColor:[UIColor duckBlack]];
}

- (void)setIcon:(UIImage *)icon
{
    _icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.iconImageView setImage:_icon];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    [self.titleLabel setText:_title];
}

@end
