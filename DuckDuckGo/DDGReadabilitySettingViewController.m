//
//  DDGReadabilitySettingViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 13/05/2013.
//
//

#import "DDGReadabilitySettingViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGSearchController.h"

NSString * const DDGReadabilityModeKey = @"readability";

@implementation DDGReadabilitySettingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [DDGSettingsViewController configureTable:self.tableView];
}

- (void)configure
{
	self.title = NSLocalizedString(@"Region", @"View controller title");
    
    NSInteger readabilitySetting = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
    
    [self addSectionWithTitle:NSLocalizedString(@"Readability", @"Title for settings that improve readability") footer:nil];
    
    [self addRadioOptionWithTitle:NSLocalizedString(@"Off", @"Readability is turned off") value:@(DDGReadabilityModeOff) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOff)];
    [self addRadioOptionWithTitle:NSLocalizedString(@"On when available", @"Setting to use readability if it's available") value:@(DDGReadabilityModeOnIfAvailable) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOnIfAvailable)];
    [self addRadioOptionWithTitle:NSLocalizedString(@"Only show articles with Readability", @"Show only articles that can be viewed with Readability") value:@(DDGReadabilityModeOnExclusive) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOnExclusive)];
}

-(void)saveData:(NSDictionary *)formData {
    NSNumber *readabilitySetting = [formData objectForKey:DDGReadabilityModeKey];
    [[NSUserDefaults standardUserDefaults] setInteger:[readabilitySetting integerValue] forKey:DDGSettingStoriesReadabilityMode];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self saveData:[self formData]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[self searchControllerDDG] popContentViewControllerAnimated:YES];
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 64.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

@end
