//
//  DDGSearchBarButton.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 23/05/2013.
//
//

#import "DDGSearchBarButton.h"

@implementation DDGSearchBarButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIEdgeInsets insets = UIEdgeInsetsMake(3.0, 5.0, 3.0, 5.0);
        [self setBackgroundImage:[[self backgroundImageForState:UIControlStateNormal] resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
        [self setBackgroundImage:[[self backgroundImageForState:UIControlStateHighlighted] resizableImageWithCapInsets:insets] forState:UIControlStateHighlighted];
        [self setBackgroundImage:[[self backgroundImageForState:UIControlStateDisabled] resizableImageWithCapInsets:insets] forState:UIControlStateDisabled];
        [self setBackgroundImage:[[self backgroundImageForState:UIControlStateSelected] resizableImageWithCapInsets:insets] forState:UIControlStateSelected];
    }
    return self;
}

- (CGRect)backgroundRectForBounds:(CGRect)bounds {
    return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(6.0, 0.0, 5.0, 0.0));
}

@end
