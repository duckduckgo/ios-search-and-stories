//
//  DDGProgressBarTextField.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 5/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAddressBarTextField.h"

@interface DDGAddressBarTextField (Private)
-(void)updateBackgroundWithProgress:(CGFloat)newProgress;
-(void)hideProgress;
-(void)showProgress;
@end

@implementation DDGAddressBarTextField

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self addTarget:self action:@selector(hideProgress) forControlEvents:UIControlEventEditingDidBegin];
        [self addTarget:self action:@selector(showProgress) forControlEvents:UIControlEventEditingDidEnd];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self addTarget:self action:@selector(hideProgress) forControlEvents:UIControlEventEditingDidBegin];
        [self addTarget:self action:@selector(showProgress) forControlEvents:UIControlEventEditingDidEnd];
    }
    return self;
}

#pragma mark - Showing and hiding progress

-(void)hideProgress {
    [self updateBackgroundWithProgress:0.0];
}

-(void)showProgress {
    [self updateBackgroundWithProgress:progress];
}

#pragma mark - Progress bar

-(void)setProgress:(CGFloat)newProgress {
    progress = newProgress;
    if(!self.isEditing)
        [self updateBackgroundWithProgress:newProgress];
}

- (void)updateBackgroundWithProgress:(CGFloat)newProgress {    
    UIImage *background;
    UIImage *leftCap;
    UIImage *center;
    UIImage *rightPartial;
    UIImage *rightCap;
    // if retina display (from http://stackoverflow.com/questions/3504173/detect-retina-display)
    //if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) {
    if(true) { // we're forcing retina graphics right now because we don't have the required 1x graphics. TODO: get some 1x graphics and uncomment the line above!
        background = [UIImage imageNamed:@"search_field@2x.png"];
        leftCap = [UIImage imageNamed:@"load_bar_left@2x.png"];
        center = [UIImage imageNamed:@"load_bar_center@2x.png"];
        rightPartial = [UIImage imageNamed:@"load_bar_right_partial@2x.png"];
        rightCap = [UIImage imageNamed:@"load_bar_right@2x.png"];
    } else {
        background = [UIImage imageNamed:@"search_field.png"];
        leftCap = [UIImage imageNamed:@"load_bar_left.png"];
        center = [UIImage imageNamed:@"load_bar_center.png"];
        rightPartial = [UIImage imageNamed:@"load_bar_right_partial.png"];
        rightCap = [UIImage imageNamed:@"load_bar_right.png"];
    }

    CGFloat inset = floor((background.size.height - leftCap.size.height)/2);

    // if there isn't enough progress to display the caps, don't even bother.
    if(newProgress <= (leftCap.size.width + rightCap.size.width + (2*inset)) / background.size.width) {
        [self setBackground:background];
        return;
    } else if(newProgress > 1.0) {
        newProgress = 1.0;
    }

    UIGraphicsBeginImageContext(background.size);
    
    [background drawAtPoint:CGPointZero];
    [leftCap drawAtPoint:CGPointMake(inset, inset)];
    
    CGFloat centerWidth = (background.size.width * newProgress) - leftCap.size.width - rightCap.size.width - 2*inset;
    centerWidth = floor(centerWidth);
    [center drawInRect:CGRectMake(leftCap.size.width+inset,
                                  inset,
                                  centerWidth,
                                  center.size.height
                                  )];
    
    // start using the right cap image when we're 2px away from completion
    UIImage *right = (newProgress <= 1.0 - (2.0/background.size.width) ? rightPartial : rightCap);
    [right drawAtPoint:CGPointMake(leftCap.size.width + centerWidth + inset, inset)];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self setBackground:result];
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
    
    [super drawTextInRect:rect];
    
    CGContextRestoreGState(context);
}

@end
