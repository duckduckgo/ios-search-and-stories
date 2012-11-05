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
@synthesize detailTitle;

-(id)initWithTitle:(NSString *)aTitle detailTitle:(NSString*)aDetailTitle action:(void(^)(void))anAction {
    self = [super initWithTitle:aTitle];
    if(self)
	{
        self.action = anAction;
		self.detailTitle = aDetailTitle;
    }
    return self;
}

@end
