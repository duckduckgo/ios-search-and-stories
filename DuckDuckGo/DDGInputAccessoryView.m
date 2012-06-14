//
//  DDGInputAccessoryView.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDGInputAccessoryView.h"

@implementation DDGInputAccessoryView
@synthesize background;

// This view ignores touches to itself while allowing touches to its subviews.
// Taken from http://vectorvector.tumblr.com/post/2130331861/ignore-touches-to-uiview-subclass-but-not-to-its

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil;
    else return hitView;
}

@end
