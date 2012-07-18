//
//  IGFormButton.m
//  Example
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormButton.h"

@implementation IGFormButton
@synthesize action;

-(id)initWithTitle:(NSString *)aTitle action:(void(^)(void))anAction {
    self = [super initWithTitle:aTitle];
    if(self) {
        self.action = anAction;
    }
    return self;
}

@end
