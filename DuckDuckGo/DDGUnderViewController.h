//
//  DDGUnderViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import <UIKit/UIKit.h>

@class DDGHomeViewController, DDGSettingsViewController;
@interface DDGUnderViewController : UITableViewController

@property(nonatomic, strong) DDGHomeViewController *homeViewController;
@property(nonatomic, strong) UINavigationController *settingsViewController;

@end
