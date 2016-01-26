//
//  DDGTraitHelper.m
//  DuckDuckGo
//
//  Created by Josiah Clumont @SwiftlyDeft on 15/01/16.
//
//

#import "DDGTraitHelper.h"

@implementation DDGTraitHelper

+ (BOOL)isFullScreeniPad:(UITraitCollection*)traitCollection {
    // NSLog(@"Trait collection is... %@", traitCollection);
    if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        return true;
    } else {
        return false;
    }
}

+ (BOOL)hasThisTraitCollection:(UITraitCollection*)newTraitCollection changedFromTraitCollection:(UITraitCollection*)previousTraitCollection {
    if (previousTraitCollection.horizontalSizeClass != newTraitCollection.horizontalSizeClass || previousTraitCollection.verticalSizeClass != newTraitCollection.verticalSizeClass) {
        return true;
    } else {
        return false;
    }
}

@end
