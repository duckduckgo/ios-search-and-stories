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
@synthesize path;

-(id)initWithTitle:(NSString *)aTitle path:(NSString*)aPath action:(void(^)(void))anAction {
    self = [super initWithTitle:aTitle];
    if(self)
	{
        self.action = anAction;
		self.path = aPath;
    }
    return self;
}

@end
