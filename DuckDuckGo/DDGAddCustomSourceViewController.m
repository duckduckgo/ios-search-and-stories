//
//  DDGAddCustomSourceViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/24/12.
//
//

#import "DDGAddCustomSourceViewController.h"
#import "DDGNewsProvider.h"

@implementation DDGAddCustomSourceViewController

-(void)configure
{
    self.title = @"Add Source";

	self.tableView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];

    [self addTextField:@"News keyword"];
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 38, 31); // the actual image is 36px wide but we need 1px horizontal padding on either side
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setImage:[UIImage imageNamed:@"save_button.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 58, 33);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

-(NSString *)validateData:(NSDictionary *)formData {
    if([[[formData objectForKey:@"News keyword"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
        return @"You must enter a news keyword.";
    else
        return nil;
}

-(void)saveData:(NSDictionary *)formData {
    [[DDGNewsProvider sharedProvider] addCustomSource:[formData objectForKey:@"News keyword"]];
}

-(void)backButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
