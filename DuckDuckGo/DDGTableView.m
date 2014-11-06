//
//  DDGTableView.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 06/11/2014.
//
//

#import "DDGTableView.h"
#import <objc/runtime.h>

NSString * const DDGObfuscatedSelectorName = @"*_*a*d*j*u*s*t*C*o*n*t*e*n*t*O*f*f*s*e*t*I*f*N*e*c*e*s*s*a*r*y*";

@implementation DDGTableView

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        NSString *selector = [DDGObfuscatedSelectorName stringByReplacingOccurrencesOfString:@"*" withString:@""];
        SEL originalSelector = NSSelectorFromString(selector);
        SEL swizzledSelector = @selector(ignoreAdjustContentOffsetIfNecessary);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class,
                                       originalSelector,
                                       method_getImplementation(swizzledMethod),
                                       method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)ignoreAdjustContentOffsetIfNecessary {}

@end
