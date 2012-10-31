//
//  DDGChooseRegionViewController.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 10/31/12.
//
//

#import "DDGChooseRegionViewController.h"
#import "DDGRegionProvider.h"

@interface DDGChooseRegionViewController ()

-(void)backButtonpressed;

@end

@implementation DDGChooseRegionViewController

-(void)backButtonpressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
	{
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Region";

	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
	button.frame = CGRectMake(0, 0, 36, 31);
	[button addTarget:self action:@selector(backButtonpressed) forControlEvents:UIControlEventTouchUpInside];

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[DDGRegionProvider shared].regions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    // this entry is
	NSDictionary *entry = [[DDGRegionProvider shared].regions objectAtIndex:indexPath.row];
	NSString *key = [[entry allKeys] objectAtIndex:0];
    cell.textLabel.text = [entry objectForKey:key];
	cell.accessoryType = [key isEqualToString:[DDGRegionProvider shared].region] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // this entry is
	NSDictionary *entry = [[DDGRegionProvider shared].regions objectAtIndex:indexPath.row];
	[[DDGRegionProvider shared] setRegion:[[entry allKeys] objectAtIndex:0]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
