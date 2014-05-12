//
//  DDGAutocompleteCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 22/05/2013.
//
//

#import "DDGAutocompleteCell.h"
//#import "DDGPlusButton.h"

@interface DDGAutocompleteCell ()

//@property (nonatomic, strong, readwrite) DDGPlusButton *plusButton;
@property (nonatomic, strong) UIButton *button;
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


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.textLabel.numberOfLines = 1;
        self.tintColor = [UIColor autocompleteHeaderColor];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
        
        self.detailTextLabel.numberOfLines = 2;
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 53, 53)];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.clipsToBounds = YES;
        iv.backgroundColor = [UIColor whiteColor];
        
        CALayer *layer = iv.layer;
        layer.cornerRadius = 4.0;
        
        [self.contentView insertSubview:iv aboveSubview:self.imageView];
        self.roundedImageView = iv;
        
        // self contained separator lines
        CGRect frame = self.contentView.bounds;
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-1.0, frame.size.width, 1.0)];
        separatorLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        separatorLine.clipsToBounds = YES;
        separatorLine.backgroundColor = [UIColor autocompleteHeaderColor];
        [self addSubview:separatorLine];
        self.separatorLine = separatorLine;
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
        [button setImage:[UIImage imageNamed:@"Plus"] forState:UIControlStateNormal];
        self.button = button;
    }
    return self;
}

- (BOOL)showsSeparatorLine
{
    return (!self.separatorLine.isHidden);
}

- (void)setShowsSeparatorLine:(BOOL)showsSeparatorLine
{
    self.separatorLine.hidden = (!showsSeparatorLine);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.roundedImageView.hidden = (nil == self.roundedImageView.image);
    CGSize size = self.roundedImageView.image.size;
    CGSize fitSize = AspectFitSizeInSize(size, CGSizeMake(53, 53), NO);
    self.roundedImageView.bounds = CGRectMake(0, 0, fitSize.width, fitSize.height);
    self.roundedImageView.center = self.imageView.center;
    
    CGRect bounds = self.bounds;
    CGRect accessoryRect = self.accessoryView.frame;
    CGRect contentRect = self.contentView.frame;
    CGRect textRect = self.textLabel.frame;
    CGRect detailRect = self.detailTextLabel.frame;
    
    CGPoint center = CGPointMake(CGRectGetMaxX(bounds) - (CGRectGetWidth(accessoryRect) * 0.5f), CGRectGetMidY(bounds));
    [self.accessoryView setCenter:center];
    
    self.contentView.frame = CGRectMake(contentRect.origin.x,
                                        contentRect.origin.y,
                                        bounds.size.width - contentRect.origin.x - accessoryRect.size.width - 6.0,
                                        contentRect.size.height);

    self.textLabel.frame = CGRectMake(textRect.origin.x,
                                      textRect.origin.y,
                                      contentRect.size.width - textRect.origin.x,
                                      textRect.size.height);
    
    self.detailTextLabel.frame = CGRectMake(detailRect.origin.x,
                                            detailRect.origin.y,
                                            contentRect.size.width - detailRect.origin.x,
                                            detailRect.size.height);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    self.accessoryView = nil;
    [self setAdorned:NO];
    [self.imageView setImage:nil];
    [self.roundedImageView setImage:nil];
}

- (void)setAdorned:(BOOL)adorned
{
    [self.textLabel setFont:adorned ? [UIFont boldSystemFontOfSize:17.0f] : [UIFont systemFontOfSize:17.0f]];
    [self.textLabel setTextColor:adorned ? [UIColor autocompleteTitleColor] : [UIColor autocompleteTextColor]];
    [self.detailTextLabel setFont:adorned ? [UIFont systemFontOfSize:15.0f] : [UIFont systemFontOfSize:15.0f]];
    [self.detailTextLabel setTextColor:adorned ? [UIColor autocompleteDetailColor] : [UIColor autocompleteTextColor]];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    [self.button addTarget:target action:action forControlEvents:controlEvents];
    self.accessoryView = self.button;
}

@end
