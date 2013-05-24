//
//  DDGAutocompleteHeaderView.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 24/05/2013.
//
//

#import "DDGAutocompleteHeaderView.h"

@interface DDGAutocompleteHeaderView ()
@property (nonatomic, strong, readwrite) UIImage *backgroundImage;
@end

@implementation DDGAutocompleteHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        UILabel *label = [[UILabel alloc] initWithFrame:UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(0, 8.0, 0, 0))];
        
        self.backgroundImage = [UIImage imageNamed:@"section_tile.png"];
        label.backgroundColor = [UIColor clearColor];
        label.opaque = NO;
        label.textColor = [UIColor colorWithRed:0.329 green:0.341 blue:0.373 alpha:1.000];
        label.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        label.shadowOffset = CGSizeMake(0.5, 0.5);
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:label];
        _textLabel = label;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [self.backgroundImage drawInRect:rect];
}

@end
