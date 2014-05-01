//
//  UIView+DDGSlideOverMenuController.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 27/03/2014.
//
//

#import "UIView+DDGSlideOverMenuController.h"

@implementation UIView (DDGSlideOverMenuController)

- (void)inspectViewHierarchy:(DDGViewInspectionBlock)block
{
    BOOL stop = NO;
    [self inspectViewHierarchy:block stop:&stop];
}

- (BOOL)shouldCauseMenuPanGestureToFail
{
    return NO;
}

- (UIImage *)snapshotImageAfterScreenUpdates:(BOOL)afterUpdates adjustBoundsForStatusBar:(BOOL)adjustBounds
{
    CGRect bounds = self.bounds;
    if (adjustBounds) {
        bounds.size.height += 20.0f;
    }
    UIGraphicsBeginImageContext(bounds.size);
    [self drawViewHierarchyInRect:bounds afterScreenUpdates:afterUpdates];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImageJPEGRepresentation(image, 0.75f);
    image = [UIImage imageWithData:data];
    return image;
}

#pragma mark - Private

- (void)inspectViewHierarchy:(DDGViewInspectionBlock)block stop:(BOOL *)stop
{
    if (!block || *stop) {
        return;
    }
    block(self, stop);
    for (UIView *view in self.subviews) {
        [view inspectViewHierarchy:block stop:stop];
        if (*stop) {
            break;
        }
    }
}

@end
