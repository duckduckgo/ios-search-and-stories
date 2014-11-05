//
//  UIScrollView+DDG.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 05/11/2014.
//
//

#import "UIScrollView+DDG.h"
#import <objc/runtime.h>

@implementation UIScrollView (DDG)

- (BOOL)isIgnoringOffset {
    NSNumber *ignoring = objc_getAssociatedObject(self, @selector(isIgnoringOffset));
    return ignoring.boolValue;
}

- (CGFloat)offsetToIgnore {
    NSNumber *offset = objc_getAssociatedObject(self, @selector(offsetToIgnore));
    return offset.floatValue;
}

- (void)setIgnoringOffset:(BOOL)ignoring {
    objc_setAssociatedObject(self, @selector(isIgnoringOffset), @(ignoring), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setOffsetToIgnore:(CGFloat)offset {
    objc_setAssociatedObject(self, @selector(offsetToIgnore), @(offset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
