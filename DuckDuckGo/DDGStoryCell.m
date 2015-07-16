//
//  DDGStoryCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/02/2013.
//
//

#import "DDGFaviconButton.h"
#import "DDGStoryCell.h"

NSString *const DDGStoryCellIdentifier = @"StoryCell";

CGFloat const DDGTitleBarHeight = 35.0f;

@interface DDGStoryCell ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *contentBackgroundView;
@property (nonatomic, strong) UIView *dropShadowView;
@property (nonatomic, strong) UIView *innerShadowView;
@property (nonatomic, strong) UILabel* textLabel;
@property (nonatomic, strong) DDGFaviconButton *faviconButton;

@end

@implementation DDGStoryCell

#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}

-(NSString*)reuseIdentifier
{
    return DDGStoryCellIdentifier;
}


#pragma mark -

- (void)setDisplaysDropShadow:(BOOL)displaysDropShadow
{
    _displaysDropShadow = displaysDropShadow;
    self.clipsToBounds = !displaysDropShadow;
    [self setNeedsLayout];
}

- (void)setDisplaysInnerShadow:(BOOL)displaysInnerShadow
{
    _displaysInnerShadow = displaysInnerShadow;
    [self setNeedsLayout];
}

- (void)setFavicon:(UIImage *)favicon
{
    _favicon = favicon;
    [self.faviconButton setImage:favicon forState:UIControlStateNormal];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    // Empty stub!
}

- (void)setImage:(UIImage *)image
{
    [self.backgroundImageView setImage:image];
}

- (void)setRead:(BOOL)read
{
    _read = read;
    [self.textLabel setTextColor:(read ? [UIColor duckStoryReadColor] : [UIColor duckBlack])];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // Empty stub!
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    [self.textLabel setText:title];
}

#pragma mark -

- (void)configure
{
    self.displaysDropShadow = NO;
    self.displaysInnerShadow = NO;
    
    UIImageView *backgroundImageView = [UIImageView new];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundImageView.clipsToBounds = YES;
    [self.contentView addSubview:backgroundImageView];
    self.backgroundImageView = backgroundImageView;
    
    UIView *contentBackgroundView = [UIView new];
    contentBackgroundView.backgroundColor = [UIColor duckLightGray];
    [self.contentView addSubview:contentBackgroundView];
    self.contentBackgroundView = contentBackgroundView;
    
    UIView *dropShadowView = [UIView new];
    dropShadowView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    dropShadowView.opaque = NO;
    [self addSubview:dropShadowView];
    self.dropShadowView = dropShadowView;
    
    UIView *innerShadowView = [UIView new];
    innerShadowView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    innerShadowView.opaque = NO;
    [self.contentView addSubview:innerShadowView];
    self.innerShadowView = innerShadowView;
    
    self.textLabel = [UILabel new];
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
    self.textLabel.numberOfLines = 2;
    self.textLabel.opaque = NO;
    [self.contentView addSubview:self.textLabel];
    
    DDGFaviconButton *faviconButton = [DDGFaviconButton buttonWithType:UIButtonTypeCustom];
    faviconButton.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
    faviconButton.opaque = NO;
    faviconButton.backgroundColor = [UIColor clearColor];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [faviconButton addTarget:nil action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
#pragma clang diagnostic pop
    [self.contentView addSubview:faviconButton];
    self.faviconButton = faviconButton;
}

#pragma mark -

- (void)layoutSubviews;
{
    //Always call your parents.
    [super layoutSubviews];
    
    //Let's set everything up.
    CGRect bounds = self.contentView.bounds;
    
    CGRect backgroundImageViewBounds = bounds;
    backgroundImageViewBounds.size.height -= DDGTitleBarHeight;
    [self.backgroundImageView setFrame:backgroundImageViewBounds];
    
    if (self.displaysDropShadow) {
        CGRect dropShadowBounds = bounds;
        dropShadowBounds.origin.y = CGRectGetHeight(bounds);
        dropShadowBounds.size.height = 0.5f;
        [self.dropShadowView setFrame:dropShadowBounds];
    }
    
    if (self.displaysInnerShadow) {
        CGRect innerShadowBounds = bounds;
        innerShadowBounds.size.height = 0.5f;
        [self.innerShadowView setFrame:innerShadowBounds];
    }
    
    CGRect faviconFrame = self.faviconButton.frame;    
    
    CGFloat textWidth = bounds.size.width - faviconFrame.size.width - 16.0;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize textSize = CGRectIntegral([self.textLabel.text boundingRectWithSize:CGSizeMake(textWidth, MAXFLOAT)
                                                                       options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                                    attributes:@{NSFontAttributeName: self.textLabel.font,
                                                                                 NSParagraphStyleAttributeName: paragraphStyle}
                                                                          context:nil]).size;
    
    CGRect contentBackgroundFrame = [self.contentBackgroundView frame];
    CGFloat lineHeight = self.textLabel.font.lineHeight + 2.0;
    
    BOOL multiLine = (textSize.height > lineHeight);
    
    if (multiLine) {
        contentBackgroundFrame.size.height = 51.0f;
    } else {
        contentBackgroundFrame.size.height = MAX(lineHeight, DDGTitleBarHeight);
    }
    
    contentBackgroundFrame.origin.x = 0;
    contentBackgroundFrame.origin.y = bounds.size.height - contentBackgroundFrame.size.height;
    contentBackgroundFrame.size.width = bounds.size.width;
    
    [self.contentBackgroundView setFrame:contentBackgroundFrame];
    
    CGPoint center = [self.faviconButton center];
    center.y = CGRectGetMidY(contentBackgroundFrame);
    [self.faviconButton setCenter:center];
    
    CGRect textFrame = [self.contentBackgroundView frame];
    textFrame.origin.y += 1.0;
    textFrame.origin.x += faviconFrame.size.width;
    textFrame.size.width = textWidth;
        
    self.textLabel.frame = textFrame;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.backgroundImageView setImage:nil];
    self.displaysDropShadow = NO;
    self.displaysInnerShadow = NO;
}

@end
