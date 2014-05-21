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
@property (nonatomic, weak) IBOutlet UIView *buttonContainerView;
@property (nonatomic, weak) IBOutlet UILabel *contentLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentContainerWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentLabelRightConstraint;
@property (nonatomic, weak) IBOutlet UIImageView *faviconImageView;

@end

@implementation DDGMenuHistoryItemCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDeleteButtonTap:)];
    [self.buttonContainerView addGestureRecognizer:tapGestureRecognizer];
    [self.buttonContainerView setHidden:YES];
    self.opaque = NO;
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = [UIColor duckRed];
    self.selectedBackgroundView = selectedBackgroundView;
    self.tintColor = [UIColor duckRed];
    [self reset];
}

- (void)handleDeleteButtonTap:(UITapGestureRecognizer *)recognizer
{
    if (self.deleteBlock) {
        self.deleteBlock(self);
    }
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
    [self setDeletable:NO animated:NO];
}

- (void)setAuxiliaryViewHidden:(BOOL)hidden
{
    _auxiliaryViewHidden = hidden;
    [self.auxiliaryImageView setHidden:hidden];
    [self.contentLabelRightConstraint setConstant:hidden ? 15.0f : 39.0f];
    [self layoutIfNeeded];
}

- (void)setContent:(NSString *)content
{
    _content = [content copy];
    [self.contentLabel setText:content];
}

- (void)setDeletable:(BOOL)deletable animated:(BOOL)animated
{
    [self.contentView layoutIfNeeded];    
    if (animated) {
        if (deletable) {
            [self.buttonContainerView setHidden:NO];
        }
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             if (!self.auxiliaryViewHidden) {
                                 [self.auxiliaryImageView setAlpha:deletable ? 0.0f : 1.0f];
                             }
                             CGFloat width = CGRectGetWidth(self.bounds);
                             [self.contentContainerWidthConstraint setConstant:deletable ? (width - 74.0f) : width];
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             if (!deletable) {
                                 [self.buttonContainerView setHidden:YES];
                             }
                         }];
    } else {
        [self.buttonContainerView setHidden:!deletable];
        [self.contentContainerWidthConstraint setConstant:deletable ? 246.0f : CGRectGetWidth(self.bounds)];
        [self layoutIfNeeded];
    }
}

- (void)setFaviconImage:(UIImage *)faviconImage
{
    _faviconImage = faviconImage;
    [self.faviconImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.faviconImageView setImage:faviconImage];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    self.tintColor = highlighted ? [UIColor whiteColor] : [UIColor duckRed];
    [self.contentLabel setTextColor:highlighted ? [UIColor whiteColor] : [UIColor duckBlack]];
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

- (BOOL)shouldCauseMenuPanGestureToFail
{
    return YES;
}

@end
