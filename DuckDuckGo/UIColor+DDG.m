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
    return RGBA(41.0f, 41.0f, 41.0f, 1.0f);
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

+ (UIColor*)duckTabBarBackground
{
    return [UIColor whiteColor];
}

+ (UIColor*)duckTabBarForeground
{
    return UIColorFromRGB(0xADADAD);
}

+ (UIColor*)duckTabBarForegroundSelected
{
    return UIColorFromRGB(0xDF5833);
}


+ (UIColor*)duckProgressBarForeground
{
    return [UIColor duckSearchBarBackground];
}

+ (UIColor*)duckProgressBarBackground
{
    return [UIColor whiteColor];
}

+(UIColor*)duckStoriesBackground
{
    return UIColorFromRGB(0xEEEEEE);
}


+ (UIColor*)duckSegmentBarBackground { return [UIColor duckSearchBarBackground]; }
+ (UIColor*)duckSegmentBarForeground { return [UIColor whiteColor]; }
+ (UIColor*)duckSegmentBarBackgroundSelected { return [UIColor whiteColor]; }
+ (UIColor*)duckSegmentBarForegroundSelected { return [UIColor duckSearchBarBackground]; }
+ (UIColor*)duckSegmentBarBorder { return [UIColor whiteColor]; }

+ (UIColor*)duckStoryMenuButtonBackground { return [[UIColor blackColor] colorWithAlphaComponent:0.5f]; }

+ (UIColor *)duckNoContentColor
{
    return UIColorFromRGB(0xEAEAEA);
}

+ (UIColor *)duckRed
{
    return UIColorFromRGB(0xDE5833);
}

+ (UIColor *)duckStoryReadColor
{
    return RGBA(158.0f, 158.0f, 158.0f, 1.0f);
}

+ (UIColor *)duckStoryTitleBackground
{
    return [UIColor whiteColor];
}

+ (UIColor *)duckStoryDropShadowColor
{
    return UIColorFromRGB(0xDADADA);
}


+ (UIColor *)duckSearchFieldBackground
{
    return UIColorFromRGB(0xBD4A2B);
}

+ (UIColor *)duckSearchBarBackground
{
    return UIColorFromRGB(0xDE5833);
}

+ (UIColor *)duckSearchFieldForeground
{
    return [UIColor whiteColor];
}

+ (UIColor *)duckSearchFieldPlaceholderForeground
{
    return [UIColor whiteColor];
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
