//
//  DDGAutocompleteCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 22/05/2013.
//
//

#import "DDGAutocompleteCell.h"
#import "DDGPlusButton.h"

@interface DDGAutocompleteCell ()
@property (nonatomic, strong, readwrite) DDGPlusButton *plusButton;
@property (nonatomic, weak, readwrite) UIImageView *roundedImageView;
@property (nonatomic, weak, readwrite) UIView *separatorLine;
@end

@implementation DDGAutocompleteCell

CGSize AspectFitSizeInSize(CGSize containedSize, CGSize container, BOOL canUpscale);
CGSize AspectFitSizeInSize(CGSize containedSize, CGSize container, BOOL canUpscale) {
    
    CGSize newSize = CGSizeZero;
    if (CGSizeEqualToSize(containedSize, newSize)) {
        return newSize;
    }
    
    CGFloat containerAspect = container.width / container.height;
    CGFloat containedAspect = containedSize.width / containedSize.height;
    
    if (!canUpscale && (containedSize.width < container.width && containedSize.height < container.height)) {
        return CGSizeMake(containedSize.width, containedSize.height);
    }
    
    if (containerAspect == containedAspect) {
        return container;
    }
    
    if (containerAspect < containedAspect) {
        newSize.width = container.width;
        newSize.height = floorf((containedSize.height * container.width) / containedSize.width);
    } else {
        newSize.width = floorf((containedSize.width * container.height) / containedSize.height);
        newSize.height = container.height;
    }
    
    return newSize;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
        self.textLabel.textColor = [UIColor colorWithRed:0.353 green:0.373 blue:0.400 alpha:1.000];
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.textLabel.numberOfLines = 1;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
        
        self.detailTextLabel.numberOfLines = 2;
        self.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
        self.detailTextLabel.textColor = [UIColor colorWithRed:0.549 green:0.565 blue:0.580 alpha:1.000];        
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 53, 53)];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.clipsToBounds = YES;
        iv.backgroundColor = [UIColor whiteColor];
        
        CALayer *layer = iv.layer;
        layer.borderWidth = 0.5;
        layer.borderColor = [UIColor colorWithRed:0.812 green:0.820 blue:0.835 alpha:1.000].CGColor;
        layer.cornerRadius = 4.0;
        
        [self.contentView insertSubview:iv aboveSubview:self.imageView];
        self.roundedImageView = iv;
        
        // self contained separator lines
        CGRect frame = self.contentView.bounds;
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-1.0, frame.size.width, 1.0)];
        separatorLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        separatorLine.clipsToBounds = YES;
        separatorLine.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:separatorLine];
        self.separatorLine = separatorLine;
        
    }
    return self;
}

- (BOOL)showsSeparatorLine {
    return (!self.separatorLine.isHidden);
}

- (void)setShowsSeparatorLine:(BOOL)showsSeparatorLine {
    self.separatorLine.hidden = (!showsSeparatorLine);
}

- (void)setShowsPlusButton:(BOOL)showsPlusButton {
    if (showsPlusButton == _showsPlusButton)
        return;
    
    if (showsPlusButton) {
        if (nil == self.plusButton)
            self.plusButton = [DDGPlusButton lightPlusButton];
        [self.contentView addSubview:self.plusButton];
        self.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24.0, self.contentView.bounds.size.height)];
    } else {
        [self.plusButton removeFromSuperview];
        self.accessoryView = nil;
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.roundedImageView.hidden = (nil == self.roundedImageView.image);
    CGSize size = self.roundedImageView.image.size;
    CGSize fitSize = AspectFitSizeInSize(size, CGSizeMake(53, 53), NO);
    self.roundedImageView.bounds = CGRectMake(0, 0, fitSize.width, fitSize.height);
    self.roundedImageView.center = self.imageView.center;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    self.showsPlusButton = NO;
}

@end
