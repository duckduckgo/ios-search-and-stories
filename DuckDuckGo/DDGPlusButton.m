//
//  DDGPlusButton.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 02/04/2013.
//
//

#import "DDGPlusButton.h"

@implementation DDGPlusButton

+ (id)plusButton {
    DDGPlusButton *button = [self buttonWithType:UIButtonTypeCustom];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);    
    [button setBackgroundImage:[[UIImage imageNamed:@"btn-bg_plus"] resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"btn-icon_plus"] forState:UIControlStateNormal];
    [button addTarget:nil action:@selector(plus:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    return button;
}

@end
