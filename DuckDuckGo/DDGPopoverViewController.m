//
//  DDGPopoverViewController.m
//  Popover
//
//  Created by Johnnie Walker on 07/05/2013.
//  Copyright (c) 2013 Random Sequence. All rights reserved.
//

#import "DDGPopoverViewController.h"

@interface DDGPopoverBackgroundView : UIView
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *arrowImage;
@property (nonatomic, strong) UIImage *orientedArrowImage;
@property (nonatomic) CGRect arrowRect;
@property (nonatomic) CGRect popoverRect;
@property (nonatomic) CGRect debugRect;

@property (nonatomic, weak) UIView* touchPassthroughView;
@property (nonatomic, weak) DDGPopoverViewController* popoverViewController;
@end

@implementation DDGPopoverBackgroundView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self.backgroundImage drawInRect:self.popoverRect];
    [self.arrowImage drawInRect:self.arrowRect blendMode:kCGBlendModeNormal alpha:1.0];
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // If the hitView is THIS view, return the view that you want to receive the touch instead:
    if (hitView == self) {
        [self performSelector:@selector(goAwayNow) withObject:nil afterDelay:0.02];
        return [self.touchPassthroughView hitTest:[self.touchPassthroughView convertPoint:point
                                                                                 fromView:self]
                                        withEvent:event];
    }
    // Else return the hitView (as it could be one of this view's buttons):
    return hitView;
}

-(void)goAwayNow {
    [self.popoverViewController dismissPopoverAnimated:TRUE];
}


@end


@interface DDGPopoverViewController ()
@property (nonatomic, strong, readwrite) UIViewController *contentViewController;
@property (nonatomic) UIEdgeInsets contentInsets;     // the insets from the outer popover edges to the content view
@property (nonatomic) UIEdgeInsets borderInsets;   // the insets of the popover border
@property (nonatomic, strong) DDGPopoverBackgroundView *backgroundView;
@property (nonatomic, strong) UIImage* upArrowImage;
@property (nonatomic, assign) CGFloat intrusion;
@property (nonatomic, weak) UIView* touchPassthroughView;
@end

@implementation DDGPopoverViewController

- (id)initWithContentViewController:(UIViewController *)viewController
                  andTouchPassthroughView:(UIView*)touchPassthroughView
{
    NSParameterAssert(nil != viewController);
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.contentViewController = viewController;
        self.contentInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        self.borderInsets = UIEdgeInsetsMake(12, 12, 4, 12);
        self.intrusion = 3;
        self.touchPassthroughView = touchPassthroughView;
    }
    return self;
}

- (void)loadView {
    self.upArrowImage = [UIImage imageNamed:@"popover-indicator"];
    self.backgroundView = [[DDGPopoverBackgroundView alloc] initWithFrame:self.touchPassthroughView.frame];
    self.backgroundView.popoverViewController = self;
    self.backgroundView.touchPassthroughView = self.touchPassthroughView;
    self.backgroundView.backgroundColor = [UIColor redColor];
    self.backgroundView.backgroundImage = [[UIImage imageNamed:@"popover-frame"] resizableImageWithCapInsets:UIEdgeInsetsMake(11,11,11,11)];
    self.view = self.backgroundView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor duckPopoverBackground];
    self.view.opaque = NO;
    //[self.view addSubview:self.backgroundView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.delegate popoverControllerDidDismissPopover:self];
    
    [self dismissPopoverAnimated:(duration > 0.0)];
}

