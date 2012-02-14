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
@synthesize background;

@synthesize serverRequest;
@synthesize serverCache;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent
{
	self = [super initWithNibName:nibNameOrNil bundle:nil];
	if (self)
	{
		[parent addSubview:self.view];
		keyboardRect = CGRectZero;
		
		self.serverRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://duckduckgo.com"]
													 cachePolicy:NSURLRequestUseProtocolCachePolicy
												 timeoutInterval:10.0];
		
		[serverRequest setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
		[serverRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
		[serverRequest setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Accept"];
				
		search.placeholder = NSLocalizedString (@"SearchPlaceholder", nil);
        
        suggestionsCache = [[NSMutableDictionary alloc] init];
        
        stopOrReloadButton = [[UIButton alloc] init];
        stopOrReloadButton.frame = CGRectMake(0, 0, 31, 31);
        [stopOrReloadButton addTarget:self action:@selector(stopOrReloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        search.rightView = stopOrReloadButton;
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.view removeFromSuperview];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	search.rightViewMode = UITextFieldViewModeAlways;
	search.leftViewMode = UITextFieldViewModeAlways;
	search.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spacer8x16.png"]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInput)];
    [self.background addGestureRecognizer:gestureRecognizer];
    
    [self revealBackground:NO animated:NO];
    [self revealAutocomplete:NO];
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


#pragma mark - Updating keyboardRect

- (void)keyboardWillShow:(NSNotification*)notification
{
	keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [self.view convertRect:keyboardRect toView:nil];
    
    if([search isFirstResponder]) {
        // user just started editing the search box
        [self revealBackground:YES animated:YES];
        
        if ([search.text length])
        {
            // if in search field mode, then reveal autocomplete.
            if(![self validURLStringFromString:search.text])
                [self revealAutocomplete:YES];
            
            [self downloadSuggestionsForSearchText:search.text];
        }
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
	keyboardRect = CGRectZero;
}


#pragma  mark - Handle user actions

- (IBAction)leftButtonPressed:(UIButton*)sender {
	[search resignFirstResponder];
    
    // if it's showing, hide it.
    [self revealAutocomplete:NO];
    
	[searchHandler searchControllerLeftButtonPressed];
}


-(void)setState:(DDGSearchControllerState)searchControllerState {
	state = searchControllerState;
}

-(void)stopOrReloadButtonPressed {
    if([searchHandler respondsToSelector:@selector(searchControllerStopOrReloadButtonPressed)])
        [searchHandler performSelector:@selector(searchControllerStopOrReloadButtonPressed)];
}

-(void)webViewStartedLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
}

-(void)webViewFinishedLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];    
}


#pragma mark - Omnibar methods

- (void)revealBackground:(BOOL)reveal animated:(BOOL)animated {
	CGSize screenSize = self.view.superview.frame.size;
	CGRect rect = self.view.frame;
	if (reveal) {
		rect.size.height = screenSize.height - keyboardRect.size.height;
    } else {
		// clip to search entry height
		rect.size.height = 46.0;
        // if the autocomplete table is showing, we'll want to hide that first.
        [self revealAutocomplete:NO];
    }
    
    double animationDuration = (animated ? 0.25 : 0.0);
    

    // expand the frame to fullscreen for a moment so that the background looks like it's behind the keyboard, then adjust it to appropriate size once the animation completes.
    
    if(animated)
        self.view.frame = self.view.superview.bounds;
    
    [UIView animateWithDuration:0.0 delay:animationDuration 
                        options:(unsigned int)0 
                     animations:^{
                         self.view.frame = rect;
                     } 
                     completion:nil];
    
    [UIView animateWithDuration:(animated ? 0.25 : 0.0) animations:^{
        background.alpha = (reveal ? 1.0 : 0.0);
    }];
}

-(void)revealAutocomplete:(BOOL)reveal {
    tableView.hidden = !reveal;
}

-(void)cancelInput {
    [search resignFirstResponder];
    search.text = oldSearchText;
    oldSearchText = nil;
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
    // figure out what the new search string is
    NSString *newSearchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if([newSearchText isEqualToString:[self validURLStringFromString:newSearchText]]) {
        NSLog(@"%@ is a URL!!!",textField.text);
        // we're definitely editing a URL, don't bother with autocomplete.
        [self revealAutocomplete:NO];
        return YES;
    }
        
	if(newSearchText.length) {
		// load our new best cached result, and download new autocomplete suggestions.
        [self downloadSuggestionsForSearchText:newSearchText];
    	[self revealAutocomplete:YES];
	} else {
        // search text is blank; clear the suggestions cache, reload, and hide the table
        [suggestionsCache removeAllObjects];
        [self revealAutocomplete:NO];
    }
    // either way, reload the table view.
    [tableView reloadData];
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [suggestionsCache removeAllObjects];
	[self revealAutocomplete:NO];
    
	// save search text in case user cancels input without navigating somewhere
    if(!oldSearchText)
        oldSearchText = textField.text;
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // save search text in case user cancels input without navigating somewhere
    if(!oldSearchText)
        oldSearchText = textField.text;
    
    if(state==DDGSearchControllerStateWeb)
        textField.rightView = nil;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self revealBackground:NO animated:YES];
    
    if(state==DDGSearchControllerStateWeb)
        textField.rightView = stopOrReloadButton;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSString *s = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (![s length])
	{
		textField.text = nil;
		return NO;
	}
	[textField resignFirstResponder];
	[self revealAutocomplete:NO];
	
    NSString *urlString;
    if((urlString = [self validURLStringFromString:search.text])) {
        [searchHandler loadURL:urlString];
    } else {
        // it isn't a URL, so treat it as a search query.
        [searchHandler loadQuery:([search.text length] ? search.text : nil)];
    }
    
    oldSearchText = nil;
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
    if([item objectForKey:ksDDGSearchControllerServerKeyImage])
        [iv setImageWithURL:[NSURL URLWithString:[item objectForKey:ksDDGSearchControllerServerKeyImage]]];
    else
        [iv setImage:nil]; // wipe out any image that used to be there
    
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
	[self revealAutocomplete:NO];
    
    [searchHandler loadQuery:[item objectForKey:ksDDGSearchControllerServerKeyPhrase]];
}

@end

NSString *const ksDDGSearchControllerServerKeySnippet = @"snippet"; 
NSString *const ksDDGSearchControllerServerKeyPhrase = @"phrase"; 
NSString *const ksDDGSearchControllerServerKeyImage = @"image"; 

