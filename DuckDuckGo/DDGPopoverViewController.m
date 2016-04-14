//
//  DDGPopoverViewController.m
//  Popover
//
//  Created by Johnnie Walker on 07/05/2013.
//  Copyright (c) 2013 Random Sequence. All rights reserved.
//

#import "DDGPopoverViewController.h"
#import "DDGStoryCell.h"
#import "DDGStoryMenu.h"

@interface DDGPopoverBackgroundView : UIView
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *arrowImage;
@property (nonatomic, strong) UIImage *orientedArrowImage;
@property (nonatomic, strong) UIImageView* arrowView;
//@property (nonatomic) CGRect arrowRect;
@property (nonatomic) CGRect popoverRect;
@property (nonatomic) CGRect debugRect;
@property UIEdgeInsets borderInsets;
@property (nonatomic, weak) UIView* touchPassthroughView;
@property (nonatomic, weak) DDGPopoverViewController* popoverViewController;
@end



@interface DDGPopoverViewController ()
@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic) UIEdgeInsets borderInsets;   // the insets of the popover border
@property (nonatomic, strong) DDGPopoverBackgroundView *backgroundView;
@property (nonatomic, strong) UIImage* upArrowImage;
@property (nonatomic, strong) UIImage* downArrowImage;
@property (nonatomic, weak) UIView* touchPassthroughView;
@property (nonatomic, weak) UIView* anchorView;
@property UIPopoverArrowDirection arrowDirections;
@end


@implementation DDGPopoverBackgroundView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.borderInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        self.arrowView = [UIImageView new];
        [self addSubview:self.arrowView];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    UIView* dimView = self.popoverViewController.dimmedBackgroundView;
    if(dimView) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor duckDimmedPopoverBackground].CGColor);
        CGContextFillRect(context, [self convertRect:dimView.frame fromView:dimView.superview]);
    }
    
    [super drawRect:rect];
    
    [self.backgroundImage drawInRect:self.popoverRect];
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetFillColorWithColor(context, [[UIColor greenColor] colorWithAlphaComponent:0.3].CGColor);
//    CGContextFillRect(context, self.originRect);
//    
//    CGContextSetFillColorWithColor(context, [[UIColor blueColor] colorWithAlphaComponent:0.3].CGColor);
//    CGContextFillRect(context, self.arrowView.frame);
//    
//    CGContextSetFillColorWithColor(context, [[UIColor redColor] colorWithAlphaComponent:0.3].CGColor);
//    CGContextFillRect(context, self.popoverRect);
}

-(void)setArrowImage:(UIImage *)arrowImage
{
    _arrowImage = arrowImage;
    self.arrowView.image = arrowImage;
}

