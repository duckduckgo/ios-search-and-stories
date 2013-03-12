//
//  DDGUnderViewControllerCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 08/03/2013.
//
//

#import "DDGUnderViewControllerCell.h"

@implementation DDGUnderViewControllerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.imageView.layer.cornerRadius = 2.0;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.opaque = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    UIImageView *imageView = (UIImageView *)self.accessoryView;
    if ([imageView isKindOfClass:[UIImageView class]]) {
        [imageView setHighlighted:selected];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    UIImageView *imageView = (UIImageView *)self.accessoryView;
    if ([imageView isKindOfClass:[UIImageView class]]) {
        [imageView setHighlighted:highlighted];
    }
}

- (void)setCellMode:(DDGUnderViewControllerCellMode)cellMode {
    
    _cellMode = cellMode;
    
    if (cellMode == DDGUnderViewControllerCellModeRecent) {
        
        self.accessoryView = nil;
        
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"new_bg_history-items"]];
		self.textLabel.numberOfLines = 2;
		self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
        self.textLabel.textColor = [UIColor colorWithRed:0.490 green:0.522 blue:0.576 alpha:1.000];
        self.textLabel.highlightedTextColor = [UIColor whiteColor];
    } else {
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_caret"]];
        imageView.highlightedImage = [UIImage imageNamed:@"icon_caret_onclick"];
        imageView.contentMode = UIViewContentModeLeft;
        self.accessoryView = imageView;
        
		self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"new_bg_menu-items"]];
		self.textLabel.numberOfLines = 1;
		self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
        self.textLabel.textColor = [UIColor colorWithRed:0.686 green:0.725 blue:0.800 alpha:1.000];
        self.textLabel.highlightedTextColor = [UIColor whiteColor];
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];    
    
    CGRect bounds = self.contentView.bounds;
    
    CGRect imageRect = CGRectMake(0, 0, 36, bounds.size.height);
    if (self.imageView.image) {
        CGSize size = (self.cellMode == DDGUnderViewControllerCellModeRecent) ? CGSizeMake(16.0, 16.0) : CGSizeMake(24.0, 24.0);
        imageRect = CGRectMake(imageRect.origin.x + ((imageRect.size.width - size.width) / 2.0),
                               imageRect.origin.y + ((imageRect.size.height - size.height) / 2.0),
                               size.width,
                               size.height);
    }
    self.imageView.frame = CGRectIntegral(imageRect);
    
    CGRect labelRect = CGRectMake(38, 0, 195, bounds.size.height);
    self.textLabel.frame = labelRect;
    
    CGRect accessoryRect = CGRectMake(233, 0, bounds.size.width - 223, bounds.size.height);
    self.accessoryView.frame = accessoryRect;
}

@end
