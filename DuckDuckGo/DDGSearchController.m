//
//  DDGSearchController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchController.h"
#import "DDGSearchSuggestionsProvider.h"
#import "DDGSearchHistoryProvider.h"
#import "AFNetworking.h"
#import "DDGAddressBarTextField.h"
#import "DDGBangsProvider.h"
#import "DDGInputAccessoryView.h"

@interface DDGSearchController (Private)

-(void)revealBackground:(BOOL)reveal animated:(BOOL)animated;
-(void)revealAutocomplete:(BOOL)reveal;
-(void)cancelInputAfterDelay;
-(void)cancelInput;
-(void)loadQueryOrURL:(NSString *)queryOrURL;
-(void)searchFieldDidChange:(id)sender;
-(void)updateBarProgress;
-(void)createInputAccessory;
-(void)bangButtonPressed;
-(void)loadSuggestionsForBang:(NSString *)bang;
-(void)bangAutocompleteButtonPressed:(UIButton *)sender;
-(void)clearBangSuggestions;
-(void)reloadSuggestions;

@end

@implementation DDGSearchController

@synthesize loadedCell;
@synthesize tableView, searchField, searchButton, background;
@synthesize searchHandler, state;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent
{
	self = [super initWithNibName:nibNameOrNil bundle:nil];
    // the code below happens after viewDidLoad
    
	if (self) {
        // expand the view's frame to fill the width of the screen
        CGRect frame = self.view.frame;
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            frame.size.width = parent.bounds.size.width;
        else
            frame.size.width = parent.bounds.size.height;
        
        self.view.frame = frame;

		[parent addSubview:self.view];
        [self revealBackground:NO animated:NO];

        keyboardRect = CGRectZero;
		                
        searchField.placeholder = NSLocalizedString(@"SearchPlaceholder", nil);
        [searchField addTarget:self action:@selector(searchFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

        stopOrReloadButton = [[UIButton alloc] init];
        stopOrReloadButton.frame = CGRectMake(0, 0, 31, 31);
        [stopOrReloadButton addTarget:self action:@selector(stopOrReloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        searchField.rightView = stopOrReloadButton;
        
        suggestionsProvider = [[DDGSearchSuggestionsProvider alloc] init];
        historyProvider = [DDGSearchHistoryProvider sharedInstance];
        
        [self createInputAccessory];
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
    
    // TODO (WHEN I GET BACK): MAKE DISCLOSURE BUTTON TAPS NOT TRIGGER CANCELINPUT (see those lines below).
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInputAfterDelay)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    CGRect inputAccessoryFrame = inputAccessory.frame;
    CGRect scrollViewFrame = [inputAccessory viewWithTag:102].frame;

    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && UIInterfaceOrientationIsPortrait(currentOrientation)) {
        inputAccessoryFrame.size.width += 160;
        scrollViewFrame.size.width += 160;
    } else if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation) && UIInterfaceOrientationIsLandscape(currentOrientation)) {
        inputAccessoryFrame.size.width -= 160;
        scrollViewFrame.size.width -= 160;
    }
    
    inputAccessory.frame = inputAccessoryFrame;
    [inputAccessory viewWithTag:102].frame = scrollViewFrame;
}


#pragma mark - Updating keyboardRect

- (void)keyboardWillShow:(NSNotification*)notification
{
	keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [self.view convertRect:keyboardRect toView:nil];
    
    if([searchField isFirstResponder]) {
        // user just started editing the search box
        [self revealBackground:YES animated:YES];
        [self reloadSuggestions];
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
    // stop the current timer (if there is one), then set a new one to update the progress
    [loadingTimer invalidate];
    // target: 40fps
    // TODO: figure out what the optimal framerate for this animation is (and tune it for speed, if necessary)
    loadingBeginTime = [NSDate date];
    loadingTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/40.0) target:self selector:@selector(updateBarProgress) userInfo:nil repeats:YES];
}

