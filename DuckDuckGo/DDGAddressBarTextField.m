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
        [self customInit];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self customInit];
    }
    return self;
}

-(void)customInit {
    [self addTarget:self action:@selector(hideProgress) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(showProgress) forControlEvents:UIControlEventEditingDidEnd];
    
    self.background = [[UIImage imageNamed:@"search_field.png"] stretchableImageWithLeftCapWidth:20.0 topCapHeight:0];
    
    progressView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"load_bar.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:0]];
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

// this adds a drop shadow under the text which is only visible when the progress bar is visible
- (void) drawTextInRect:(CGRect)rect {
    CGSize shadowOffset = CGSizeMake(0, 1);
    CGFloat shadowBlur = 0;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    float components[4] = {1, 1, 1, 0.75};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef shadowColor = CGColorCreate( colorSpace, components);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlur, shadowColor);
    CGColorRelease(shadowColor);
	CGColorSpaceRelease(colorSpace);
    
    [super drawTextInRect:rect];
    
    CGContextRestoreGState(context);
}

@end
