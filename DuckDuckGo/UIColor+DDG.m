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


+(UIColor*)duckSegmentedForeground
{
    return [UIColor whiteColor];
}

+(UIColor*)duckSegmentedBackground
{
    return [UIColor duckSearchBarBackground];
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
    return UIColorFromRGB(0x4495d4);
}

+ (UIColor*)duckProgressBarBackground
{
    return UIColorFromRGB(0x98c5e7);
}

+(UIColor*)duckStoriesBackground
{
    return UIColorFromRGB(0xEEEEEE);
}

+(UIColor*)duckRefreshColor
{
    return UIColorFromRGB(0xAAAAAA);
}

//+(UIColor*)duckSettingsLabel
//{
//    //return [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];
//    return UIColorFromRGB(0x222222);
//}
//
//+(UIColor*)duckSettingsDetailLabel
//{
//    return [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
//}
//

+ (UIColor*)duckSegmentBarBackground { return [UIColor duckSearchBarBackground]; }
+ (UIColor*)duckSegmentBarForeground { return [UIColor whiteColor]; }
+ (UIColor*)duckSegmentBarBackgroundSelected { return [UIColor whiteColor]; }
+ (UIColor*)duckSegmentBarForegroundSelected { return [UIColor duckSearchBarBackground]; }
+ (UIColor*)duckSegmentBarBorder { return [UIColor whiteColor]; }

+ (UIColor*)duckStoryMenuButtonBackground { return [[UIColor blackColor] colorWithAlphaComponent:0.5f]; }

+ (UIColor *)duckNoContentColor
{
    return UIColorFromRGB(0xEEEEEE);
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

+ (UIColor *)duckTableSeparator
{
    return UIColorFromRGB(0xdddddd);
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


+(UIColor*)duckPopoverBackground
{
    return [UIColor clearColor];
}

+ (UIColor *)autocompleteHeaderColor
{
    return [UIColor clearColor];
}



+ (UIColor *)duckListItemTextForeground
{
    return UIColorFromRGB(0x222222);
}
+ (UIColor *)duckListItemDetailForeground
{
    //return UIColorFromRGB(0x999999);
    return [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
}


+ (UIColor *)autocompleteTitleColor
{
    return RGBA(89.0f, 95.0f, 102.0f, 1.0f);
}

@end
