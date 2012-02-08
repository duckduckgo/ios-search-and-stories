//
//  DDGSearchController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchController.h"
#import "SBJson.h"
#import "AFNetworking.h"

static NSString *const sBaseSuggestionServerURL = @"http://swass.duckduckgo.com:6767/face/suggest/?q=";

@implementation DDGSearchController

@synthesize loadedCell;
@synthesize search;
@synthesize searchHandler;
@synthesize searchButton;
@synthesize state;

@synthesize serverRequest;
@synthesize serverCache;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent
{
	self = [super initWithNibName:nibNameOrNil bundle:nil];
	if (self)
	{
		[parent addSubview:self.view];
		kbRect = CGRectZero;
		
		self.serverRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://duckduckgo.com"]
													 cachePolicy:NSURLRequestUseProtocolCachePolicy
												 timeoutInterval:10.0];
		
		NSLog(@"HEADERS: %@", [serverRequest allHTTPHeaderFields]);
		[serverRequest setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
		[serverRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
		[serverRequest setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Accept"];
		
		NSLog(@"HEADERS: %@", [serverRequest allHTTPHeaderFields]);
		
		search.placeholder = NSLocalizedString (@"SearchPlaceholder", nil);
        
        suggestionsCache = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	self.serverRequest = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.view removeFromSuperview];
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
	search.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spacer8x16.png"]];
	
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

- (IBAction)searchButtonAction:(UIButton*)sender
{
	[search resignFirstResponder];
    
    // if it's showing, hide it.
    [self autoCompleteReveal:NO];
    
	[searchHandler loadButton];
}

- (void)switchModeTo:(enum eSearchState)searchState
{
	state = searchState;
}

#pragma mark - Omnibar methods

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
		rect.size.height = 46.0;
	}
	[UIView animateWithDuration:0.25 animations:^
     {
         self.view.frame = rect;
     }];
}

-(void)updateBarWithURL:(NSURL *)url {
    
    // parse URL query components
    NSArray *queryComponentsArray = [[url query] componentsSeparatedByString:@"&"];
    NSMutableDictionary *queryComponents = [[NSMutableDictionary alloc] init];
    for(NSString *queryComponent in queryComponentsArray) {
        NSArray *parameter = [queryComponent componentsSeparatedByString:@"="];
        if(parameter.count > 1)
            [queryComponents setObject:[parameter objectAtIndex:1] forKey:[parameter objectAtIndex:0]];
    }

    // check whether we have a DDG search URL
    if([[url host] isEqualToString:@"duckduckgo.com"] && [[url path] isEqualToString:@"/"] && [queryComponents objectForKey:@"q"]) {
        // yep! extract the search query...
        NSString *query = [queryComponents objectForKey:@"q"];
        query = [query stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
        query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        search.text = query;
    } else {
        // no, just a plain old URL.
        search.text = [url absoluteString];
    }
}

-(NSString *)validURLStringFromString:(NSString *)urlString {
    // check whether the entered text is a URL or a search query
    NSURL *url = [NSURL URLWithString:urlString];
    if(url && url.scheme) {
        // it has a scheme, so it's probably a valid URL
        return urlString;
    } else {
        // check whether adding a scheme makes it a valid URL
        NSString *urlStringWithSchema = [NSString stringWithFormat:@"http://%@",urlString];
        url = [NSURL URLWithString:urlStringWithSchema];
        
        if(url && url.host && [url.host rangeOfString:@"."].location != NSNotFound) {
            // it has a host with a dot ("xyz.com"), so it's probably a URL
            return urlStringWithSchema;
        } else {
            // it can't be made into a valid URL
            return nil;
        }
    }
}

#pragma  mark - Handle the text field input

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if([textField.text isEqualToString:[self validURLStringFromString:textField.text]]) {
        // we're definitely editing a URL, don't bother with autocomplete.
        [self autoCompleteReveal:NO];
        return YES;
    }
    
    // figure out what the new search string is
    NSString *newSearchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSUInteger newLength = newSearchText.length;
    
	if (!newLength) {
		// going to NO characters
		[self autoCompleteReveal:NO];
	} else if (![textField.text length] && newLength) {
		// going from NO characters to something
		[self autoCompleteReveal:YES];
	}
    
	if (newLength) {
		// load our new best cached result, and download new autocomplete suggestions.
        [self downloadSuggestionsForSearchText:newSearchText];
        [tableView reloadData];
	} else {
        // newLength==0; clear the suggestions cache and reload
        [suggestionsCache removeAllObjects];
        [tableView reloadData];
	}
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [suggestionsCache removeAllObjects];
	[self autoCompleteReveal:NO];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if ([textField.text length])
	{
		// if in search field mode, then reveal autocomplete.
        if(![self validURLStringFromString:textField.text])
            [self autoCompleteReveal:YES];

        [self downloadSuggestionsForSearchText:textField.text];
	}
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
	
    NSString *urlString;
    if((urlString = [self validURLStringFromString:search.text])) {
        [searchHandler loadURL:urlString];
    } else {
        // it isn't a URL, so treat it as a search query.
        [searchHandler loadQuery:([search.text length] ? search.text : nil)];
    }
            
	return YES;
}


#pragma mark - Suggestion cache management

-(NSArray *)currentSuggestions {
    NSString *searchText = search.text;
    NSString *bestMatch = nil;
    
    for(NSString *suggestionText in suggestionsCache) {
        if([searchText hasPrefix:suggestionText] && (suggestionText.length > bestMatch.length))
            bestMatch = suggestionText;
    }
    
    return (bestMatch ? [suggestionsCache objectForKey:bestMatch] : [NSArray array]);
}

-(void)downloadSuggestionsForSearchText:(NSString *)searchText {
        
    NSString *urlString = [sBaseSuggestionServerURL stringByAppendingString:[searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    serverRequest.URL = [NSURL URLWithString:urlString];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:serverRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [suggestionsCache setObject:JSON forKey:searchText];
        [tableView reloadData];
        
    } failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@",[error userInfo]);
    }];
    [operation start];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self currentSuggestions] count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	UIImageView *iv;
    if (cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
		cell.textLabel.textColor = [UIColor darkGrayColor];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		cell.imageView.image = [UIImage imageNamed:@"spacer44x44.png"];
		
		iv = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
		iv.tag = 100;
		iv.contentMode = UIViewContentModeScaleAspectFit;
		iv.backgroundColor = [UIColor whiteColor];
		[cell.contentView addSubview:iv];
    }

    NSArray *suggestions = [self currentSuggestions];
    if(suggestions.count <= indexPath.row)
        return cell; // this entry no longer exists; return empty cell. the tableview will be reloading very soon anyway.
    
	NSDictionary *item = [suggestions objectAtIndex:indexPath.row];
    
    // Configure the cell...
	cell.textLabel.text = [item objectForKey:ksDDGSearchControllerServerKeyPhrase];
	cell.detailTextLabel.text = [item objectForKey:ksDDGSearchControllerServerKeySnippet];

	iv = (UIImageView *)[cell.contentView viewWithTag:100];
	
	iv.backgroundColor = [UIColor whiteColor];
    [iv setImageWithURL:[NSURL URLWithString:[item objectForKey:ksDDGSearchControllerServerKeyImage]]];

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *item = [[self currentSuggestions] objectAtIndex:indexPath.row];
	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
	
	[search resignFirstResponder];
	[self autoCompleteReveal:NO];
    
    [searchHandler loadQuery:[item objectForKey:ksDDGSearchControllerServerKeyPhrase]];
}

@end

NSString *const ksDDGSearchControllerServerKeySnippet = @"snippet"; 
NSString *const ksDDGSearchControllerServerKeyPhrase = @"phrase"; 
NSString *const ksDDGSearchControllerServerKeyImage = @"image"; 