-(void)setBackgroundImage:(UIImage *)backgroundImage
{
    _backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(12,12,12,12)];
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    // If the hitView is THIS view, return the view that you want to receive the touch instead:
    if (hitView == self) {
        if(self.popoverViewController.shouldDismissUponOutsideTap) {
            // dismiss, but stil allow the hit to be passed through
            [self performSelector:@selector(goAwayNow) withObject:nil afterDelay:0.001];
            
            // Check the popoverViewController if the content view is of type DDGStoryMenu
            if ([self.popoverViewController.contentViewController isKindOfClass:[DDGStoryMenu class]]) {
                // Check the cell and see if the hit point falls in the cell, then dont pass the hit view
                DDGStoryMenu *menu     = (DDGStoryMenu*)self.popoverViewController.contentViewController;
                CGPoint locationInView = [menu.storyCell convertPoint:point fromView:menu.storyCell.window];
                
                if (CGRectContainsPoint(menu.storyCell.bounds, locationInView)) {
                    menu.storyCell.shouldGoToDetail = NO;
                    
                }
            }
        }

        BOOL isWithinContent = CGRectContainsPoint(self.popoverViewController.contentViewController.view.frame, point);
        if(isWithinContent) {
            return hitView;
        }
        
        // if we get here, we've gotten a tap outside of our own content area. Check to see
        // if it's within the dimmed view and if we're supposed to absorb those taps and dismiss
        UIView* dimView = self.popoverViewController.dimmedBackgroundView;
        if(dimView && self.popoverViewController.shouldAbsorbAndDismissUponDimmedViewTap) {
            if(CGRectContainsPoint(dimView.frame, [dimView convertPoint:point fromView:self])) {
                // the tap was within the dimmed view.  dismiss and absorb the touch ourselves
                [self performSelector:@selector(goAwayNow) withObject:nil afterDelay:0.001];
                return self;
            }
        }
        
        // this will pass any touches through to the passthroughview
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


-(CGRect)originRect {
    CGRect originRect = self.popoverViewController.anchorRect;
    UIView* originView = self.popoverViewController.anchorView;
    
    if(originRect.origin.x==0 && originRect.origin.y==0 && originRect.size.width==0 && originRect.size.height==0) {
        // if the originRect is zeroed out then we should attach this popover to the originView itself
        originRect = [self convertRect:originView.frame fromView:originView.superview];
    } else {
        // the originRect is not zero and so translate its coordinates to this view's space
        originRect = [self convertRect:originRect fromView:originView.superview];
    }
    return originRect;
}

- (void)layoutSubviews {
    // get the popover content size, either from preferredContentSize or from the actual size
    CGSize contentSize = self.popoverViewController.contentViewController.preferredContentSize;
    if(contentSize.width<=0 || contentSize.height<=0) {
        contentSize = self.popoverViewController.contentViewController.view.frame.size;
    }
    
    UIEdgeInsets insets = self.borderInsets;
    CGSize arrowSize = self.popoverViewController.upArrowImage.size;
    
    CGRect originRect = self.originRect;
    
    // get a starting point for the outer popover frame
    CGRect myFrame = self.frame;
    CGFloat popoverWidth = MIN(insets.left + insets.right + contentSize.width, myFrame.size.width);
    CGFloat popoverHeight = MIN(insets.top + insets.bottom + contentSize.height, myFrame.size.height);
    CGFloat popoverX = MAX(0, originRect.origin.x + (originRect.size.width / 2.0) - (popoverWidth/2.0));
    CGFloat popoverY = MAX(0, originRect.origin.y + originRect.size.height);
    
    // make sure the x isn't high enough to push the popover off the screen
    if (popoverX + popoverWidth > myFrame.size.width) {
        popoverX = MAX(0, myFrame.size.width - popoverWidth);
    }
    
    UIPopoverArrowDirection arrowDir = UIPopoverArrowDirectionUp;
    // if the popover thing is off of the screen and flipping the Y coordinates will
    // bring it fully back on-screen, then do so.
    if(self.popoverViewController.arrowDirections & UIPopoverArrowDirectionUp && popoverY + popoverHeight <= myFrame.size.height) {
        // the arrow can point up and has enough room to do so... the current rect is acceptable
        arrowDir = UIPopoverArrowDirectionUp;
        popoverY -= self.popoverViewController.intrusion;
        insets.top = MAX(insets.top, arrowSize.height);
    } else if(self.popoverViewController.arrowDirections & UIPopoverArrowDirectionDown) { // backgroundRect.origin.y - originRect.size.height - backgroundRect.size.height > 0
        // the arrow can point down.  We may not have room for it to do so, but we'll do it anyway because there wasn't room or the option to point up
        popoverY -= originRect.size.height + popoverHeight - self.popoverViewController.intrusion;
        arrowDir = UIPopoverArrowDirectionDown;
        insets.bottom = MAX(insets.top, arrowSize.height);
    }
    
    switch(arrowDir) {
        case UIPopoverArrowDirectionDown:
            self.arrowImage = self.popoverViewController.downArrowImage;
            self.arrowView.frame = CGRectMake(originRect.origin.x + (originRect.size.width/2.0) - (arrowSize.width / 2.0),
                                              popoverY + popoverHeight - arrowSize.height,
                                              arrowSize.width,
                                              arrowSize.height);
            break;
        case UIPopoverArrowDirectionUp:
        default:
            self.arrowImage = self.popoverViewController.upArrowImage;
            self.arrowView.frame = CGRectMake(originRect.origin.x + (originRect.size.width/2.0) - (arrowSize.width / 2.0),
                                              popoverY + 1,
                                              arrowSize.width,
                                              arrowSize.height);
            popoverY += arrowSize.height - self.borderInsets.top;
            break;
    }
    
    self.arrowView.hidden = self.popoverViewController.hideArrow;
    self.popoverRect = CGRectMake(popoverX, popoverY, popoverWidth, popoverHeight); // the popover frame image should be placed around the content
    self.popoverViewController.contentViewController.view.frame = UIEdgeInsetsInsetRect(self.popoverRect, self.borderInsets);
    
    [super layoutSubviews];
    
    [self setNeedsDisplay];
    //[self setNeedsUpdateConstraints];
}

@end


@implementation DDGPopoverViewController


- (id)initWithContentViewController:(UIViewController *)viewController
            andTouchPassthroughView:(UIView*)touchPassthroughView
{
    NSParameterAssert(nil != viewController);
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.contentViewController = viewController;
        self.touchPassthroughView = touchPassthroughView;
        self.intrusion = 6;
        self.shouldDismissUponOutsideTap = TRUE;
    }
    return self;
}


