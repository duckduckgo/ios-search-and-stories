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
@property (nonatomic) CGRect arrowRect;
@end

@implementation DDGPopoverBackgroundView

- (void)drawRect:(CGRect)rect {
    [self.backgroundImage drawInRect:rect];
    [self.arrowImage drawInRect:self.arrowRect blendMode:kCGBlendModeCopy alpha:1.0];
}

@end

@interface DDGPopoverViewController ()
@property (nonatomic, strong, readwrite) UIViewController *contentViewController;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic, weak) DDGPopoverBackgroundView *backgroundView;
@end

@implementation DDGPopoverViewController

- (id)initWithContentViewController:(UIViewController *)viewController
{
    NSParameterAssert(nil != viewController);
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.contentViewController = viewController;
        self.edgeInsets = UIEdgeInsetsMake(20.0, 10.0, 10.0, 10.0);
    }
    return self;
}

- (void)loadView {
    DDGPopoverBackgroundView *backgroundView = [[DDGPopoverBackgroundView alloc] initWithFrame:CGRectZero];
    backgroundView.backgroundImage = [[UIImage imageNamed:@"bang-info_frame.png"] resizableImageWithCapInsets:self.edgeInsets];
    backgroundView.arrowImage = [UIImage imageNamed:@"bang-info_indicator.png"];
    self.backgroundView = backgroundView;
    self.view = backgroundView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.delegate popoverControllerDidDismissPopover:self];
    
    [self dismissPopoverAnimated:(duration > 0.0)];
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    CGSize contentSize = self.contentViewController.preferredContentSize;
    CGRect contentBounds = CGRectMake(0, 0, contentSize.width, contentSize.height);

    UIEdgeInsets insets = self.edgeInsets;
    UIEdgeInsets inverseInsets = UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right);
    
    CGRect outsetRect = UIEdgeInsetsInsetRect(contentBounds, inverseInsets);
    outsetRect.origin = CGPointZero;
    
    self.view.bounds = outsetRect;

    CGRect bounds = view.bounds;
    CGRect frame = self.view.frame;
    
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    
    frame = CGRectMake(rect.origin.x + (rect.size.width / 2.0) - (outsetRect.size.width/2.0),
                       rect.origin.y + rect.size.height,
                       frame.size.width,
                       frame.size.height);
    frame = CGRectIntegral(frame);
    frame.origin.x = MAX(bounds.origin.x, frame.origin.x);
    if (frame.origin.x + frame.size.width > bounds.origin.x + bounds.size.width) {
        frame.origin.x = bounds.origin.x + bounds.size.width - frame.size.width;
    }

    UIViewController *rootViewController = view.window.rootViewController;    
    CGRect rootRect = [rootViewController.view convertRect:frame fromView:view];    
    self.view.frame = rootRect;

    UIView *contentView = self.contentViewController.view;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.frame = UIEdgeInsetsInsetRect(self.view.bounds, insets);
    contentView.opaque = NO;
    
    [self addChildViewController:self.contentViewController]; // calls [childViewController willMoveToParentViewController:self]
    [self.view addSubview:contentView];
    [self.contentViewController didMoveToParentViewController:self];

    self.view.alpha = 0.0;
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    [rootViewController addChildViewController:self];
    [rootViewController.view addSubview:self.view];
    [self didMoveToParentViewController:rootViewController];
//    [view addSubview:self.view];
    
    CGRect backgroundBounds = self.view.bounds;
    CGRect backgroundButtonRect = [self.view convertRect:rect fromView:view];
    
    CGSize arrowSize = self.backgroundView.arrowImage.size;
    CGRect arrowRect = CGRectMake(backgroundButtonRect.origin.x + (backgroundButtonRect.size.width/2.0) - (arrowSize.width / 2.0),
                                  backgroundBounds.origin.y,
                                  arrowSize.width,
                                  arrowSize.height);
    self.backgroundView.arrowRect = arrowRect;
    
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


@end
