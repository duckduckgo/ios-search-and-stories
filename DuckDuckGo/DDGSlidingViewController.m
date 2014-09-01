//
//  DDGSlidingViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 21/05/2013.
//
//

#import "DDGHorizontalPanGestureRecognizer.h"
#import "DDGSlidingViewController.h"
//#import <UIKit/UIGestureRecognizerSubclass.h>

//@interface DDGHorizontalPanGestureRecognizer : UIPanGestureRecognizer
//
//@end
//
//@implementation DDGHorizontalPanGestureRecognizer
//
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    [super touchesMoved:touches withEvent:event];
//    
//    CGPoint translation = [self translationInView:self.view];
//    if (abs(translation.y) > abs(translation.x)) {
//        self.state = UIGestureRecognizerStateFailed;
//    }
//}
//
//@end

@interface ECSlidingViewController (ExposePrivateMethod)

- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer *)recognizer;

@end

@interface DDGSlidingViewController ()
@property (nonatomic, strong) DDGHorizontalPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *oldPanGesture;
@end

@implementation DDGSlidingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.oldPanGesture = [super panGesture];    
    self.panGesture = [[DDGHorizontalPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateTopViewHorizontalCenterWithRecognizer:)];
}

- (void)anchorTopViewTo:(ECSide)side animations:(void (^)())animations onComplete:(void (^)())complete {
    
    void(^newCompletion)() = ^ {
        [self.topViewController.view addGestureRecognizer:self.oldPanGesture];
        if (complete)
            complete();
    };
    
    [super anchorTopViewTo:side animations:animations onComplete:newCompletion];
}

- (void)resetTopViewWithAnimations:(void(^)())animations onComplete:(void(^)())complete {
    
    void(^newCompletion)() = ^ {
        [self.topViewController.view removeGestureRecognizer:self.oldPanGesture];
        if (complete)
            complete();
    };
    
    [super resetTopViewWithAnimations:animations onComplete:newCompletion];
};

@end
