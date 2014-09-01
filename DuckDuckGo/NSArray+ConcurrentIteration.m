//
//  NSArray+ConcurrentIteration.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/3/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "NSArray+ConcurrentIteration.h"

@implementation NSArray (ConcurrentIteration)

-(void)iterateWithMaximumConcurrentOperations:(NSUInteger)threads block:(void (^)(NSUInteger, id))block {
    
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.suspended = YES;
    queue.maxConcurrentOperationCount = threads;
    
    NSUInteger count = self.count;
    for (NSUInteger i = 0; i < count; i++) {
        [queue addOperationWithBlock:^{
            block(i, [self objectAtIndex:i]);
        }];
    }
    
    queue.suspended = NO;
    [queue waitUntilAllOperationsAreFinished];
}

@end