//
//  DDGPanLeftGestureRecognizer.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 25/02/2013.
//
//

#import "DDGPanLeftGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface DDGPanLeftGestureRecognizer ()
@property (nonatomic) BOOL hasBegun;
@end

@implementation DDGPanLeftGestureRecognizer

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    CGPoint translation = [self translationInView:self.view];
    if (abs(translation.y) > abs(translation.x)) {
        self.state = UIGestureRecognizerStateFailed;
    } else {
        if (translation.x < 0) {
            // left
            self.hasBegun = YES;
        } else if (translation.x > 0) {
            // right
            if (!self.hasBegun) {
                self.state = UIGestureRecognizerStateFailed;
            }
        }        
    }
}

- (void)setState:(UIGestureRecognizerState)state {
    [super setState:state];
    
    if (state == UIGestureRecognizerStateFailed
        || state == UIGestureRecognizerStatePossible) {
        self.hasBegun = NO;
    }
}

- (void)reset {
    [super reset];
    self.hasBegun = NO;
}

@end
