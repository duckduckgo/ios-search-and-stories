//
//  DDGUnderViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import "DDGUnderViewController.h"
#import "ECSlidingViewController.h"
#import "DDGHomeViewController.h"
#import "DDGSettingsViewController.h"

@implementation DDGUnderViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 0;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    if(indexPath.section == 0)
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Stories";
            break;
        case 1:
            cell.textLabel.text = @"Settings";
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *newTopViewController;
    
    if(indexPath.section == 0 && indexPath.row == 0) {
        newTopViewController = _homeViewController;
    } else if(indexPath.section == 0 && indexPath.row == 1) {
        if(!_settingsViewController)
            self.settingsViewController = [[UINavigationController alloc] initWithRootViewController:[[DDGSettingsViewController alloc] initWithDefaults]];
        newTopViewController = _settingsViewController;
    }
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];
}

@end
