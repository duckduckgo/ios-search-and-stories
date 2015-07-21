//
//  DDGSearchBar.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 04/04/2013.
//
//

#import "DDGSearchBar.h"

@interface DDGSearchBar ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addressFieldLeftAlignToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addressFieldLeftAlignToLeftButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addressFieldRightAlignToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addressFieldRightAlignToCancelButton;

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
    self.addressFieldRightAlignToCancelButton = [NSLayoutConstraint constraintWithItem:self.searchField
                                                                             attribute:NSLayoutAttributeTrailing
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.cancelButton
                                                                             attribute:NSLayoutAttributeLeading
                                                                            multiplier:1 constant:-13];
    self.addressFieldLeftAlignToLeftButton = [NSLayoutConstraint constraintWithItem:self.searchField
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.leftButton
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1 constant:8];
}




- (void)setShowsCancelButton:(BOOL)show {
    _showsCancelButton = show;
    if(show) {
        [self removeConstraint:self.addressFieldRightAlignToSuperview];
        [self addConstraint:self.addressFieldRightAlignToCancelButton];
    } else {
        [self removeConstraint:self.addressFieldRightAlignToCancelButton];
        [self addConstraint:self.addressFieldRightAlignToSuperview];
    }
}

- (void)setShowsLeftButton:(BOOL)show {
    _showsLeftButton = show;
    if(show) {
        [self removeConstraint:self.addressFieldLeftAlignToSuperview];
        [self addConstraint:self.addressFieldLeftAlignToLeftButton];
    } else {
        [self removeConstraint:self.addressFieldLeftAlignToLeftButton];
        [self addConstraint:self.addressFieldLeftAlignToSuperview];
    }
}

- (void)setShowsBangButton:(BOOL)show {
    _showsBangButton = show;
    self.searchField.additionalLeftSideInset = show ? 39 : 0;
}

- (void)setShowsBangButton:(BOOL)show animated:(BOOL)animated {
    self.showsBangButton = show;
    NSTimeInterval duration = (animated) ? 0.2 : 0.0;
    [self layoutIfNeeded:duration];
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

- (void)layoutSubviews {
    self.leftButton.hidden = !self.showsLeftButton;
    self.bangButton.hidden = !self.showsBangButton;
    self.cancelButton.hidden = !self.showsCancelButton;

    [self setNeedsDisplay];
    [self setNeedsUpdateConstraints];
}



#pragma mark - Showing and hiding progress

-(void)cancel {
    self.progressView.percentCompleted = 100;
}

-(void)finish {
    self.progressView.percentCompleted = 100;
}

#pragma mark - Progress bar

-(void)setProgress:(CGFloat)newProgress {
    self.progressView.percentCompleted = ceill(newProgress*100);
    
}

-(void)setProgress:(CGFloat)newProgress animationDuration:(CGFloat)duration {
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self setProgress:newProgress];
                     }
                     completion:^(BOOL finished) {
                         if(finished)
                             [self setProgress:newProgress+0.1
                             animationDuration:duration*4];
                     }];
}


@end