-(void)webViewFinishedLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];    
    
    // clear out the search field progress
    [loadingTimer invalidate];
    [searchField setProgress:0];
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
        inputAccessory.frame = CGRectMake(0, 0, 0, 46);
        inputAccessory.hidden = YES;
    }
    [self revealAutocomplete:NO]; // if we're revealing, we'll show it again after the animation
    
    double animationDuration = (animated ? 0.25 : 0.0);
    
    // expand the frame to fullscreen for a moment so that the background looks like it's behind the keyboard, then adjust it to appropriate size once the animation completes.
    
    if(animated)
        self.view.frame = self.view.superview.bounds;

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.view.frame = rect;
        if(reveal) {
            [self revealAutocomplete:YES];
            CGRect bangBarFrame = inputAccessory.frame;
            bangBarFrame.origin.y = rect.size.height - 46.0;
            bangBarFrame.size.width = rect.size.width;
            inputAccessory.frame = bangBarFrame;
            inputAccessory.hidden = NO;
        }
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
    if(!barUpdated) {
        searchField.text = oldSearchText;
        oldSearchText = nil;
    }
}

-(void)updateBarWithURL:(NSURL *)url {
    barUpdated = YES;
    
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

-(void)updateBarProgress {
    NSTimeInterval loadingTime = (-1.0)*[loadingBeginTime timeIntervalSinceNow];
    CGFloat avgLoadingTime = 2; // 80% by 2 seconds
    CGFloat progress = (1-1/((4.0/avgLoadingTime)*loadingTime+1)); // have the progress asymptotically approach 1 as time goes on
    [searchField setProgress:progress];
}

#pragma mark - Input accesory

-(void)createInputAccessory {
    inputAccessory = [[DDGInputAccessoryView alloc] initWithFrame:CGRectMake(0, 0, 0, 46)];
    inputAccessory.hidden = YES;
    UIButton *bangButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // TODO: *important* bang_button.png and empty_bang_button.png are currently stolen from the iPhone keyboard images; replace them with custom graphics before release.
    [bangButton setBackgroundImage:[UIImage imageNamed:@"bang_button.png"] forState:UIControlStateNormal];
    bangButton.frame = CGRectMake(0, 0, 46, 46);
    [bangButton addTarget:self action:@selector(bangButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessory addSubview:bangButton];
    
    // get screen width so we can size the scroll view appropriately
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat width;
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        width = screenRect.size.height;
    else
        width = screenRect.size.width;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(46, 0, width-46, 46)];
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.contentSize = CGSizeMake(0, 46);
    scrollView.tag = 102;
    scrollView.hidden = YES;
    [inputAccessory addSubview:scrollView];
    
    [self.view addSubview:inputAccessory];
}

-(void)bangButtonPressed {
    [searchField setText:[NSString stringWithFormat:@"%@!",searchField.text]];
}

-(void)bangAutocompleteButtonPressed:(UIButton *)sender {
    [searchField setText:[searchField.text stringByReplacingCharactersInRange:currentWordRange withString:sender.titleLabel.text]];
}

-(void)loadSuggestionsForBang:(NSString *)bang {
    UIScrollView *scrollView = (UIScrollView *)[inputAccessory viewWithTag:102];
    
    if([bang isEqualToString:@"!"]) return;
    NSArray *suggestions = [DDGBangsProvider bangsWithPrefix:bang];
    if(suggestions.count > 0)
        scrollView.hidden = NO;
    UIImage *backgroundImg = [[UIImage imageNamed:@"empty_bang_button.png"] stretchableImageWithLeftCapWidth:7.0 topCapHeight:0];

    for(NSDictionary *suggestionDict in suggestions) {
        NSString *suggestion = [suggestionDict objectForKey:@"name"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setTitle:suggestion forState:UIControlStateNormal];
        [button addTarget:self action:@selector(bangAutocompleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        CGSize titleSize = [suggestion sizeWithFont:button.titleLabel.font];
        [button setFrame:CGRectMake(scrollView.contentSize.width, 0, (titleSize.width > 30 ? titleSize.width + 20 : 50), 46)];
        [button setBackgroundImage:backgroundImg forState:UIControlStateNormal];
        scrollView.contentSize = CGSizeMake(scrollView.contentSize.width + button.frame.size.width, 46);
        [scrollView addSubview:button];
    }
}

-(void)clearBangSuggestions {
    UIScrollView *scrollView = (UIScrollView *)[inputAccessory viewWithTag:102];
    
    scrollView.contentSize = CGSizeMake(0, 46);
    for(UIView *subview in scrollView.subviews) {
        [subview removeFromSuperview];
    }
    scrollView.hidden = YES;
}

#pragma mark - Search suggestions

- (void)reloadSuggestions {
    NSString *newSearchText = searchField.text;
    
    if([newSearchText isEqualToString:[self validURLStringFromString:newSearchText]]) {
        // we're definitely editing a URL, don't bother with autocomplete.
        return;
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
}

#pragma mark - Text field delegate

-(void)searchFieldDidChange:(id)sender {
    [self reloadSuggestions];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if(newString.length == 0) {
        currentWordRange = NSMakeRange(NSNotFound, 0);
        [self clearBangSuggestions];
        return YES; // there's nothing we can do with an empty string
    }
    
    // find word beginning
    int wordBeginning;
    for(wordBeginning = range.location+string.length;wordBeginning>=0;wordBeginning--) {
        if(wordBeginning == 0 || [newString characterAtIndex:wordBeginning-1] == ' ')
            break;
    }

    // find word end
    int wordEnd;
    for(wordEnd = wordBeginning;wordEnd<newString.length;wordEnd++) {
        if(wordEnd == newString.length || [newString characterAtIndex:wordEnd] == ' ')
            break;
    }
    
    currentWordRange = NSMakeRange(wordBeginning, wordEnd-wordBeginning);
    
    NSString *currentWord;
    if(currentWordRange.length == 0)
        currentWord = @"";
    else
        currentWord = [newString substringWithRange:currentWordRange];
    
    [self clearBangSuggestions];
    if(currentWord.length > 0 && [currentWord characterAtIndex:0]=='!') {
        [self loadSuggestionsForBang:currentWord];
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	// save search text in case user cancels input without navigating somewhere
    if(!oldSearchText)
        oldSearchText = textField.text;
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // clear out the search field progress
    [loadingTimer invalidate];
    [searchField setProgress:0];
    
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // save search text in case user cancels input without navigating somewhere
    if(!oldSearchText)
        oldSearchText = textField.text;
    barUpdated = NO;
    
    textField.rightView = nil;
    [self reloadSuggestions];
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
    static NSString *suggestionCellID = @"SCell";
    static NSString *historyCellID = @"HCell";
    static NSString *emptyCellID = @"ECell";
    
    NSArray *history = [historyProvider pastHistoryItemsForPrefix:searchField.text];
    NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:searchField.text];
    if((suggestions.count + history.count) <= indexPath.row) {
        // this entry no longer exists; return empty cell. the tableview will be reloading very soon anyway.
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:emptyCellID];
        if(cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:emptyCellID];
        return cell;
    }
    
    UITableViewCell *cell;
    if(indexPath.row < history.count) {
        // dequeue or initialize a history cell
        cell = [tv dequeueReusableCellWithIdentifier:historyCellID];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
        }
        
        // fill the appropriate data into the history cell
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        cell.textLabel.text = [historyItem objectForKey:@"text"];
        //cell.detailTextLabel.text = @"History item";
        
    } else {
        // dequeue or initialize a suggestion cell
        cell = [tv dequeueReusableCellWithIdentifier:suggestionCellID];
        UIImageView *iv;
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:suggestionCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.imageView.image = [UIImage imageNamed:@"spacer44x44.png"];
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
            
            iv = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
            iv.tag = 100;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            iv.backgroundColor = [UIColor whiteColor];
            [cell.contentView addSubview:iv];
        } else {
            iv = (UIImageView *)[cell.contentView viewWithTag:100];
        }
        
     	NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row - history.count];
        
        cell.textLabel.text = [suggestionItem objectForKey:@"phrase"];
        cell.detailTextLabel.text = [suggestionItem objectForKey:@"snippet"];
        
        if([suggestionItem objectForKey:@"image"])
            [iv setImageWithURL:[NSURL URLWithString:[suggestionItem objectForKey:@"image"]]];
        else
            [iv setImage:nil]; // wipe out any image that used to be there
   
        if([suggestionItem objectForKey:@"officialsite"])
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
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
    NSArray *history = [historyProvider pastHistoryItemsForPrefix:searchField.text];
    NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:searchField.text];
    if(indexPath.row < history.count) {
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        [self loadQueryOrURL:[historyItem objectForKey:@"text"]];        
    } else {
     	NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row - history.count];
        [self loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];        
    }
    	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
	[searchField resignFirstResponder];
}

- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSArray *history = [historyProvider pastHistoryItemsForPrefix:searchField.text];
    NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:searchField.text];
    if(indexPath.row < history.count) {
        // this should never happen
        NSLog(@"??? Accessory button tapped for a history item");
    } else {
     	NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row - history.count];
        [self loadQueryOrURL:[suggestionItem objectForKey:@"officialsite"]];        
        [tv deselectRowAtIndexPath:indexPath animated:YES];
        [searchField resignFirstResponder];
    }
}

@end
