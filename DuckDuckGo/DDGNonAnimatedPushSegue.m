//
//  DDGNonAnimatedPushSegue.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 1/27/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGNonAnimatedPushSegue.h"

@implementation DDGNonAnimatedPushSegue

-(void)perform {
    [[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:NO];
}

@end
