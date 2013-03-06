//
//  DDGStoriesViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import "DDGStoriesViewController.h"
#import "DDGPanLeftGestureRecognizer.h"

@interface DDGStoriesViewController ()
@property (nonatomic, strong) NSOperationQueue *imageDownloadQueue;
@property (nonatomic, strong) NSOperationQueue *imageDecompressionQueue;
@property (nonatomic, strong) NSMutableSet *enqueuedDownloadOperations;
@property (nonatomic, strong) NSIndexPath *swipeViewIndexPath;
@property (nonatomic, strong) DDGPanLeftGestureRecognizer *panLeftGestureRecognizer;
@property (nonatomic, copy) NSArray *stories;

@end

@implementation DDGStoriesViewController


@end
