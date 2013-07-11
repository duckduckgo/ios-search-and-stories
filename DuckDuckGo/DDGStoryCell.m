//
//  DDGStoryCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/02/2013.
//
//

#import "DDGStoryCell.h"
#import "DDGFaviconButton.h"

@implementation DDGStoryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView.clipsToBounds = YES;
        UIImageView *overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"topic_cell_background"]];
        overlayImageView.opaque = NO;
        overlayImageView.backgroundColor = [UIColor clearColor];
        overlayImageView.contentMode = UIViewContentModeTop;
        overlayImageView.clipsToBounds = YES;
        [self.contentView addSubview:overlayImageView];
        self.overlayImageView = overlayImageView;
        
        self.contentView.opaque = YES;
        self.contentView.backgroundColor = [UIColor colorWithRed:0.247 green:0.267 blue:0.302 alpha:1.000];
        
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.opaque = NO;
        self.textLabel.numberOfLines = 2;
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
        
        UIButton *faviconButton = [DDGFaviconButton buttonWithType:UIButtonTypeCustom];
        faviconButton.frame = CGRectMake(0, 0, 40.0, 40.0);
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
    return self;
}

- (void)layoutSubviews;
{
    //Always call your parents.
    [super layoutSubviews];
    
    //Let's set everything up.
    CGRect bounds = self.contentView.bounds;
    
    self.imageView.hidden = NO;
    self.imageView.frame = bounds;
    self.imageView.alpha = 1.0;
    [self.contentView sendSubviewToBack:self.imageView];
    
    CGRect faviconFrame = self.faviconButton.frame;    
    
    CGFloat textWidth = bounds.size.width - faviconFrame.size.width - 16.0;
    CGSize textSize = [self.textLabel.text sizeWithFont:self.textLabel.font
                                      constrainedToSize:CGSizeMake(textWidth, MAXFLOAT)
                                          lineBreakMode:self.textLabel.lineBreakMode];
    
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
    
    self.overlayImageView.frame = overlayFrame;    
    
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

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setNeedsLayout];
}

@end
