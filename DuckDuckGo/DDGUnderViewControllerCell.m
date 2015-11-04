//
//  DDGUnderViewControllerCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 08/03/2013.
//
//

#import "DDGUnderViewControllerCell.h"
#import "DDGDeleteButton.h"

@interface DDGUnderViewControllerCell ()
@property (nonatomic, weak, readwrite) DDGFixedSizeImageView *fixedSizeImageView;
@property (nonatomic, weak, readwrite) UIImageView *backgroundImageView;
@property (nonatomic, weak, readwrite) UIImageView *selectedBackgroundImageView;
@end

@implementation DDGUnderViewControllerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        DDGFixedSizeImageView *fixedSizeImageView = [[DDGFixedSizeImageView alloc] initWithFrame:CGRectZero];
        fixedSizeImageView.layer.cornerRadius = 2.0;
        fixedSizeImageView.size = CGSizeMake(24.0, 24.0);
        [self addSubview:fixedSizeImageView];
        self.fixedSizeImageView = fixedSizeImageView;        
        
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.opaque = NO;
        
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];;
        backgroundImageView.contentMode = UIViewContentModeScaleToFill;
        backgroundImageView.opaque = NO;
        backgroundImageView.backgroundColor = [UIColor clearColor];
        self.backgroundView = backgroundImageView;
        self.backgroundImageView = backgroundImageView;

        UIImageView *selectedBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];;
        selectedBackgroundView.contentMode = UIViewContentModeScaleToFill;
        selectedBackgroundView.opaque = NO;
        selectedBackgroundView.backgroundColor = [UIColor clearColor];
        self.selectedBackgroundView = selectedBackgroundView;
        self.selectedBackgroundImageView = selectedBackgroundView;
        
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
                
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_caret"]];
        imageView.highlightedImage = [UIImage imageNamed:@"icon_caret_onclick"];
        imageView.contentMode = UIViewContentModeCenter;
        self.accessoryView = imageView;
        
        backgroundImageView.image = [UIImage imageNamed:@"new_bg_menu-items"];
		selectedBackgroundView.image = [UIImage imageNamed:@"new_bg_menu-items-highlighted"];
        
		self.textLabel.numberOfLines = 1;
		self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
        self.textLabel.textColor = [UIColor slideOutMenuTextColor];
        self.textLabel.highlightedTextColor = [UIColor whiteColor];        
    }
    return self;
}

- (UIImageView *)imageView {
    return nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    BOOL highlight = (selected || self.isActive || self.highlighted);
    
    [super setSelected:selected animated:animated];

    UIImageView *imageView = (UIImageView *)self.accessoryView;
    if ([imageView isKindOfClass:[UIImageView class]]) {
        [imageView setHighlighted:highlight];
    }
    
    [self.textLabel setHighlighted:highlight];
    [self.fixedSizeImageView setHighlighted:highlight];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    BOOL highlight = (highlighted || self.isActive || self.selected);
    
    UIImageView *imageView = (UIImageView *)self.accessoryView;
    if ([imageView isKindOfClass:[UIImageView class]]) {
        [imageView setHighlighted:highlight];
    }
    
    [self.textLabel setHighlighted:highlight];
    [self.fixedSizeImageView setHighlighted:highlight];
}

- (void)setActive:(BOOL)active {
    
    _active = active;
    
    UIImageView *imageView = (UIImageView *)self.accessoryView;
    if ([imageView isKindOfClass:[UIImageView class]]) {
        [imageView setHighlighted:active];
    }
    
    [self.textLabel setHighlighted:active];
    [self.fixedSizeImageView setHighlighted:active];
    
    [self setNeedsDisplay];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setActive:NO];
    self.fixedSizeImageView.size = CGSizeMake(24.0, 24.0);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self setNeedsLayout];
}

- (void)setEditing:(BOOL)editing {
    [super setEditing:editing];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    
    CGFloat overhang = self.overhangWidth;
    CGRect bounds = self.bounds;
    
    self.backgroundView.frame = bounds;
    self.selectedBackgroundView.frame = bounds;
    
    if (nil != self.accessoryView)
        [self addSubview:self.accessoryView];
    
    CGRect accessoryRect = self.accessoryView.frame;
    accessoryRect.origin.x = bounds.size.width - overhang - 2.0 - accessoryRect.size.width;
    accessoryRect.origin.y = floor((bounds.size.height - accessoryRect.size.height) / 2.0);
    self.accessoryView.frame = accessoryRect;
    
    CGRect editingRect = self.editingAccessoryView.frame;
    editingRect.origin.x = bounds.size.width - overhang - editingRect.size.width;
    editingRect.origin.y = floor((bounds.size.height - editingRect.size.height) / 2.0);
    self.editingAccessoryView.frame = editingRect;
    
    self.contentView.frame = CGRectMake(0, 0, bounds.size.width - overhang - accessoryRect.size.width, bounds.size.height);
    CGRect contentBounds = self.contentView.bounds;
    
    CGRect imageRect = CGRectMake(0, 0, 36, contentBounds.size.height);
    if (self.fixedSizeImageView.image) {
        CGSize size = CGSizeMake(24.0, 24.0);
        imageRect = CGRectMake(imageRect.origin.x + ((imageRect.size.width - size.width) / 2.0),
                               imageRect.origin.y + ((imageRect.size.height - size.height) / 2.0),
                               size.width,
                               size.height);
    }
    self.fixedSizeImageView.frame = CGRectIntegral(imageRect);
    
    CGRect labelRect = CGRectMake(38, 0, contentBounds.size.width - 38, bounds.size.height);
    self.textLabel.frame = labelRect;
}

@end
