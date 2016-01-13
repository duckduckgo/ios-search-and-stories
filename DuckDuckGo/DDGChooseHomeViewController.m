//
//  DDGChooseHomeViewController.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 12/09/2015.
//
//

#import "DDGChooseHomeViewController.h"

#import "DDGSearchController.h"
#import "DDGSettingsViewController.h"
#import "Constants.h"

@interface IGFormViewController (ExposePrivateMethod)

- (void)saveAndExit;

@end


@implementation DDGChooseHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = nil;
    [DDGSettingsViewController configureTable:self.tableView];
}

- (void)configure
{
    [self clearElements];
    self.title = NSLocalizedString(@"Home", @"Title or label for the default home view setting");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *homeViewMode = [defaults objectForKey:DDGSettingHomeView];
    
    [self addRadioOptionWithTitle:[DDGChooseHomeViewController homeViewNameForID:DDGSettingHomeViewTypeDuck]
                            value:DDGSettingHomeViewTypeDuck
                              key:DDGSettingHomeView
                         selected:[homeViewMode
                                   isEqual:DDGSettingHomeViewTypeDuck]];
    [self addRadioOptionWithTitle:[DDGChooseHomeViewController homeViewNameForID:DDGSettingHomeViewTypeStories]
                            value:DDGSettingHomeViewTypeStories
                              key:DDGSettingHomeView
                         selected:[homeViewMode isEqual:DDGSettingHomeViewTypeStories]];
    [self addRadioOptionWithTitle:[DDGChooseHomeViewController homeViewNameForID:DDGSettingHomeViewTypeSaved]
                            value:DDGSettingHomeViewTypeSaved
                              key:DDGSettingHomeView
                         selected:[homeViewMode isEqual:DDGSettingHomeViewTypeSaved]];
    [self addRadioOptionWithTitle:[DDGChooseHomeViewController homeViewNameForID:DDGSettingHomeViewTypeRecents]
                            value:DDGSettingHomeViewTypeRecents
                              key:DDGSettingHomeView
                         selected:[homeViewMode isEqual:DDGSettingHomeViewTypeRecents]];
}

+(NSString*)homeViewNameForID:(NSString*)viewID {
    if([viewID isEqualToString:DDGSettingHomeViewTypeDuck]) {
        return NSLocalizedString(@"Search", @"The name of the search view");
    } else if([viewID isEqualToString:DDGSettingHomeViewTypeStories]) {
        return NSLocalizedString(@"Stories (Default)", @"The name of the stories view");
    } else if([viewID isEqualToString:DDGSettingHomeViewTypeSaved]) {
        return NSLocalizedString(@"Favorites", @"The name of the favorites/bookmarks view");
    } else if([viewID isEqualToString:DDGSettingHomeViewTypeRecents]) {
        return NSLocalizedString(@"Recents", @"The name of the recents/history view");
    } else {
        return NSLocalizedString(@"Stories", @"The name of the stories view");
    }
}


-(void)saveData:(NSDictionary *)formData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([formData objectForKey:DDGSettingHomeView]) {
        [defaults setObject:[formData objectForKey:DDGSettingHomeView] forKey:DDGSettingHomeView];
    }
    [defaults synchronize];
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 64.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
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

@end
