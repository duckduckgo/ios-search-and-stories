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
    if(progress < 0.0 || progress > 1.0)
        return;
    
    // TODO: make this work with retina displays eventually
    UIImage *background = [UIImage imageNamed:@"search_field.png"];
    
    CGSize backgroundSize = CGSizeMake(background.size.width, background.size.height);
    UIGraphicsBeginImageContext(backgroundSize);
    
    [background drawAtPoint:CGPointZero];
    
    UIImage *filled = [UIImage imageNamed:@"filled_search_field.png"];
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
