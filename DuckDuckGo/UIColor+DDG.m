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

@end
