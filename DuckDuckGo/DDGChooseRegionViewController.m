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
#import "Constants.h"

@interface IGFormViewController (ExposePrivateMethod)

- (void)saveAndExit;

@end

@implementation DDGChooseRegionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = nil;
    
    [DDGSettingsViewController configureTable:self.tableView];
}

- (void)configure
{
    [self clearElements];
    self.title = NSLocalizedString(@"Region", @"Title or label for the region setting");
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self saveData:[self formData]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[self searchControllerDDG] popContentViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDGSettingsRefreshData object:nil];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [DDGSettingsViewController createSectionHeaderView:[self tableView:tableView titleForHeaderInSection:section]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    [DDGSettingsViewController configureSettingsCell:cell];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForFooterInSection:section];
    return title.length > 0 ? [DDGSettingsViewController createSectionFooterView:title] : nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 64.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

@end
