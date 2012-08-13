//
//  NSArray+ConcurrentIteration.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/3/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSArray (ConcurrentIteration)

-(void)iterateConcurrentlyWithThreads:(int)threads block:(void (^)(int i, id obj))block;
-(void)iterateConcurrentlyWithThreads:(int)threads priority:(dispatch_queue_priority_t)priority block:(void (^)(int i, id obj))block;

@end
