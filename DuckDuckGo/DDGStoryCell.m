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
@property (nonatomic, strong) DDGFaviconButton *faviconButton;

@end

@implementation DDGStoryCell

#pragma mark -

- (instancetype)init
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DDGStoryCellIdentifier];
    if (self) {
        [self configure];
    }
    return self;
}

#pragma mark -

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
    dropShadowView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
    dropShadowView.opaque = NO;
    [self.contentView addSubview:dropShadowView];
    self.dropShadowView = dropShadowView;
    
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
    self.textLabel.numberOfLines = 2;
    self.textLabel.opaque = NO;
    
    DDGFaviconButton *faviconButton = [DDGFaviconButton buttonWithType:UIButtonTypeCustom];
    faviconButton.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
    faviconButton.opaque = NO;
    faviconButton.backgroundColor = [UIColor clearColor];
    [faviconButton addTarget:nil action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
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
    CGRect dropShadowBounds = bounds;
    dropShadowBounds.size.height = 1.0f;
    [self.dropShadowView setFrame:dropShadowBounds];
    
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
}

@end
