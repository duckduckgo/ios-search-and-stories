//
//  DDGProgressBarTextField.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 5/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAddressBarTextField.h"

@implementation DDGAddressBarTextField

- (void)setProgress:(CGFloat)progress {
    
    UIImage *background;
    UIImage *leftCap;
    UIImage *center;
    UIImage *rightPartial;
    UIImage *rightCap;
    // if retina display (from http://stackoverflow.com/questions/3504173/detect-retina-display)
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) {
        background = [UIImage imageNamed:@"search_field@2x.png"];
        leftCap = [UIImage imageNamed:@"load_bar_left@2x.png"];
        center = [UIImage imageNamed:@"load_bar_center@2x.png"];
        rightPartial = [UIImage imageNamed:@"load_bar_right_partial@2x.png"];
        rightCap = [UIImage imageNamed:@"load_bar_right@2x.png"];
    } else {
        background = [UIImage imageNamed:@"search_field.png"];

        // TODO: we need 1x graphics here!
        leftCap = [UIImage imageNamed:@"load_bar_left@2x.png"];
        center = [UIImage imageNamed:@"load_bar_center@2x.png"];
        rightPartial = [UIImage imageNamed:@"load_bar_right_partial@2x.png"];
        rightCap = [UIImage imageNamed:@"load_bar_right@2x.png"];
    }

    CGFloat inset = floor((background.size.height - leftCap.size.height)/2);
    
    // if there isn't enough progress to display the caps, don't even bother.
    if(progress <= (leftCap.size.width + rightCap.size.width + (2*inset)) / background.size.width) {
        [self setBackground:background];
        return;
    } else if(progress > 1.0) {
        progress = 1.0;
    }

    UIGraphicsBeginImageContext(background.size);
    
    [background drawAtPoint:CGPointZero];
    [leftCap drawAtPoint:CGPointMake(inset, inset)];
    
    CGFloat centerWidth = (background.size.width * progress) - leftCap.size.width - rightCap.size.width - 2*inset;
    [center drawInRect:CGRectMake(leftCap.size.width+inset,
                                  inset,
                                  centerWidth,
                                  center.size.height
                                  )];
    
    // start using the right cap image when we're 2px away from completion
    UIImage *right = (progress <= 1.0 - (2.0/background.size.width) ? rightPartial : rightCap);
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
    
    CGColorRef shadowColor = [[UIColor colorWithWhite:1.0 alpha:0.75] CGColor];
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlur, shadowColor);
    
    [super drawTextInRect:rect];
    
    CGContextRestoreGState(context);
}

@end
