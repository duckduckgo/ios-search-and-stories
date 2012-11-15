//
//  DDGChooseRegionViewController.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 10/31/12.
//
//

#import "DDGChooseRegionViewController.h"
#import "DDGRegionProvider.h"

@implementation DDGChooseRegionViewController

- (void)configure
{
	self.title = @"Region";

    self.tableView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    [button addTarget:self action:@selector(saveAndExit) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

	// the actual image is 36px wide but we need 1px horizontal padding on either side
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
	else
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
    
    for(NSDictionary *regionSet in [DDGRegionProvider shared].regions) {
        for(NSString *regionKey in regionSet) {
            [self addRadioOption:@"region" title:[[DDGRegionProvider shared] titleForRegion:regionKey] enabled:([regionKey isEqualToString:[DDGRegionProvider shared].region])];
        }
    }
}

-(void)saveData:(NSDictionary *)formData {
    NSString *regionTitle = [formData objectForKey:@"region"];
    for(NSDictionary *regionSet in [DDGRegionProvider shared].regions) {
        for(NSString *regionKey in regionSet) {
            if([[regionSet objectForKey:regionKey] isEqualToString:regionTitle])
                [[DDGRegionProvider shared] setRegion:regionKey];
        }
    }
}

#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	CGPoint center = self.navigationItem.leftBarButtonItem.customView.center;
	if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
	else
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
	self.navigationItem.leftBarButtonItem.customView.center = center;
	
    return [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end
