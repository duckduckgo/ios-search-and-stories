//
//  DDGTopicsTrendsPick.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGTopicsTrendsPick.h"
#import "UtilityCHS.h"
#import "JSON.h"
#import "NSString+SBJSON.h"

@implementation DDGTopicsTrendsPick

@synthesize loadedCell;
@synthesize tableView;
@synthesize entries;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	// Do any additional setup after loading the view, typically from a nib.
	
	dataHelper = [[DataHelper alloc] initWithDelegate:self];

//	[tableView registerNib:[UINib nibWithNibName:@"" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@""];
	
	self.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:12.0/255.0 alpha:1.0]; //[UIColor colorWithPatternImage:[UIImage imageNamed:@"blackBar4x44.png"]];
	
	UILabel *lbl = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	lbl.text = NSLocalizedString (@"Pick Topics + Sources", @"A comment");
	lbl.textColor = [UIColor lightGrayColor];
	lbl.backgroundColor = [UIColor clearColor];
	lbl.font = [UIFont boldSystemFontOfSize:21.0];
	[lbl sizeToFit];
	self.navigationItem.titleView = lbl;
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[button setImage:[UIImage imageNamed:@"doneButton51x31.png"] forState:UIControlStateNormal];
	[button addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
	button.frame = CGRectMake(0, 0, 51, 31);

	UIBarButtonItem *bbi = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
	self.navigationItem.rightBarButtonItem = bbi;
	self.navigationItem.hidesBackButton = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
	[dataHelper release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	}
	return YES;
}

#pragma - user actions

- (IBAction)done:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}


#pragma  mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;

	if (!indexPath.section)
	{
		static NSString *CellIdentifier = @"Cell";
		
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if (!cell)
		{
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			[cell.contentView addSubview:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"addCustomTopics320x44.png"]] autorelease]];
		}
	}
	else
	{
		
	}
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return !section ? 1 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return !indexPath.section ? 44.0 : 200.0;
}

#pragma  mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma - load up entries for  home screen

#pragma mark - DataHelper delegate

- (void)dataReceivedWith:(NSInteger)identifier andData:(NSData*)data andStatus:(NSInteger)status
{
	if (identifier == 1000 && data.length)
	{
		NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		self.entries = [[[json JSONValue] objectForKey:@"value"] objectForKey:@"items"];
		[json release];
		[tableView reloadData];
	}
}

- (void)dataReceived:(NSInteger)identifier withStatus:(NSInteger)status
{
	// MUST be images we need a refesh
	[tableView reloadData];
}

- (void)redirectReceived:(NSInteger)identifier withURL:(NSString*)url
{
}

- (void)errorReceived:(NSInteger)identifier withError:(NSError*)error
{
}

@end
