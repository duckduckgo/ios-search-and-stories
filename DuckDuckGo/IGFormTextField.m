//
//  IGFormTextField.m
//  CramberryPad
//
//  Created by Ishaan Gulrajani on 4/3/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormTextField.h"


@implementation IGFormTextField
@synthesize textField;

-(id)initWithTitle:(NSString *)aTitle {
	if((self = [super initWithTitle:aTitle])) {
		textField = [[UITextField alloc] initWithFrame:CGRectZero];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.placeholder = aTitle;
	}
	return self;
}


@end
