//
//  DDGProgressBarTextField.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 5/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAddressBarTextField.h"
#import <QuartzCore/QuartzCore.h>

@implementation DDGAddressBarTextField

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self setup];
    }
    return self;
}

-(void)setup
{
    [self addTarget:self action:@selector(hideProgress) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(showProgress) forControlEvents:UIControlEventEditingDidEnd];
    
    self.backgroundColor = [UIColor whiteColor];
    CALayer *layer = self.layer;
    layer.cornerRadius = 2.0f;
    layer.masksToBounds = YES;
    
    progressView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"load_bar.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2.0, 0, 2.0)]];
    progressView.frame = CGRectMake(2, 2, 100, 27);
    [self insertSubview:progressView atIndex:1];
    
    [self setProgress:0];
}

#pragma mark - Showing and hiding progress

-(void)hideProgress {
    progressView.hidden = YES;
}

-(void)showProgress {
    progressView.hidden = NO;
}

-(void)cancel {
    [self setProgress:0.0 animationDuration:0.0];
    [progressView.layer removeAllAnimations];    
}

-(void)finish {
    [self setProgress:1.0 animationDuration:0.5];
    // the fade-out needs to happen before the width animation happens, otherwise the width animation will try to continue itself and render the setProgress:0 below useless
    [UIView animateWithDuration:0.45 animations:^{
        progressView.alpha = 0;
    } completion:^(BOOL finished) {
        [self setProgress:0];
        progressView.alpha = 1;
    }];
}

#pragma mark - Progress bar

-(void)setProgress:(CGFloat)newProgress {
    [self setProgress:newProgress animationDuration:2.0];
}

-(void)setProgress:(CGFloat)newProgress animationDuration:(CGFloat)duration {
    if(newProgress > 1)
        newProgress = 1;
    CGRect f = progressView.frame;
    f.size.width = (self.bounds.size.width-4)*newProgress;
    if(newProgress > progress) {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             progressView.frame = f;                     
                         }
                         completion:^(BOOL finished) {
                             if(finished)
                                 [self setProgress:newProgress+0.1 
                                 animationDuration:duration*4];
                         }];
    } else {
        [progressView.layer removeAllAnimations];
        progressView.frame = f;
    }
        progress = newProgress;
}

@end
