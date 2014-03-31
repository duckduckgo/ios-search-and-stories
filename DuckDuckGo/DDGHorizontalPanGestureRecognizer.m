//
//  DDGHorizontalPanGestureRecognizer.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 31/03/2014.
//
//

#import "DDGHorizontalPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation DDGHorizontalPanGestureRecognizer

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    CGPoint translation = [self translationInView:self.view];
    if (abs(translation.y) > abs(translation.x)) {
        self.state = UIGestureRecognizerStateFailed;
    }
}

@end
