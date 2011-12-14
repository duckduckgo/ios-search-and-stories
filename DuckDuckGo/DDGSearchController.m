//
//  DDGSearchController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DDGSearchController.h"
#import "NSString+SBJSON.h"

@implementation DDGSearchController

@synthesize loadedCell;
@synthesize search;
@synthesize searchHandler;
@synthesize searchButton;
@synthesize state;

@synthesize serverRequest;
@synthesize serverData;
@synthesize serverConnection;

@synthesize serverCache;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent
{
	self = [super initWithNibName:nibNameOrNil bundle:nil];
	if (self)
	{
		[parent addSubview:self.view];
		kbRect = CGRectZero;
		
		self.serverData = [NSMutableData dataWithCapacity:8192];
		self.serverRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://duckduckgo.com"]
													 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
												 timeoutInterval:30.0];
		
		NSLog(@"HEADERS: %@", [serverRequest allHTTPHeaderFields]);
		[serverRequest setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
		
		NSLog(@"HEADERS: %@", [serverRequest allHTTPHeaderFields]);
		self.serverCache = [NSMutableDictionary dictionaryWithCapacity:8];

		dataHelper = [[DataHelper alloc] initWithDelegate:self];
	}
	return self;
}

- (void)dealloc
{
	[dataHelper release];
	self.serverData = nil;
	self.serverRequest = nil;
	if (serverConnection)
		[serverConnection cancel];
	self.serverConnection = nil;
	self.serverCache = nil;
	
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

//
// SAMPLE URL -- http://va-l3.duckduckgo.com:6767/face/suggest/?q=
//

- (NSArray*)currentResultForItem:(NSUInteger)item
{
	return [serverCache objectForKey:[NSNumber numberWithUnsignedInteger:item]];
}

- (void)cacheCurrentResult:(NSArray*)result forItem:(NSUInteger)item
{
	[serverCache setObject:result forKey:[NSNumber numberWithUnsignedInteger:item]];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (serverConnection)
	{
		[serverConnection cancel];
		self.serverConnection = nil;
	}

	NSUInteger lengthLeft = [textField.text length] - range.length + [string length];
	
	if (!lengthLeft)
		// going to NO characters
		[self autoCompleteReveal:NO];
	else if (![textField.text length] && lengthLeft)
		// going from NO characters to something
		[self autoCompleteReveal:YES];
	
	if (lengthLeft && lengthLeft < [textField.text length])
	{
		// destroying characters
		// this means we use a cached result
		if (lengthLeft < [serverCache count])
		{
			// keep the cache trimmed to a max of number of characters
			NSUInteger maxLen = [serverCache count];
			for (NSUInteger l = lengthLeft + 1; l <= maxLen; ++l)
			{
				NSNumber *n = [NSNumber numberWithUnsignedInteger:l];
				if ([serverCache objectForKey:n])
					[serverCache removeObjectForKey:n];
			}
		}
		[tableView reloadData];
	}
	else if (lengthLeft)
	{
		// we have replaced or added characters
		// time to server up
		NSString *willBecome;
		if (!range.length)
			willBecome = textField.text;
		else
			willBecome = [textField.text substringWithRange:range];
		
		if (![willBecome length])
			willBecome = @"";
		willBecome = [willBecome stringByAppendingString:string ? string : @""];
		NSString *surl = [@"http://va-l3.duckduckgo.com:6767/face/suggest/?q=" stringByAppendingString:willBecome];
		serverRequest.URL = [NSURL URLWithString:[surl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		self.serverConnection = [NSURLConnection connectionWithRequest:serverRequest delegate:self];
//		NSLog (@"URL: %@", surl);
	}
	else if (!lengthLeft)
	{
		// stay slim and trim in memory :)
		[serverCache removeAllObjects];
	}
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	[self autoCompleteReveal:NO];
	[serverCache removeAllObjects];
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
	return [[self currentResultForItem:[serverCache count]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	UIImageView *iv;
    if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
		cell.textLabel.textColor = [UIColor darkGrayColor];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		cell.imageView.image = [UIImage imageNamed:@"spacer44x44.png"];
		
		iv = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
		iv.tag = 100;
		iv.contentMode = UIViewContentModeScaleAspectFit;
		iv.backgroundColor = [UIColor whiteColor];
		[cell.contentView addSubview:iv];
		[iv release];
    }
    NSArray *items = [self currentResultForItem:[serverCache count]];
	NSDictionary *item = [items objectAtIndex:indexPath.row];
	
    // Configure the cell...
	cell.textLabel.text = [item objectForKey:@"phrase"];
	cell.detailTextLabel.text = [item objectForKey:@"snippet"];

	iv = (UIImageView *)[cell.contentView viewWithTag:100];
	
	iv.backgroundColor = [UIColor whiteColor];
	iv.image = [UIImage imageWithData:[dataHelper retrieve:[item objectForKey:@"image"] 
													 store:kCacheStoreIndexImages 
													  name:[NSString stringWithFormat:@"%08x", [[item objectForKey:@"image"] hash]]
												returnData:YES
												identifier:0]];    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = [self currentResultForItem:[serverCache count]];
	NSDictionary *item = [items objectAtIndex:indexPath.row];
	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
	
	[searchHandler actionTaken:[NSDictionary dictionaryWithObjectsAndKeys:@"web", @"action",  [item objectForKey:@"phrase"], @"searchTerm", nil]];
}

#pragma mark - auto completion server connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
	[serverData setLength:0]; 
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[serverData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[serverData setLength:0]; 
	self.serverConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// we have a complete data file for cacheing
	if (serverData.length)
	{
		NSString *query = [[[connection.originalRequest.URL.query componentsSeparatedByString:@"="] objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//		NSLog(@"QUERY:[%@]", query);
		NSString *json = [[NSString alloc] initWithData:serverData encoding:NSUTF8StringEncoding];
		NSArray *result = [json JSONValue];
		[self cacheCurrentResult:result forItem:[query length]];
		[json release];
		[tableView reloadData];
	}
	self.serverConnection = nil;
}

#pragma - DataHelper delegate

- (void)dataReceivedWith:(NSInteger)identifier andData:(NSData*)data andStatus:(NSInteger)status
{
}

- (void)dataReceived:(NSInteger)identifier withStatus:(NSInteger)status
{
	// no matter what is coming back, we need a refesh
	[tableView reloadData];
}

- (void)redirectReceived:(NSInteger)identifier withURL:(NSString*)url
{
}

- (void)errorReceived:(NSInteger)identifier withError:(NSError*)error
{
}


@end
