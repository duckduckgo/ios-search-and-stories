//
//  DDGToolbarAndNavigationBarAutohider.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 2015.12.20.
//
//

#import <Foundation/Foundation.h>

@protocol DDGToolbarAndNavigationBarAutohiderDelegate <NSObject>

-(void)setHideToolbarAndNavigationBar:(BOOL)shouldHide forScrollview:(UIScrollView*)scrollView;

@end


@interface DDGToolbarAndNavigationBarAutohider : NSObject <UIScrollViewDelegate>

@property (weak) id<DDGToolbarAndNavigationBarAutohiderDelegate> toolbarAndNavigationBarHiderDelegate;

-(id)initWithContainerView:(UIView*)containerView
                scrollView:(UIScrollView*)scrollView
                  delegate:(id<DDGToolbarAndNavigationBarAutohiderDelegate>)delegate;

@end
