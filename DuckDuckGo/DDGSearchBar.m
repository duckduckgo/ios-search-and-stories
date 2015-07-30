//
//  DDGSearchBar.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 04/04/2013.
//
//

#import "DDGSearchBar.h"

@interface DDGSearchBar ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonXConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftButtonXConstraint;

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


- (void)setShowsCancelButton:(BOOL)show {
    _showsCancelButton = show;
    if(show) {
        self.cancelButtonXConstraint.constant = - (self.cancelButton.frame.size.width + 13);
    } else {
        self.cancelButtonXConstraint.constant = 0;
    }
    [self layoutIfNeeded];

}

- (void)setShowsLeftButton:(BOOL)show {
    _showsLeftButton = show;
    if(show) {
        self.leftButtonXConstraint.constant = self.leftButton.frame.size.width + 10;
    } else {
        self.leftButtonXConstraint.constant = 0;
    }
    [self layoutIfNeeded];
}

- (void)setShowsBangButton:(BOOL)show {
    _showsBangButton = show;
    self.searchField.additionalLeftSideInset = show ? 39 : 0;
    [self setNeedsLayout];
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
