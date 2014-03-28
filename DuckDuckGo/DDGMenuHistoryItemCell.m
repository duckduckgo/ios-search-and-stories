//
//  DDGMenuHistoryItemCell.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 28/03/2014.
//
//

#import "DDGMenuHistoryItemCell.h"

@interface DDGMenuHistoryItemCell ()

@property (nonatomic, weak) IBOutlet UIImageView *auxiliaryImageView;
@property (nonatomic, weak) IBOutlet UILabel *contentLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentLabelRightConstraint;
@property (nonatomic, weak) IBOutlet UIImageView *faviconImageView;

@end

@implementation DDGMenuHistoryItemCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.tintColor = [UIColor duckRed];
    [self reset];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self reset];
}

- (void)reset
{
    [self.auxiliaryImageView setImage:[UIImage imageNamed:@"Plus"]];
    self.auxiliaryViewHidden = YES;
    [self.faviconImageView setContentMode:UIViewContentModeCenter];
    self.notification = NO;
}

- (void)setAuxiliaryViewHidden:(BOOL)hidden
{
    _auxiliaryViewHidden = hidden;
    [self.auxiliaryImageView setHidden:hidden];
    [self.contentLabelRightConstraint setConstant:hidden ? 15.0f : 39.0f];
    [self setNeedsUpdateConstraints];
}

- (void)setContent:(NSString *)content
{
    _content = [content copy];
    [self.contentLabel setText:content];
}

- (void)setFaviconImage:(UIImage *)faviconImage
{
    _faviconImage = faviconImage;
    [self.faviconImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.faviconImageView setImage:faviconImage];
}

- (void)setNotification:(BOOL)notification
{
    _notification = notification;
    UIImage *image = nil;
    if (notification) {
        image = [[UIImage imageNamed:@"Notification"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else {
        image = [[UIImage imageNamed:@"Search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [self.faviconImageView setImage:image];
}

@end
