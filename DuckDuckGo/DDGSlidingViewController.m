//
//  DDGSlidingViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 21/05/2013.
//
//

#import "DDGSlidingViewController.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface DDGHorizontalPanGestureRecognizer : UIPanGestureRecognizer

@end

@implementation DDGHorizontalPanGestureRecognizer

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    CGPoint translation = [self translationInView:self.view];
    if (abs(translation.y)/2.0 > abs(translation.x)) {
        self.state = UIGestureRecognizerStateFailed;
    }
}

@end

@interface DDGSlidingViewController ()
@property (nonatomic, strong) DDGHorizontalPanGestureRecognizer *panGesture;
@end

@implementation DDGSlidingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.panGesture = [[DDGHorizontalPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateTopViewHorizontalCenterWithRecognizer:)];
}

@end