- (void)presentPopoverFromRect:(CGRect)originRect inView:(UIView *)originView permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    CGSize contentSize = self.contentViewController.preferredContentSize;
    CGRect contentBounds = CGRectMake(0, 0, contentSize.width, contentSize.height);
    
    UIEdgeInsets insets = self.borderInsets;
    UIEdgeInsets inverseInsets = UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right);
    
    CGRect outsetRect = UIEdgeInsetsInsetRect(contentBounds, inverseInsets);
    outsetRect.origin = CGPointZero;
    
    self.view.bounds = outsetRect;
    
    CGRect bounds = originView.bounds;
    CGRect frame = self.view.frame;
    
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    
    frame = CGRectMake(originRect.origin.x + (originRect.size.width / 2.0) - (outsetRect.size.width/2.0),
                       originRect.origin.y + originRect.size.height,
                       frame.size.width,
                       frame.size.height);
    frame = CGRectIntegral(frame);
    frame.origin.x = MAX(bounds.origin.x, frame.origin.x);
    if (frame.origin.x + frame.size.width > bounds.origin.x + bounds.size.width) {
        frame.origin.x = bounds.origin.x + bounds.size.width - frame.size.width;
    }

    UIViewController *rootViewController = originView.window.rootViewController;    
    CGRect backgroundRect = [rootViewController.view convertRect:frame fromView:originView];
    self.view.frame = rootViewController.view.frame; // the containing frame should cover the entire root view
    
    UIView *contentView = self.contentViewController.view;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.opaque = NO;
    
    [self addChildViewController:self.contentViewController]; // calls [childViewController willMoveToParentViewController:self]
    [self.view addSubview:contentView];
    [self.contentViewController didMoveToParentViewController:self];

    self.view.alpha = 0.5;
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    [rootViewController addChildViewController:self];
    [rootViewController.view addSubview:self.view];
    
    [self didMoveToParentViewController:rootViewController];
    
    originRect = [self.view convertRect:originRect fromView:originView];
    
    UIPopoverArrowDirection arrowDir = UIPopoverArrowDirectionUp;
    
    // if the popover thing is off of the screen and flipping the Y coordinates will
    // bring it fully back on-screen, then do so.
    if(arrowDirections & UIPopoverArrowDirectionUp && backgroundRect.origin.y + backgroundRect.size.height <= self.view.frame.size.height) {
        // the arrow can point up and has enough room to do so... the current rect is acceptable
        arrowDir = UIPopoverArrowDirectionUp;
        backgroundRect.origin.y -= self.intrusion;
    } else if(arrowDirections & UIPopoverArrowDirectionDown) { // backgroundRect.origin.y - originRect.size.height - backgroundRect.size.height > 0
        // the arrow can point down.  We may not have room for it to do so, but we'll do it anyway because there wasn't room or the option to point up
        backgroundRect.origin.y -= originRect.size.height + backgroundRect.size.height - self.intrusion;
        arrowDir = UIPopoverArrowDirectionDown;
    }
    contentView.frame = UIEdgeInsetsInsetRect(backgroundRect, self.contentInsets);
    self.backgroundView.debugRect = contentView.frame;
    contentView.layer.cornerRadius = 4;
    
    self.backgroundView.popoverRect = backgroundRect; // the popover frame image should be placed around the content
    
    CGSize arrowSize = self.upArrowImage.size;
    
    switch(arrowDir) {
        case UIPopoverArrowDirectionDown:
            self.backgroundView.arrowRect = CGRectMake(originRect.origin.x + (originRect.size.width/2.0) - (arrowSize.width / 2.0),
                                                       originRect.origin.y - arrowSize.height + self.intrusion - 1,
                                                       arrowSize.width,
                                                       arrowSize.height);
            self.backgroundView.arrowImage = [UIImage imageWithCGImage:self.upArrowImage.CGImage scale:self.upArrowImage.scale orientation:UIImageOrientationDownMirrored];
            break;
        case UIPopoverArrowDirectionUp:
        default:
            self.backgroundView.arrowRect = CGRectMake(originRect.origin.x + (originRect.size.width/2.0) - (arrowSize.width / 2.0),
                                                       originRect.origin.y + originRect.size.height - self.intrusion,
                                                       arrowSize.width,
                                                       arrowSize.height);
            self.backgroundView.arrowImage = self.upArrowImage;
            break;
    }
    
    NSTimeInterval duration = animated ? 0.4 : 0.0;
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         self.view.layer.shouldRasterize = NO;
                     }];
}

- (void)dismissPopoverAnimated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.2 : 0.0;
    
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        [self.contentViewController willMoveToParentViewController:nil];
        [self.contentViewController.view removeFromSuperview];
        [self.contentViewController removeFromParentViewController]; // calls [childViewController didMoveToParentViewController:nil]        
    }];
}

-(void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSTimeInterval duration = animated ? 0.2 : 0.0;
    
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [self willMoveToParentViewController:nil];
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                         
                         [self.contentViewController willMoveToParentViewController:nil];
                         [self.contentViewController.view removeFromSuperview];
                         [self.contentViewController removeFromParentViewController]; // calls [childViewController didMoveToParentViewController:nil]
                         
                         if(completion!=NULL) completion();
                     }];

}

@end
