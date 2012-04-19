//
//  DDGSearchController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchController.h"
#import "DDGAutocompleteServerKeys.h"
#import "DDGSearchSuggestionsProvider.h"
#import "DDGSearchHistoryProvider.h"
#import "AFNetworking.h"

@interface DDGSearchController (Private)

-(void)revealBackground:(BOOL)reveal animated:(BOOL)animated;
-(void)revealAutocomplete:(BOOL)reveal;
-(void)cancelInputAfterDelay;
-(void)cancelInput;
-(void)loadQueryOrURL:(NSString *)queryOrURL;

@end

@implementation DDGSearchController

@synthesize loadedCell;
@synthesize tableView, searchField, searchButton, background;
@synthesize searchHandler, state;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent
{
	self = [super initWithNibName:nibNameOrNil bundle:nil];
	if (self) {

        // expand the view's frame to fill the width of the screen
        CGRect frame = self.view.frame;
        frame.size.width = [UIScreen mainScreen].applicationFrame.size.width;
        self.view.frame = frame;

		[parent addSubview:self.view];
		keyboardRect = CGRectZero;
		                
        searchField.placeholder = NSLocalizedString(@"SearchPlaceholder", nil);
        
        stopOrReloadButton = [[UIButton alloc] init];
        stopOrReloadButton.frame = CGRectMake(0, 0, 31, 31);
        [stopOrReloadButton addTarget:self action:@selector(stopOrReloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        searchField.rightView = stopOrReloadButton;
        
        suggestionsProvider = [[DDGSearchSuggestionsProvider alloc] init];
        historyProvider = [[DDGSearchHistoryProvider alloc] init];
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

	searchField.rightViewMode = UITextFieldViewModeAlways;
	searchField.leftViewMode = UITextFieldViewModeAlways;
	searchField.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spacer8x16.png"]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInputAfterDelay)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    [self revealBackground:NO animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Updating keyboardRect

- (void)keyboardWillShow:(NSNotification*)notification
{
	keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [self.view convertRect:keyboardRect toView:nil];
    
    if([searchField isFirstResponder]) {
        // user just started editing the search box
        [self revealBackground:YES animated:YES];
        
        if ([searchField.text length])
        {            
            [suggestionsProvider downloadSuggestionsForSearchText:searchField.text success:^{
                [tableView reloadData];
            }];
        }
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
	keyboardRect = CGRectZero;
}


#pragma  mark - Interactions with search handler

- (IBAction)leftButtonPressed:(UIButton*)sender {
	[searchField resignFirstResponder];
    
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

-(void)loadQueryOrURL:(NSString *)queryOrURL {
    [historyProvider logHistoryItem:queryOrURL];
    [searchHandler loadQueryOrURL:queryOrURL];
}

#pragma mark - Helpers

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

// mostly for clarity
-(BOOL)isQuery:(NSString *)queryOrURL {
    return ![self validURLStringFromString:queryOrURL];
}

#pragma mark - Omnibar management methods

- (void)revealBackground:(BOOL)reveal animated:(BOOL)animated {
    CGSize screenSize = self.view.superview.frame.size;
	CGRect rect = self.view.frame;
	if (reveal) {
		rect.size.height = screenSize.height - keyboardRect.size.height;
    } else {
		// clip to search entry height
		rect.size.height = 46.0;
    }
    [self revealAutocomplete:NO]; // if we're revealing, we'll show it again after the animation
    
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
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.view.frame = rect;
        if(reveal)
            [self revealAutocomplete:YES];
    });
    
    [UIView animateWithDuration:(animated ? 0.25 : 0.0) animations:^{
        background.alpha = (reveal ? 1.0 : 0.0);
    }];
}

-(void)revealAutocomplete:(BOOL)reveal {
    tableView.hidden = !reveal;
}

// cancelInput destroys the table view instantly, which causes issues when a cell is tapped and that needs to be processed before destroying the table view, so we wait for a tiny bit first.
-(void)cancelInputAfterDelay {
    [self performSelector:@selector(cancelInput) withObject:nil afterDelay:0.01];
}

-(void)cancelInput {
    [searchField resignFirstResponder];
    searchField.text = oldSearchText;
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
    if([[url host] isEqualToString:@"duckduckgo.com"]) {
        if([[url path] isEqualToString:@"/"] && [queryComponents objectForKey:@"q"]) {
            // yep! extract the search query...
            NSString *query = [queryComponents objectForKey:@"q"];
            query = [query stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
            query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            searchField.text = query;
        } else if(![[url pathExtension] isEqualToString:@"html"]) {
            // article page
            NSString *query = [url path];
            query = [query substringFromIndex:1]; // strip the leading '/' in the URL
            query = [query stringByReplacingOccurrencesOfString:@"_" withString:@"%20"];
            query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            searchField.text = query;
        } else {
            // a URL on DDG.com, but not a search query
            searchField.text = [url absoluteString];
        }
    } else {
        // no, just a plain old URL.
        searchField.text = [url absoluteString];
    }
}

-(void)resetOmnibar {
    searchField.text = @"";
    [tableView reloadData];
}

#pragma  mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // figure out what the new search string is
    NSString *newSearchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if([newSearchText isEqualToString:[self validURLStringFromString:newSearchText]]) {
        // we're definitely editing a URL, don't bother with autocomplete.
        return YES;
    }
        
	if(newSearchText.length) {
		// load our new best cached result, and download new autocomplete suggestions.
        [suggestionsProvider downloadSuggestionsForSearchText:newSearchText success:^{
            [tableView reloadData];
        }];
	} else {
        // search text is blank; clear the suggestions cache, reload, and hide the table
        [suggestionsProvider emptyCache];
    }
    // either way, reload the table view.
    [tableView reloadData];
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [suggestionsProvider emptyCache];
    [tableView reloadData];
    
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
	
    [self loadQueryOrURL:([searchField.text length] ? searchField.text : nil)];

    oldSearchText = nil;
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
    return ([[suggestionsProvider suggestionsForSearchText:searchField.text] count] +
            [[historyProvider pastHistoryItemsForPrefix:searchField.text] count]);
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
		cell.backgroundView = [[UIView alloc] init];
        [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
        
		iv = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
		iv.tag = 100;
		iv.contentMode = UIViewContentModeScaleAspectFill;
		iv.backgroundColor = [UIColor whiteColor];
		[cell.contentView addSubview:iv];
    }

    NSArray *history = [historyProvider pastHistoryItemsForPrefix:searchField.text];
    NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:searchField.text];
    if((suggestions.count + history.count) <= indexPath.row)
        return cell; // this entry no longer exists; return empty cell. the tableview will be reloading very soon anyway.

    iv = (UIImageView *)[cell.contentView viewWithTag:100];
    iv.backgroundColor = [UIColor whiteColor];

    if(indexPath.row < history.count) {
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        cell.textLabel.text = [historyItem objectForKey:@"text"];
        cell.detailTextLabel.text = @"History item";
        [iv setImage:nil];
    } else {
     	NSDictionary *item = [suggestions objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [item objectForKey:ksDDGSearchControllerServerKeyPhrase];
        cell.detailTextLabel.text = [item objectForKey:ksDDGSearchControllerServerKeySnippet];
        
        if([item objectForKey:ksDDGSearchControllerServerKeyImage])
            [iv setImageWithURL:[NSURL URLWithString:[item objectForKey:ksDDGSearchControllerServerKeyImage]]];
        else
            [iv setImage:nil]; // wipe out any image that used to be there
   
    }    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *item = [[suggestionsProvider suggestionsForSearchText:searchField.text] objectAtIndex:indexPath.row];
	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
	
	[searchField resignFirstResponder];
    
    [self loadQueryOrURL:[item objectForKey:ksDDGSearchControllerServerKeyPhrase]];
}

@end
