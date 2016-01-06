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
    return [UIColor colorWithRed:0.678 green:0.678 blue:0.678 alpha:1]; // #ADADAD
}

+ (UIColor*)duckTabBarForegroundSelected
{
    return [UIColor colorWithRed:0.874 green:0.345 blue:0.2 alpha:1]; // #DF5833
}

+ (UIColor*)duckTabBarBorder
{
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:0.15];
}

+ (UIColor*)duckProgressBarForeground
{
    return [UIColor colorWithRed:0.266 green:0.584 blue:0.831 alpha:1]; // #4495d4
}

+ (UIColor*)duckProgressBarBackground
{
    return [UIColor colorWithRed:0.596 green:0.772 blue:0.905 alpha:1]; // #98c5e7
}

+(UIColor*)duckStoriesBackground
{
    return [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]; // #EEEEEE
}

+(UIColor*)duckRefreshColor
{
    return [UIColor colorWithRed:0.666 green:0.666 blue:0.666 alpha:1]; // #AAAAAA
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
    return [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]; // #EEEEEE
}

+ (UIColor *)duckRed
{
    return [UIColor colorWithRed:0.87 green:0.345 blue:0.2 alpha:1]; // #DE5833
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
    return [UIColor colorWithRed:0.854 green:0.854 blue:0.854 alpha:1]; // #DADADA
}

+ (UIColor *)duckTableSeparator
{
    return [UIColor colorWithRed:0.866 green:0.866 blue:0.866 alpha:1]; // #dddddd
}


+ (UIColor *)duckSearchFieldBackground
{
    return [UIColor colorWithRed:0.741 green:0.29 blue:0.168 alpha:1]; // #BD4A2B
}

+ (UIColor *)duckSearchBarBackground
{
    return [UIColor colorWithRed:0.87 green:0.345 blue:0.2 alpha:1]; // #DE5833
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

+(UIColor*)duckDimmedPopoverBackground { return [[UIColor blackColor] colorWithAlphaComponent:0.35]; }

+ (UIColor *)autocompleteHeaderColor
{
    return [UIColor clearColor];
}



+ (UIColor *)duckListItemTextForeground
{
    return [UIColor colorWithRed:0.133 green:0.133 blue:0.133 alpha:1]; // #222222
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
