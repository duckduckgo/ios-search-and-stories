//
//  DDGDeleteButton.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/04/2013.
//
//

#import "DDGDeleteButton.h"

@implementation DDGDeleteButton

+ (void)initialize {
    UIEdgeInsets insets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
    
    [[DDGDeleteButton appearance] setBackgroundImage:[[UIImage imageNamed:@"btn-list_delete"] resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
    [[DDGDeleteButton appearance] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[DDGDeleteButton appearance] setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];    
}

+ (id)deleteButton {
    DDGDeleteButton *button = [super buttonWithType:UIButtonTypeCustom];

    button.titleLabel.shadowColor = [UIColor blackColor];
    button.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    
    return button;
}

@end
