//
//  DDGAutocompleteHeaderView.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 24/05/2013.
//
//

#import "DDGAutocompleteHeaderView.h"

@interface DDGAutocompleteHeaderView ()

@property (nonatomic, weak, readwrite) UILabel *textLabel;

@end

@implementation DDGAutocompleteHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor duckStoriesBackground];
        self.opaque = TRUE;

        UILabel *label = [[UILabel alloc] initWithFrame:UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(0, 8.0, 0, 0))];
        label.backgroundColor = [UIColor clearColor];
        label.opaque = NO;
        label.textColor = [UIColor autocompleteTitleColor];
        label.font = [UIFont duckFontWithSize:13.0f];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:label];
        self.textLabel = label;
    }
    return self;
}

@end
