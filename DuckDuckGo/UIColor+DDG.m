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

+ (UIColor *)duckLightBlue
{
    return [UIColor colorWithRed:191.0f/255.0f green:223.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
}

+ (UIColor *)duckLightGray
{
    CGFloat component = 240.0f/255.0f;
    return [UIColor colorWithRed:component green:component blue:component alpha:1.0f];
}

+ (UIColor *)duckRed
{
    return [UIColor colorWithRed:208.0f/255.0f green:99.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
}

+ (UIColor *)autocompleteDetailColor
{
    return RGBA(140.0f, 145.0f, 148.0f, 1.0f);
}

+ (UIColor *)autocompleteHeaderColor
{
    return RGBA(225.0f, 225.0f, 225.0f, 1.0f);
}

+ (UIColor *)autocompleteTextColor
{
    return RGBA(57.0f, 57.0f, 57.0f, 1.0f);
}

+ (UIColor *)autocompleteTitleColor
{
    return RGBA(89.0f, 95.0f, 102.0f, 1.0f);
}

@end
