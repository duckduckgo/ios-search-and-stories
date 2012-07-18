//
//  IGHouseAdView.m
//  CramberryPhone
//
//  Created by Ishaan Gulrajani on 9/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IGHouseAdView.h"


@implementation IGHouseAdView

+(IGHouseAdView *)houseAdView {
	IGHouseAdView *houseAdView = [[IGHouseAdView alloc] initWithFrame:CGRectZero];
	houseAdView.userInteractionEnabled = YES;
	return houseAdView;
}

-(void)setup {
	[self setFrame:self.frame];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/cramberry-flash-cards/id348699191?mt=8"]];
}

-(void)setFrame:(CGRect)newFrame {
	NSLog(@"setFrame:%@",NSStringFromCGRect(newFrame));
	if(newFrame.size.height == 50) {
		[self setImage:[UIImage imageNamed:@"like_upgrade.png"]];
	} else {
		[self setImage:[UIImage imageNamed:@"like_upgrade_wide.png"]];
	}
	
	[super setFrame:newFrame];
}

@end
