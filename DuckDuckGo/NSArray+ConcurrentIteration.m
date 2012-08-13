//
//  NSArray+ConcurrentIteration.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/3/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "NSArray+ConcurrentIteration.h"

@implementation NSArray (ConcurrentIteration)

-(void)iterateConcurrentlyWithThreads:(int)threads block:(void (^)(int, id))block {
    [self iterateConcurrentlyWithThreads:threads priority:DISPATCH_QUEUE_PRIORITY_DEFAULT block:block];
}

-(void)iterateConcurrentlyWithThreads:(int)threads priority:(dispatch_queue_priority_t)priority block:(void (^)(int i, id obj))block {
    int count = self.count;
    threads = MIN(threads, count); // no point making 10 threads for 5 objects
    __block int openThreads = 0;
    
    for(int thread=0;thread<threads;thread++) {
        @synchronized(self) {
            openThreads++;
        }
        dispatch_async(dispatch_get_global_queue(priority, 0), ^{
            for(int i=thread;i<count;i+=threads) {
                block(i, [self objectAtIndex:i]);
            }
            @synchronized(self) {
                openThreads--;
            }
        });
    }
    
    // wait until no remaining open threads, then return
    while (openThreads)
        usleep(100000);
    return;
}

@end