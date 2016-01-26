//
//  DDGFormViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 23/05/2013.
//
//

#import "DDGFormViewController.h"
#import "Constants.h"

@interface DDGFormViewController ()

@end

@implementation DDGFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.settingsTableView = self.tableView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSettingsData) name:kDDGSettingsRefreshData object:nil];
}

- (void)clearElements {
    [elements removeAllObjects];
}

#pragma mark - Selection & Update Methods
// Using the split view, after a user selects their home or region, it would actually update
- (void)refreshSettingsData {
    // Call to configure?
    [self configure];
    [self.settingsTableView reloadData];
}

@end
