//
//  IGFormSection.m
//  CramberryPad
//
//  Created by Ishaan Gulrajani on 4/3/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormElement.h"


@implementation IGFormElement
@synthesize title;

-(id)initWithTitle:(NSString *)aTitle {
	if((self = [super init])) {
		title = [aTitle copy];
	}
	return self;
}



-(UIResponder *)control {return nil;}
-(void)setControl:(UIResponder *)newControl {}

@end
