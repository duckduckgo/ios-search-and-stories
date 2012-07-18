//
//  IGFormRadioOption.m
//  Programming
//
//  Created by Ishaan Gulrajani on 4/4/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormRadioOption.h"


@implementation IGFormRadioOption
@synthesize category, value;

-(id)initWithCategory:(NSString *)aCategory title:(NSString *)aTitle {
	if((self = [super initWithTitle:aTitle])) {
		category = aCategory;
	}
	return self;
}


@end
