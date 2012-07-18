//
//  IGFormTextView.m
//  CramberryPad
//
//  Created by Ishaan Gulrajani on 7/2/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormTextView.h"


@implementation IGFormTextView
@synthesize textView;

-(id)initWithTitle:(NSString *)aTitle {
	if((self = [super initWithTitle:aTitle])) {
		textView = [[UITextView alloc] initWithFrame:CGRectZero];
		textView.opaque = NO;
		textView.backgroundColor = [UIColor clearColor];
		textView.font = [UIFont systemFontOfSize:17.0f];
	}
	return self;
}



@end
