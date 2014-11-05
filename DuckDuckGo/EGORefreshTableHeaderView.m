//
//  EGORefreshTableHeaderView.m
//  Demo
//
//  Created by Devin Doty on 10/14/09October14.
//  Copyright 2009 enormego. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGORefreshTableHeaderView.h"
#import "UIScrollView+DDG.h"

#define FLIP_ANIMATION_DURATION 0.18f
#define FLIP_TRIGGER_OFFSET (-87.0)
#define LOADING_OFFSET (82.0)

@interface EGORefreshTableHeaderView () {
    EGOPullRefreshState _state;
	UILabel *_lastUpdatedLabel;
	UILabel *_statusLabel;
	UIActivityIndicatorView *_activityView;
}

@property (nonatomic, strong) UIImageView *arrowImageView;

- (void)setState:(EGOPullRefreshState)aState;

@end

@implementation EGORefreshTableHeaderView

@synthesize delegate=_delegate;


- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tintColor = [UIColor whiteColor];
        		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(75.0f, frame.size.height - 58.0f, self.frame.size.width, 20.0f)];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont boldSystemFontOfSize:14.0f];
        label.textColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		[self addSubview:label];
		_statusLabel = label;
		
        label = [[UILabel alloc] initWithFrame:CGRectMake(75.0f, frame.size.height - 42.0f, self.frame.size.width, 20.0f)];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont systemFontOfSize:14.0f];
        label.textColor = [UIColor colorWithWhite:1.0f alpha:0.65f];
		label.backgroundColor = [UIColor clearColor];
		[self addSubview:label];
		_lastUpdatedLabel = label;
        
        UIImage *arrowImage = [[UIImage imageNamed:@"PTR"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:arrowImage];
        arrowImageView.frame = CGRectMake(18.0f, CGRectGetHeight(frame) - 56.0f, 35.0f, 35.0f);
        [self addSubview:arrowImageView];
        self.arrowImageView = arrowImageView;
        
		UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		view.center = arrowImageView.center;
        [self addSubview:view];
		_activityView = view;
        
		[self setState:EGOOPullRefreshNormal];
    }
    return self;
}

#pragma mark -
#pragma mark Setters

- (void)refreshLastUpdatedDate {
	
	if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDataSourceLastUpdated:)]) {
		
		NSDate *date = [_delegate egoRefreshTableHeaderDataSourceLastUpdated:self];
		
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehaviorDefault];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];

        if(date)
            _lastUpdatedLabel.text = [NSString stringWithFormat:@"Last Updated: %@", [dateFormatter stringFromDate:date]];
		else
            _lastUpdatedLabel.text = @"";
        [[NSUserDefaults standardUserDefaults] setObject:_lastUpdatedLabel.text forKey:@"EGORefreshTableView_LastRefresh"];
		[[NSUserDefaults standardUserDefaults] synchronize];

	} else {
		
		_lastUpdatedLabel.text = nil;
		
	}

}

- (void)setState:(EGOPullRefreshState)aState
{
    if (aState == EGOOPullRefreshPulling) {
        _statusLabel.text = NSLocalizedString(@"Release to refresh", @"Release to refresh status");
        [UIView animateWithDuration:FLIP_ANIMATION_DURATION animations:^{
            [self.arrowImageView setTransform:CGAffineTransformMakeRotation((M_PI / 180.0f) * 180.0f)];
        }];
    } else if (aState == EGOOPullRefreshNormal) {
        if (_state == EGOOPullRefreshPulling) {
            [UIView animateWithDuration:FLIP_ANIMATION_DURATION animations:^{
                [self.arrowImageView setTransform:CGAffineTransformIdentity];
            }];
        }
        _statusLabel.text = NSLocalizedString(@"Pull down to refresh", @"Pull down to refresh status");
        [_activityView stopAnimating];
        [self.arrowImageView setHidden:NO];
        [self.arrowImageView setTransform:CGAffineTransformIdentity];
        [self refreshLastUpdatedDate];
    } else if (aState == EGOOPullRefreshLoading) {
        _statusLabel.text = NSLocalizedString(@"Loading...", @"Loading Status");
        [_activityView startAnimating];
        [self.arrowImageView setHidden:YES];
    }
    
    _state = aState;
}


#pragma mark -
#pragma mark ScrollView Methods

- (void)egoRefreshScrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (_state == EGOOPullRefreshLoading) {
		
		CGFloat offset = MAX(scrollView.contentOffset.y * -1, 0);
		offset = MIN(offset, LOADING_OFFSET);
		scrollView.contentInset = UIEdgeInsetsMake(offset, 0.0f, 0.0f, 0.0f);
		
	} else if (scrollView.isDragging) {
		
		BOOL _loading = NO;
		if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDataSourceIsLoading:)]) {
			_loading = [_delegate egoRefreshTableHeaderDataSourceIsLoading:self];
		}
		
        if(_loading) {
            [self setState:EGOOPullRefreshLoading];
        } else if (_state == EGOOPullRefreshPulling && scrollView.contentOffset.y > FLIP_TRIGGER_OFFSET && scrollView.contentOffset.y < 0.0f && !_loading) {
			[self setState:EGOOPullRefreshNormal];
		} else if (_state == EGOOPullRefreshNormal && scrollView.contentOffset.y < FLIP_TRIGGER_OFFSET && !_loading) {
			[self setState:EGOOPullRefreshPulling];
		}
		
		if (scrollView.contentInset.top != 0) {
			scrollView.contentInset = UIEdgeInsetsZero;
		}
		
	}
	
}

- (void)egoRefreshScrollViewDidEndDragging:(UIScrollView *)scrollView {
    
    BOOL _loading = NO;
	if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDataSourceIsLoading:)]) {
		_loading = [_delegate egoRefreshTableHeaderDataSourceIsLoading:self];
	}
	
	if (scrollView.contentOffset.y <= FLIP_TRIGGER_OFFSET && !_loading) {
		
		if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDidTriggerRefresh:)]) {
			[_delegate egoRefreshTableHeaderDidTriggerRefresh:self];
		}
		
		[self setState:EGOOPullRefreshLoading];
        
        [UIView animateWithDuration:0.2 animations:^{
            scrollView.offsetToIgnore = -LOADING_OFFSET;
            scrollView.ignoringOffset = YES;
            scrollView.contentInset = UIEdgeInsetsMake(LOADING_OFFSET, 0.0f, 0.0f, 0.0f);
            scrollView.ignoringOffset = NO;
        }];
//        [UIView beginAnimations:nil context:NULL];
//		[UIView setAnimationDuration:0.2];
//        NSLog(@"Setting contentInset");
//		scrollView.contentInset = UIEdgeInsetsMake(LOADING_OFFSET, 0.0f, 0.0f, 0.0f);
//		[UIView commitAnimations];
	}
	
}

- (void)egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView {	
	
//    [UIView beginAnimations:nil context:NULL];
//	[UIView setAnimationDuration:.3];
//	[scrollView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
//	[UIView commitAnimations];
	
    [UIView animateWithDuration:0.3 animations:^{
        scrollView.contentInset = UIEdgeInsetsZero;
    }];
    
	[self setState:EGOOPullRefreshNormal];

}

@end
