//
//  DDGPassthroughView.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/5/12.
//
//

#import "DDGPassthroughView.h"

@implementation DDGPassthroughView

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.userInteractionEnabled && view.alpha > 0.1 && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}

@end
