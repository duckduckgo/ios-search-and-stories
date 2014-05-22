//
//  DDGCustomDeleteViewController.m
//  
//
//  Created by Johnnie Walker on 18/04/2013.
//
//

#import "DDGCustomDeleteViewController.h"
#import "DDGMenuHistoryItemCell.h"

@implementation DDGCustomDeleteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeLeft.direction = (UISwipeGestureRecognizerDirectionLeft);
    swipeLeft.delegate = self;
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swipeRight.direction = (UISwipeGestureRecognizerDirectionRight);
    swipeRight.delegate = self;
    
    [self.tableView addGestureRecognizer:swipeLeft];
    [self.tableView addGestureRecognizer:swipeRight];
    
    self.deletingIndexPaths = [NSMutableSet set];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if (![self isViewLoaded]) {
        self.deletingIndexPaths = nil;
    }
}

- (void)cancelDeletingIndexPathsAnimated:(BOOL)animated {
    for (NSIndexPath *indexPath in self.deletingIndexPaths) {
        DDGMenuHistoryItemCell *cell = (DDGMenuHistoryItemCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell setDeletable:NO animated:animated];
    }
    [self.deletingIndexPaths removeAllObjects];
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)swipe {
    [self swipe:swipe direction:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)swipe {
    [self swipe:swipe direction:UISwipeGestureRecognizerDirectionRight];
}

- (void)swipe:(UISwipeGestureRecognizer *)swipe direction:(UISwipeGestureRecognizerDirection)direction {
    if (swipe.state == UIGestureRecognizerStateRecognized) {
        CGPoint point = [swipe locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath) {
            [self.deletingIndexPaths removeObject:indexPath];
            
            [self cancelDeletingIndexPathsAnimated:YES];
            
            BOOL deleting = (direction == UISwipeGestureRecognizerDirectionLeft);
            
            DDGMenuHistoryItemCell *cell = (DDGMenuHistoryItemCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell setDeletable:deleting animated:YES];
            
            if (deleting)
                [self.deletingIndexPaths addObject:indexPath];            
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    return (nil != indexPath);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self cancelDeletingIndexPathsAnimated:YES];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self cancelDeletingIndexPathsAnimated:YES];
}


@end
