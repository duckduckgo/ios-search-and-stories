//
//  DDGToolbarAutohider.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 2015.12.20.
//
//

#import <Foundation/Foundation.h>

@protocol DDGToolbarAutohiderDelegate <NSObject>

-(void)setHideToolbar:(BOOL)hideToolbar forScrollview:(UIScrollView*)scrollView;

@end


@interface DDGToolbarAutohider : NSObject <UIScrollViewDelegate>

@property (weak) id<DDGToolbarAutohiderDelegate> toolbarHiderDelegate;

-(id)initWithContainerView:(UIView*)containerView
                scrollView:(UIScrollView*)scrollView
                  delegate:(id<DDGToolbarAutohiderDelegate>)delegate;

@end
