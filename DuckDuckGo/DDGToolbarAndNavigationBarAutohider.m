//
//  DDGToolbarAutohider.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 2015.12.20.
//
//

#import "DDGToolbarAndNavigationBarAutohider.h"
#import "Constants.h"

@interface DDGToolbarAndNavigationBarAutohider () {
    CGPoint lastOffset;
    CGFloat lastUpwardsScrollDistance;
}

@property CGFloat previousContentHeight;
@property UIView* containerView;
@property UIScrollView* scrollView;
@property NSLayoutConstraint* topToolbarBottomConstraint;
@property NSLayoutConstraint* bottomToolbarTopConstraint;

@end


@implementation DDGToolbarAndNavigationBarAutohider


-(id)initWithContainerView:(UIView*)containerView
                scrollView:(UIScrollView*)scrollView
                  delegate:(id<DDGToolbarAndNavigationBarAutohiderDelegate>)delegate
{
    self = [super init];
    if(self) {
        lastOffset                                = scrollView.contentOffset;
        lastUpwardsScrollDistance                 = 0;
        self.toolbarAndNavigationBarHiderDelegate = delegate;
        self.containerView                        = containerView;
        self.scrollView                           = scrollView;
        self.scrollView.delegate                  = self;
        
        // Register the notificaiton
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goBackToExpandedNavigationBarState) name:kDDGNotificationExpandToolNavBar object:nil];        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)autoHideOrShowToolbarBasedOnScrolling:(UIScrollView*)scrollView {
    CGPoint offset = scrollView.contentOffset;
    BOOL shouldStoreLastOffset = true;
    if(offset.y==0) {
        // we're at the top... show the toolbar
        lastUpwardsScrollDistance = 0;
        [self.toolbarAndNavigationBarHiderDelegate setHideToolbarAndNavigationBar:FALSE forScrollview:scrollView];
    } else if(offset.y  > lastOffset.y) {
        // we're scrolling down... hide the toolbar, unless we're already very close to the bottom
        CGFloat contentHeight = scrollView.contentSize.height - scrollView.frame.size.height;
        BOOL atBottom =  false;
        CGFloat distanceToTheBottom = contentHeight - offset.y;
        if (distanceToTheBottom < 100) {
            atBottom = true;
        }
        
        lastUpwardsScrollDistance = 0;
        [self.toolbarAndNavigationBarHiderDelegate setHideToolbarAndNavigationBar:!atBottom forScrollview:scrollView];
    } else if (offset.y > 0 && offset.y <= scrollView.contentSize.height+scrollView.frame.size.height+50) {
        // we're scrolling up... show the toolbar if we've gone past a certain threshold
        lastUpwardsScrollDistance += (lastOffset.y - offset.y);
        if(lastUpwardsScrollDistance > 50) {
            lastUpwardsScrollDistance = 0;
            [self.toolbarAndNavigationBarHiderDelegate setHideToolbarAndNavigationBar:FALSE forScrollview:scrollView];
        }
    } else {
        shouldStoreLastOffset = false;
    }
    
    // This fixes the issue of pulling up (think pull to refresh) causing an issue with the bar coming in an out... Make's it a whole lot more polished
    if (shouldStoreLastOffset) {
        lastOffset = offset;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self autoHideOrShowToolbarBasedOnScrolling:scrollView];
}

// Expanded
- (void)goBackToExpandedNavigationBarState {
    [self.toolbarAndNavigationBarHiderDelegate setHideToolbarAndNavigationBar:false forScrollview:self.scrollView];
}



@end
