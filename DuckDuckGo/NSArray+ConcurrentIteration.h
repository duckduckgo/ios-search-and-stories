//
//  NSArray+ConcurrentIteration.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/3/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSArray (ConcurrentIteration)

-(void)iterateWithMaximumConcurrentOperations:(NSUInteger)max block:(void (^)(NSUInteger i, id obj))block;

@end
