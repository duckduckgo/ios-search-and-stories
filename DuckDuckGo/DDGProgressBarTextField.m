//
//  DDGProgressBarTextField.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDGProgressBarTextField.h"

@implementation DDGProgressBarTextField

- (void)setProgress:(CGFloat)progress {
    if(progress <= 0.0) {
        [self setBackground:[UIImage imageNamed:@"search_field.png"]];
        return;
    } else if(progress > 1.0) {
        progress = 1.0;
    }
    
    UIImage *background;
    UIImage *filled;
    // if retina display (from http://stackoverflow.com/questions/3504173/detect-retina-display)
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) {
        background = [UIImage imageNamed:@"search_field@2x.png"];
        filled = [UIImage imageNamed:@"filled_search_field@2x.png"];
    } else {
        background = [UIImage imageNamed:@"search_field.png"];
        filled = [UIImage imageNamed:@"filled_search_field.png"];
    }
        
    CGSize backgroundSize = CGSizeMake(background.size.width, background.size.height);
    UIGraphicsBeginImageContext(backgroundSize);
    
    [background drawAtPoint:CGPointZero];
    
    CGRect filledRect = CGRectMake(0, 0, filled.size.width * progress, filled.size.height);
    CGImageRef filledRef = CGImageCreateWithImageInRect([filled CGImage], filledRect);
    UIImage *croppedFilled = [UIImage imageWithCGImage:filledRef];
    CGImageRelease(filledRef);
    
    [croppedFilled drawAtPoint:CGPointZero];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self setBackground:result];
}

@end
