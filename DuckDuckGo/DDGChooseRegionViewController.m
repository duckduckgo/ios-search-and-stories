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

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = nil;
    
    self.tableView.backgroundView = nil;
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];    
    [self saveData:[self formData]];
}

- (void)configure
{
	self.title = @"Region";

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    [button addTarget:self action:@selector(saveAndExit) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	
	// force 1st time through for iOS < 6.0
	[self viewWillLayoutSubviews];

    for(NSDictionary *regionSet in [DDGRegionProvider shared].regions) {
        for(NSString *regionKey in regionSet) {
            NSString *value = [[DDGRegionProvider shared] titleForRegion:regionKey];
            BOOL selected = [regionKey isEqualToString:[DDGRegionProvider shared].region];
            [self addRadioOptionWithTitle:value value:regionKey key:@"region" selected:selected];
        }
    }
}

-(void)saveData:(NSDictionary *)formData {
    NSString *regionKey = [formData objectForKey:@"region"];
    [[DDGRegionProvider shared] setRegion:regionKey];
}

#pragma mark - Rotation

- (void)viewWillLayoutSubviews
{
	CGPoint center = self.navigationItem.leftBarButtonItem.customView.center;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
	else
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
	self.navigationItem.leftBarButtonItem.customView.center = center;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end
