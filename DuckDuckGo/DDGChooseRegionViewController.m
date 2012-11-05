//
//  DDGChooseRegionViewController.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 10/31/12.
//
//

#import "DDGChooseRegionViewController.h"
#import "DDGRegionProvider.h"

@implementation DDGChooseRegionViewController

- (void)configure
{
	self.title = @"Region";

    self.tableView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 38, 31); // the actual image is 36px wide but we need 1px horizontal padding on either side
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    [button addTarget:self action:@selector(saveAndExit) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    
    for(NSDictionary *regionSet in [DDGRegionProvider shared].regions) {
        for(NSString *regionKey in regionSet) {
            [self addRadioOption:@"region" title:[[DDGRegionProvider shared] titleForRegion:regionKey] enabled:([regionKey isEqualToString:[DDGRegionProvider shared].region])];
        }
    }
}

-(void)saveData:(NSDictionary *)formData {
    NSString *regionTitle = [formData objectForKey:@"region"];
    for(NSDictionary *regionSet in [DDGRegionProvider shared].regions) {
        for(NSString *regionKey in regionSet) {
            if([[regionSet objectForKey:regionKey] isEqualToString:regionTitle])
                [[DDGRegionProvider shared] setRegion:regionKey];
        }
    }
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // this entry is
//	NSDictionary *entry = [[DDGRegionProvider shared].regions objectAtIndex:indexPath.row];
//	[[DDGRegionProvider shared] setRegion:[[entry allKeys] objectAtIndex:0]];
//    [self.navigationController popViewControllerAnimated:YES];
//}

@end
