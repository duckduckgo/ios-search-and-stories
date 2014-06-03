//
//  DDGAutocompleteTableView.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/4/12.
//
//

#import "DDGAutocompleteTableView.h"
#import "DDGAutocompleteViewController.h"

@implementation DDGAutocompleteTableView

-(id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self)
        [self customInit];
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
        [self customInit];
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self)
        [self customInit];
    return self;
}

-(void)customInit {
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    recognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:recognizer];
}

-(void)tap:(UIGestureRecognizer *)recognizer {
    BOOL insideSubview = NO;
    for(UIView *subview in self.subviews) {
        if(subview.hidden == NO && subview.alpha > 0.1 && [subview pointInside:[recognizer locationInView:subview] withEvent:nil]) {
            insideSubview = YES;
            break;
        }
    }

    if(!insideSubview && [self.delegate respondsToSelector:@selector(tableViewBackgroundTouched)])
        [self.delegate performSelector:@selector(tableViewBackgroundTouched)];
}

@end
