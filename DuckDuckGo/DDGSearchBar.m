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

-(void)viewDidLoad
{
    NSLog(@"viewDidLoad: loading manual constraints");
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

- (void)awakeFromNib
{
    [super awakeFromNib];
    NSLog(@"awakeFromNib: loading manual constraints");

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
    
//    [self addConstraint:self.addressFieldRightAlignToSuperview];
//    [self addConstraint:self.addressFieldLeftAlignToSuperview];
    //[self addConstraint:self.addressFieldRightAlignToCancelButton];
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

- (void)setShowsRightButton:(BOOL)showsRightButton {
    _showsRightButton = showsRightButton;
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

- (void)setShowsRightButton:(BOOL)show animated:(BOOL)animated {
    self.showsRightButton = show;
    NSTimeInterval duration = (animated) ? 0.2 : 0.0;
    [self layoutIfNeeded:duration];
}

- (void)layoutSubviews {
    //CGRect bounds = self.frame;
    self.leftButton.hidden = !self.showsLeftButton;
    self.bangButton.hidden = !self.showsBangButton;
    self.rightButton.hidden = !self.showsRightButton;
    self.cancelButton.hidden = !self.showsCancelButton;
//
//    CGRect addressFrame = self.searchField.frame;
//    addressFrame.origin.x = self.showsLeftButton ? 38 : 8;
//    addressFrame.size.width = bounds.size.width - addressFrame.origin.x -
//    (self.showsCancelButton ? self.cancelButton.frame.size.width : 0 ) - 8;
//    self.searchField.frame = addressFrame;
//    
//    CGRect bangFrame = self.bangButton.frame;
//    bangFrame.origin.x = addressFrame.origin.x + 8;
//    self.bangButton.frame = bangFrame;
//    
//    CGRect cancelFrame = self.cancelButton.frame;
//    cancelFrame.origin.x = bounds.size.width - cancelFrame.size.width - 8;
//    self.cancelButton.frame = cancelFrame;
//    
//    NSLog(@"laid out views: %@", NSStringFromCGRect(bounds));
//    NSLog(@"  cancel frame: %@", NSStringFromCGRect(cancelFrame));
//    NSLog(@"  address frame: %@", NSStringFromCGRect(addressFrame));
    
    [self setNeedsDisplay];
    [self setNeedsUpdateConstraints];
    
    // search field
//    CGFloat rightButtonX = MIN(self.showsCancelButton ? self.cancelButton.frame.origin.x : bounds.size.width,
//                               self.showsRightButton ? self.rightButton.frame.origin.x : bounds.size.width);
//    CGRect searchFieldFrame = self.searchField.frame;
//    //searchFieldFrame.origin.x = leftButtonFrame.origin.x + leftButtonFrame.size.width + self.buttonSpacing;
//    searchFieldFrame.size.width = rightButtonX - searchFieldFrame.origin.x - self.buttonSpacing;
//    NSLog(@"search field frame: %@", NSStringFromCGRect(searchFieldFrame));
//    self.searchField.frame = searchFieldFrame;
}



#pragma mark - Showing and hiding progress

//-(void)hideProgress {
//    self.progressView.percentCompleted = 100;
//}
//
//-(void)showProgress {
//    progressView.hidden = NO;
//}

-(void)cancel {
    self.progressView.percentCompleted = 100;
}

-(void)finish {
    self.progressView.percentCompleted = 100;
}

#pragma mark - Progress bar

-(void)setProgress:(CGFloat)newProgress {
    NSLog(@"setting progress to %f", newProgress);
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
