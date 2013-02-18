//
//  DDGSHKFormController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 18/02/2013.
//
//

#import "DDGSHKFormController.h"

@interface DDGSHKFormController ()

@end

@implementation DDGSHKFormController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.tableView.backgroundView = nil;
	self.tableView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];
}

@end
