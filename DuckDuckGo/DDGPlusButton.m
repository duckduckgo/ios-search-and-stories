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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [button addTarget:nil action:@selector(plus:) forControlEvents:UIControlEventTouchUpInside];
#pragma clang diagnostic pop
    [button sizeToFit];
    
    return button;
}

+ (id)plusButton {
    return [self plusButtonWithImageName:@"btn-icon_plus" BackgroundImageNamed:@"btn-bg_plus"];
}

+ (id)lightPlusButton {
    return [self plusButtonWithImageName:@"btn-icon_plus_search-suggestions" BackgroundImageNamed:@"btn-bg_plus_search-suggestions"];
}

- (void)sizeToFit {
    [super sizeToFit];
    self.frame = CGRectInset(self.bounds, -6.0, -6.0);
}

- (CGRect)backgroundRectForBounds:(CGRect)bounds {
    return CGRectInset(self.bounds, 6.0, 6.0);
}

@end
