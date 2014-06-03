//
//  DDGChooseRegionViewController.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 10/31/12.
//
//

#import "DDGChooseRegionViewController.h"
#import "DDGRegionProvider.h"
#import "DDGSearchController.h"
#import "DDGSettingsViewController.h"

@implementation DDGChooseRegionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = nil;
    
    self.tableView.backgroundView = nil;
	self.tableView.backgroundColor =  DDG_SETTINGS_BACKGROUND_COLOR;
}

- (void)configure
{
	self.title = @"Region";

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    [button addTarget:self action:NSSelectorFromString(@"saveAndExit") forControlEvents:UIControlEventTouchUpInside];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self saveData:[self formData]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[self searchControllerDDG] popContentViewControllerAnimated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view;
    DDG_SETTINGS_HEADER(view, [self tableView:tableView titleForHeaderInSection:section])
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    DDG_SETTINGS_TITLE_LABEL(cell.textLabel)
    DDG_SETTINGS_DETAIL_LABEL(cell.detailTextLabel)
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = nil;
    NSString *title = [self tableView:tableView titleForFooterInSection:section];
    if (nil != title) {
        DDG_SETTINGS_FOOTER(view, title)
    }
    return view;
}
@end
