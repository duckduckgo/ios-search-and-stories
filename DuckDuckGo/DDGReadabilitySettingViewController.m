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
    
    self.tableView.backgroundView = nil;
	self.tableView.backgroundColor =  DDG_SETTINGS_BACKGROUND_COLOR;
}

- (void)configure
{
	self.title = NSLocalizedString(@"Region", @"View controller title");
    
    NSInteger readabilitySetting = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
    
    [self addSectionWithTitle:@"Readability" footer:nil];
    
    [self addRadioOptionWithTitle:@"Off" value:@(DDGReadabilityModeOff) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOff)];
    [self addRadioOptionWithTitle:@"On when available" value:@(DDGReadabilityModeOnIfAvailable) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOnIfAvailable)];
    [self addRadioOptionWithTitle:@"Only show articles with Readability" value:@(DDGReadabilityModeOnExclusive) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOnExclusive)];
    
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
@end