-(void)loadView
{
    [super loadView];
    self.backgroundView = [[DDGPopoverBackgroundView alloc] initWithFrame:self.touchPassthroughView.frame];
    self.backgroundView.popoverViewController = self;
    self.view = self.backgroundView;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    
    UIView *contentView = self.contentViewController.view;
    [self addChildViewController:self.contentViewController]; // calls [childViewController willMoveToParentViewController:self]
    [self.view addSubview:contentView];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.opaque = NO;
    contentView.layer.cornerRadius = 4.0;
    //contentView.alpha = 1;
    [self.contentViewController didMoveToParentViewController:self];
    
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backgroundView.touchPassthroughView = self.touchPassthroughView;
    self.backgroundView.backgroundImage = [UIImage imageNamed:@"popover-frame"];
    self.backgroundView.alpha = 0.0;
    
    NSString* arrowImageName = self.largeMode ? @"popover-indicator-large" : @"popover-indicator";
    self.upArrowImage = [UIImage imageNamed:arrowImageName];
    self.downArrowImage = [UIImage imageWithCGImage:self.upArrowImage.CGImage
                                              scale:self.upArrowImage.scale
                                        orientation:UIImageOrientationDownMirrored];
    //[self.view addSubview:self.backgroundView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if(self.shouldDismissUponOutsideTap) {
        [self.delegate popoverControllerDidDismissPopover:self];
        [self dismissPopoverAnimated:(duration > 0.0)];
    }
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromOrientation {
    [super didRotateFromInterfaceOrientation:fromOrientation];
    
    if(self.shouldDismissUponOutsideTap) {
        [self dismissPopoverAnimated:FALSE];
    } else {
        [self presentPopoverAnimated:FALSE];
    }
}



- (void)presentPopoverFromView:(UIView *)originView
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated
{
    self.anchorRect = CGRectZero; // originRect
    self.anchorView = originView;
    self.arrowDirections = arrowDirections;
    [self presentPopoverAnimated:animated];
}


- (void)presentPopoverFromRect:(CGRect)originRect
                        inView:(UIView *)originView
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated
{
    self.anchorRect = originRect;
    self.anchorView = originView;
    self.arrowDirections = arrowDirections;
    [self presentPopoverAnimated:animated];
}

- (void)presentPopoverAnimated:(BOOL)animated
{
    UIViewController *rootViewController = self.anchorView.window.rootViewController;
    if(rootViewController==nil || self.popoverParentController!=nil) {
        rootViewController = self.popoverParentController;
    }
    self.view.frame = rootViewController.view.frame; // the containing frame should cover the entire root view
    
    [rootViewController.view.window addSubview:self.view];
    [rootViewController addChildViewController:self];
    [self didMoveToParentViewController:rootViewController];
    
    [self.view addSubview:self.contentViewController.view];
    [self.view insertSubview:self.contentViewController.view belowSubview:self.backgroundView.arrowView];
    [self addChildViewController:self.contentViewController];
//    [self.contentViewController willMoveToParentViewController:self];
//    [self.contentViewController removeFromParentViewController]; // calls [childViewController didMoveToParentViewController:nil]


    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    NSTimeInterval duration = animated ? 0.4 : 0.0;
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         self.view.layer.shouldRasterize = NO;
                     }];
}

- (void)dismissPopoverAnimated:(BOOL)animated {
    [self dismissViewControllerAnimated:animated completion:^(void){
//        if ([self.delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)]) {
//            [self.delegate popoverControllerDidDismissPopover:self];
//        }
    }];
}

-(BOOL)isBeingPresented {
    return self.view.alpha != 0.0;
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
                         
                         if (finished) {
                             [self.delegate popoverControllerDidDismissPopover:self];
                         }
                         
                         if(completion!=NULL) completion();
                     }];

}

@end
