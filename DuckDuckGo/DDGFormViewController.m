//
//  DDGFormViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 23/05/2013.
//
//

#import "DDGFormViewController.h"
#import "DDGGroupedTableViewCell.h"

@interface DDGFormViewController ()

@end

@implementation DDGFormViewController

- (void)viewDidLoad
{
    [self.tableView registerClass:[DDGGroupedTableViewCell class] forCellReuseIdentifier:IGFormViewDefaultCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"DDGGroupedTableViewCellValue1" bundle:nil] forCellReuseIdentifier:IGFormViewValue1CellIdentifier];
    
    [super viewDidLoad];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        
    if ([cell isKindOfClass:[DDGGroupedTableViewCell class]]) {
        
        DDGGroupedTableViewCell *groupedCell = (DDGGroupedTableViewCell *)cell;
        
        NSInteger rows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
        
        if (indexPath.row == 0 && rows == 1) {
            groupedCell.position = GroupedTableViewCellPositionFull;
        }
        
        if (indexPath.row == 0 && rows > 1) {
            groupedCell.position = GroupedTableViewCellPositionTop;
        }
        
        if (indexPath.row > 0 && rows > 1) {
            groupedCell.position = GroupedTableViewCellPositionMiddle;
        }
        
        if (indexPath.row == (rows -1) && rows > 1) {
            groupedCell.position = GroupedTableViewCellPositionBottom;
        }
    }
    
    return cell;
}

@end
