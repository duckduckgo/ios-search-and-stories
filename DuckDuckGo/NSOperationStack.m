//
//  NSOperationStack.m
//
//  Version 1.0
//
//  Created by Nick Lockwood on 28/06/2012.
//  Copyright (c) 2012 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/NSOperationStack
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "NSOperationStack.h"


@implementation NSOperationQueue (LIFO)

- (void)setLIFODependendenciesForOperation:(NSOperation *)op
{
    @synchronized(self)
    {
        //suspend queue
        BOOL wasSuspended = [self isSuspended];
        [self setSuspended:YES];
        
        //make op a dependency of all queued ops
        NSInteger index = [self operationCount] - [self maxConcurrentOperationCount];
        if (index >= 0)
        {
            NSOperation *operation = [[self operations] objectAtIndex:index];
            if (![operation isExecuting])
            {
                [operation addDependency:op];
            }
        }
        
        //resume queue
        [self setSuspended:wasSuspended];
    }
}

- (void)addOperationAtFrontOfQueue:(NSOperation *)op
{
    [self setLIFODependendenciesForOperation:op];
    [self addOperation:op];
}

- (void)addOperationsAtFrontOfQueue:(NSArray *)ops waitUntilFinished:(BOOL)wait
{
    for (NSOperation *op in ops)
    {
        [self setLIFODependendenciesForOperation:op];
    }
    [self addOperations:ops waitUntilFinished:wait];
}

- (void)addOperationAtFrontOfQueueWithBlock:(void (^)(void))block
{
    [self addOperationAtFrontOfQueue:[NSBlockOperation blockOperationWithBlock:block]];
}

@end


@implementation NSOperationStack

- (void)addOperation:(NSOperation *)op
{
    [self setLIFODependendenciesForOperation:op];
    [super addOperation:op];
}

- (void)addOperations:(NSArray *)ops waitUntilFinished:(BOOL)wait
{
    for (NSOperation *op in ops)
    {
        [self setLIFODependendenciesForOperation:op];
    }
    [super addOperations:ops waitUntilFinished:wait];
}

- (void)addOperationWithBlock:(void (^)(void))block
{
    [self addOperation:[NSBlockOperation blockOperationWithBlock:block]];
}

@end
