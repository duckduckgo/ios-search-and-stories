//
//  UIColor+DDG.m
//  DuckDuckGo
//
//  Created by Fernando Olivares on 7/11/13.
//
//

#import "UIColor+DDG.h"

@implementation UIColor (DDG)

+ (UIColor *)slideOutMenuTextColor;
{
    //Hex is #bcc1cc.
    //RGB is 188, 193, 204.
    CGFloat red = 188.0/255.0;
    CGFloat green = 193.0/255.0;
    CGFloat blue = 204.0/255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.000];
}

+ (UIColor *)duckBlack
{
    return [UIColor colorWithRed:47.0f/255.0f green:47.0f/255.0f blue:47.0f/255.0f alpha:1.0f];
}

+ (UIColor *)duckGray
{
    return [UIColor colorWithRed:86.0f/255.0f green:86.0f/255.0f blue:86.0f/255.0f alpha:1.0f];
}

+ (UIColor *)duckLightGray
{
    CGFloat component = 240.0f/255.0f;
    return [UIColor colorWithRed:component green:component blue:component alpha:1.0f];
}

+ (UIColor *)duckRed
{
    return [UIColor colorWithRed:217.0f/255.0f green:73.0f/255.0f blue:38.0f/255.0f alpha:1.0f];
}

@end
