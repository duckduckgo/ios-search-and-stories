//
//  UIScrollView+DDG.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 05/11/2014.
//
//

#import <UIKit/UIKit.h>

@interface UIScrollView (DDG)

@property (nonatomic, assign) CGFloat offsetToIgnore;
@property (nonatomic, assign, getter = isIgnoringOffset) BOOL ignoringOffset;

@end
