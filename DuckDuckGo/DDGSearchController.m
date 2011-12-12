//
//  DDGSearchController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DDGSearchController.h"

@implementation DDGSearchController

@synthesize loadedCell;
@synthesize search;
@synthesize searchHandler;
@synthesize searchButton;
@synthesize state;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent
{
	self = [super initWithNibName:nibNameOrNil bundle:nil];
	if (self)
	{
		[parent addSubview:self.view];
		kbRect = CGRectZero;
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.view removeFromSuperview];
	[super dealloc];
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	search.rightViewMode = UITextFieldViewModeAlways;
	search.leftViewMode = UITextFieldViewModeAlways;
	search.leftView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spacer8x16.png"]] autorelease];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbShowing:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbHiding:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)kbShowing:(NSNotification*)notification
{
	kbRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	kbRect = [self.view convertRect:kbRect toView:nil];
}

- (void)kbHiding:(NSNotification*)notification
{
	kbRect = CGRectZero;
}


#pragma  mark - Handle user actions

- (void)autoCompleteReveal:(BOOL)reveal
{
	CGSize screenSize = self.view.superview.frame.size;
	CGRect rect = self.view.frame;
	if (reveal)
	{
		rect.size.height = screenSize.height - kbRect.size.height;
	}
	else
	{
		// clip to search entry height
		rect.size.height = 44.0;
	}
	[UIView animateWithDuration:0.25 animations:^
	{
		self.view.frame = rect;
	}];
}

- (IBAction)searchButtonAction:(UIButton*)sender
{
	[search resignFirstResponder];
	
	[searchHandler actionTaken:[NSDictionary dictionaryWithObjectsAndKeys:@"home", @"action", nil]];
}

- (void)switchModeTo:(enum eSearchState)searchState
{
	state = searchState;
}

#pragma  mark - Handle the text field input

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	[search resignFirstResponder];
//}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSUInteger lengthLeft = [textField.text length] - range.length + [string length];
	
	if (!lengthLeft)
		// going to NO characters
		[self autoCompleteReveal:NO];
	else if (![textField.text length] && lengthLeft)
		// going from NO characters to something
		[self autoCompleteReveal:YES];
	
	[tableView reloadData];
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	[self autoCompleteReveal:NO];
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSString *s = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (![s length])
	{
		textField.text = nil;
		return NO;
	}
	[textField resignFirstResponder];
	[self autoCompleteReveal:NO];
	
	[searchHandler actionTaken:[NSDictionary dictionaryWithObjectsAndKeys:@"web", @"action", [search.text length] ? search.text : nil, @"searchTerm", nil]];
	
	return YES;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // simulate server content
	NSInteger c = (15 - [search.text length]) * 5;
    return c <= 0 ? 10 : c;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
		cell.textLabel.textColor = [UIColor darkGrayColor];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    // Configure the cell...
	cell.textLabel.text = [NSString stringWithFormat:@"'%@' AC:%d", search.text, indexPath.row + 1];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 32.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
