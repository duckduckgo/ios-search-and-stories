//
//  DDGPlusButton.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 02/04/2013.
//
//

#import "DDGPlusButton.h"

@implementation DDGPlusButton

+ (id)plusButtonWithImageName:(NSString *)imageName BackgroundImageNamed:(NSString *)backgroundImageName {
    DDGPlusButton *button = [self buttonWithType:UIButtonTypeCustom];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);
    [button setBackgroundImage:[[UIImage imageNamed:backgroundImageName] resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button addTarget:nil action:@selector(plus:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    return button;
}

+ (id)plusButton {
    return [self plusButtonWithImageName:@"btn-icon_plus" BackgroundImageNamed:@"btn-bg_plus"];
}

+ (id)lightPlusButton {
    return [self plusButtonWithImageName:@"btn-icon_plus_search-suggestions" BackgroundImageNamed:@"btn-bg_plus_search-suggestions"];
}

@end
