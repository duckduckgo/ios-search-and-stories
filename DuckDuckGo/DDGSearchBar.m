//
//  DDGSearchBar.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 04/04/2013.
//
//

#import "DDGSearchBar.h"

@interface DDGSearchBar ()
@end

@implementation DDGSearchBar

- (void)commonInit {
    self.buttonSpacing = 5.0;
    [self setNeedsLayout];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.rightButton setImage:[[UIImage imageNamed:@"Share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                      forState:UIControlStateNormal];
    [self.rightButton setImage:[[UIImage imageNamed:@"Share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                      forState:UIControlStateHighlighted];
}

- (void)setShowsCancelButton:(BOOL)show {
    _showsCancelButton = show;
    [self setNeedsLayout];
}

- (void)setShowsLeftButton:(BOOL)showsLeftButton {
    _showsLeftButton = showsLeftButton;
    [self setNeedsLayout];
}

- (void)setShowsRightButton:(BOOL)showsRightButton {
    _showsRightButton = showsRightButton;
    [self setNeedsLayout];    
}

- (void)setShowsBangButton:(BOOL)show animated:(BOOL)animated {
    
    UIButton *incomming;
    UIButton *outgoing;
    
    if (show) {
        incomming = self.bangButton;
        outgoing = self.orangeButton;
    } else {
        outgoing = self.bangButton;
        incomming = self.orangeButton;
    }
    
    NSTimeInterval duration = (animated) ? 0.2 : 0.0;
    [UIView animateWithDuration:duration
                     animations:^{
                         incomming.alpha = 1.0;
                         outgoing.alpha = 0.0;
                     }
     
     ];
    
    self.leftButton = incomming;
    [self setNeedsLayout];
}

- (void)layoutIfNeeded:(NSTimeInterval)animationDuration {
    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)setShowsCancelButton:(BOOL)show animated:(BOOL)animated {
    self.showsCancelButton = show;
    NSTimeInterval duration = (animated) ? 0.2 : 0.0;
    [self layoutIfNeeded:duration];
}

- (void)setShowsLeftButton:(BOOL)show animated:(BOOL)animated {
    self.showsLeftButton = show;
    NSTimeInterval duration = (animated) ? 0.2 : 0.0;
    [self layoutIfNeeded:duration];
}

- (void)setShowsRightButton:(BOOL)show animated:(BOOL)animated {
    self.showsRightButton = show;
    NSTimeInterval duration = (animated) ? 0.2 : 0.0;
    [self layoutIfNeeded:duration];
}

- (void)layoutSubviews {
    CGRect bounds = self.bounds;
    
    self.leftButton.hidden = !self.showsLeftButton;
//    // left button
//    CGRect leftButtonFrame = self.leftButton.frame;
//    if (self.showsLeftButton)
//        leftButtonFrame.origin.x = self.buttonSpacing;
//    else
//        leftButtonFrame.origin.x = -leftButtonFrame.size.width;
//    
//    self.leftButton.alpha = (self.showsLeftButton) ? 1.0 : 0.0;
//    self.leftButton.frame = leftButtonFrame;
    
//    // right button
//    CGRect rightButtonFrame = self.rightButton.frame;
//    if (self.showsRightButton)
//        rightButtonFrame.origin.x = (bounds.origin.x + bounds.size.width) - rightButtonFrame.size.width - self.buttonSpacing;
//    else
//        rightButtonFrame.origin.x = bounds.origin.x + bounds.size.width;
//    
//    self.rightButton.alpha = (self.showsRightButton) ? 1.0 : 0.0;    
//    self.rightButton.frame = rightButtonFrame;
    self.rightButton.hidden = !self.showsRightButton;

    // cancel button
//    CGRect cancelButtonFrame = self.cancelButton.frame;
    
//    if (self.showsCancelButton)
//        cancelButtonFrame.origin.x = rightButtonFrame.origin.x - cancelButtonFrame.size.width - self.buttonSpacing;
//    else
//        cancelButtonFrame.origin.x = bounds.origin.x + bounds.size.width;
    self.cancelButton.hidden = !self.showsCancelButton;
    
    // search field
    CGFloat rightButtonX = MIN(self.showsCancelButton ? self.cancelButton.frame.origin.x : bounds.size.width,
                               self.showsRightButton ? self.rightButton.frame.origin.x : bounds.size.width);
    CGRect searchFieldFrame = self.searchField.frame;
    //searchFieldFrame.origin.x = leftButtonFrame.origin.x + leftButtonFrame.size.width + self.buttonSpacing;
    searchFieldFrame.size.width = rightButtonX - searchFieldFrame.origin.x - self.buttonSpacing;
    NSLog(@"search field frame: %@", NSStringFromCGRect(searchFieldFrame));
    self.searchField.frame = searchFieldFrame;
}

@end
