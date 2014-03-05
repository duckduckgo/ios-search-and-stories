//
//  DDGStoryCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/02/2013.
//
//

#import "DDGStoryBackgroundView.h"
#import "DDGFaviconButton.h"
#import "DDGStoryCell.h"

NSString *const DDGStoryCellIdentifier = @"StoryCell";

@interface DDGStoryCell ()

@property (nonatomic, strong) DDGFaviconButton *faviconButton;
@property (nonatomic, strong) UIImageView *overlayImageView;
@property (nonatomic, strong) DDGStoryBackgroundView *storyBackgroundView;

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

- (void)setBlurredImage:(UIImage *)blurredImage
{
    [self.storyBackgroundView setBlurredImage:blurredImage];
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
    [self.storyBackgroundView setBackgroundImage:image];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    [self.textLabel setText:title];
}

- (void)setTitleColor:(UIColor *)titleColor
{
    _titleColor = titleColor;
    [self.textLabel setTextColor:titleColor];
}

#pragma mark -

- (void)configure
{
    DDGStoryBackgroundView *storyBackgroundView = [DDGStoryBackgroundView new];
    [self.contentView addSubview:storyBackgroundView];
    self.storyBackgroundView = storyBackgroundView;
    
    UIImageView *overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"topic_cell_background"]];
    overlayImageView.opaque = NO;
    overlayImageView.backgroundColor = [UIColor clearColor];
    overlayImageView.contentMode = UIViewContentModeTop;
    overlayImageView.clipsToBounds = YES;
    [self.contentView addSubview:overlayImageView];
    self.overlayImageView = overlayImageView;
    
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.opaque = NO;
    self.textLabel.numberOfLines = 2;
    self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
    
    DDGFaviconButton *faviconButton = [DDGFaviconButton buttonWithType:UIButtonTypeCustom];
    faviconButton.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
    faviconButton.opaque = NO;
    faviconButton.backgroundColor = [UIColor clearColor];
    [faviconButton addTarget:nil action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:faviconButton];
    self.faviconButton = faviconButton;
    
    CGRect bounds = self.contentView.bounds;
    UIView *gratituousWhiteStripe = [[UIView alloc] initWithFrame:CGRectMake(0, bounds.size.height-1, bounds.size.width, 1.0)];
    gratituousWhiteStripe.backgroundColor = [UIColor whiteColor];
    gratituousWhiteStripe.opaque = YES;
    gratituousWhiteStripe.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:gratituousWhiteStripe];
}

- (void)redraw
{
    [self setNeedsLayout];
    [self.storyBackgroundView setNeedsDisplay];
}

#pragma mark -

- (void)layoutSubviews;
{
    //Always call your parents.
    [super layoutSubviews];
    
    //Let's set everything up.
    CGRect bounds = self.contentView.bounds;
    [self.storyBackgroundView setFrame:bounds];
    
    CGRect faviconFrame = self.faviconButton.frame;    
    
    CGFloat textWidth = bounds.size.width - faviconFrame.size.width - 16.0;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize textSize = CGRectIntegral([self.textLabel.text boundingRectWithSize:CGSizeMake(textWidth, MAXFLOAT)
                                                                       options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                                    attributes:@{NSFontAttributeName: self.textLabel.font,
                                                                                 NSParagraphStyleAttributeName: paragraphStyle}
                                                                          context:nil]).size;
    
    CGRect overlayFrame = self.overlayImageView.frame;
    CGFloat lineHeight = self.textLabel.font.lineHeight + 2.0;
    
    BOOL multiLine = (textSize.height > lineHeight);
    
    if (multiLine) {
        overlayFrame.size.height = self.overlayImageView.image.size.height;
    } else {
        overlayFrame.size.height = MAX(lineHeight, 38.0);
    }
    
    overlayFrame.origin.x = 0;
    overlayFrame.origin.y = bounds.size.height - overlayFrame.size.height;
    overlayFrame.size.width = bounds.size.width;
    
    self.overlayImageView.alpha = 0.6;
    self.overlayImageView.frame = overlayFrame;
    [self.storyBackgroundView setBlurRect:overlayFrame];
    
    //Make sure the favicon is the right size and in the right position.
    faviconFrame.origin.y = overlayFrame.origin.y + ((overlayFrame.size.height - faviconFrame.size.height)/2.0);
    faviconFrame.size = CGSizeMake(40.0, 40.0);
    
    self.faviconButton.frame = CGRectIntegral(faviconFrame);
    
    CGRect textFrame = self.overlayImageView.frame;
    textFrame.origin.y += 1.0;
    textFrame.origin.x += faviconFrame.size.width;
    textFrame.size.width = textWidth;
        
    self.textLabel.frame = textFrame;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.storyBackgroundView reset];
}

@end
