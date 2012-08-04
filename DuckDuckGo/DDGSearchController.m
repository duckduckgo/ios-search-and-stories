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
#import "DDGBookmarksViewController.h"

@implementation DDGSearchController
static NSString *bookmarksCellID = @"BCell";
static NSString *suggestionCellID = @"SCell";
static NSString *historyCellID = @"HCell";
static NSString *emptyCellID = @"ECell";

- (id)initWithNibName:(NSString *)nibNameOrNil containerViewController:(UIViewController *)container {
	self = [super initWithNibName:nibNameOrNil bundle:nil];
    // the code below happens after viewDidLoad
    
	if (self) {
        [container addChildViewController:self];
		[container.view addSubview:self.view];
        [self didMoveToParentViewController:container];
        
        // expand the view's frame to fill the width of the screen
        CGRect frame = self.view.frame;
        if(PORTRAIT)
            frame.size.width = [UIScreen mainScreen].bounds.size.width;
        else
            frame.size.width = [UIScreen mainScreen].bounds.size.height;
        
        self.view.frame = frame;

        [self revealBackground:NO animated:NO];

        keyboardRect = CGRectZero;
		
        _searchField.placeholder = NSLocalizedString(@"SearchPlaceholder", nil);
        [_searchField addTarget:self action:@selector(searchFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

        stopOrReloadButton = [[UIButton alloc] init];
        stopOrReloadButton.frame = CGRectMake(0, 0, 31, 31);
        [stopOrReloadButton addTarget:self action:@selector(stopOrReloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _searchField.rightView = stopOrReloadButton;
        
        suggestionsProvider = [[DDGSearchSuggestionsProvider alloc] init];
        historyProvider = [DDGSearchHistoryProvider sharedProvider];
        
        unusedBangButtons = [[NSMutableArray alloc] initWithCapacity:50];
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

	_searchField.rightViewMode = UITextFieldViewModeAlways;
	_searchField.leftViewMode = UITextFieldViewModeAlways;
	_searchField.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spacer8x16.png"]];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInputAfterDelay)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
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
    
    if([_searchField isFirstResponder]) {
        // if child view controller is visible, don't reveal background because background is already revealed
        if(!_childViewControllerVisible)
            [self revealBackground:YES animated:YES];
        else
            self.childViewControllerVisible = NO;
        [self reloadSuggestions];
    }
}

#pragma mark - Action sheet

- (IBAction)actionButtonPressed:(id)sender {
    if([_searchHandler respondsToSelector:@selector(searchControllerActionButtonPressed)])
        [_searchHandler searchControllerActionButtonPressed];
}

#pragma  mark - Interactions with search handler

- (IBAction)leftButtonPressed:(UIButton*)sender {
	[_searchField resignFirstResponder];
	[_searchHandler searchControllerLeftButtonPressed];
}

-(void)setState:(DDGSearchControllerState)searchControllerState {
	_state = searchControllerState;
    
    if(_state == DDGSearchControllerStateHome)
        [_searchButton setImage:[UIImage imageNamed:@"settings_button.png"] forState:UIControlStateNormal];
    else if (_state == DDGSearchControllerStateWeb) {
        [_searchButton setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
        // resize searchField and show action button
        CGRect f = _searchField.frame;
        f.size.width -= _actionButton.frame.size.width + 5;
        _searchField.frame = f;
        
        _actionButton.hidden = NO;
    }
}

-(void)stopOrReloadButtonPressed {
    if([_searchHandler respondsToSelector:@selector(searchControllerStopOrReloadButtonPressed)])
        [_searchHandler performSelector:@selector(searchControllerStopOrReloadButtonPressed)];
}

-(void)webViewStartedLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
}

-(void)webViewFinishedLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];    
    [_searchField finish];
}

-(void)setProgress:(CGFloat)progress {
    [_searchField setProgress:progress];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {
    if([_searchField isFirstResponder])
        [_searchField resignFirstResponder];
    [historyProvider logHistoryItem:queryOrURL];
    [_searchHandler loadQueryOrURL:queryOrURL];
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

-(NSString *)queryFromDDGURL:(NSURL *)url {
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
            
            return query;
        } else if(![[url pathExtension] isEqualToString:@"html"]) {
            // article page
            NSString *query = [url path];
            query = [query substringFromIndex:1]; // strip the leading '/' in the URL
            query = [query stringByReplacingOccurrencesOfString:@"_" withString:@"%20"];
            query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            return query;
        } else {
            // a URL on DDG.com, but not a search query
            return nil;
        }
    } else {
        // no, just a plain old URL.
        return nil;
    }
}

#pragma mark - Omnibar management methods

- (void)revealBackground:(BOOL)reveal animated:(BOOL)animated {
    CGSize screenSize = self.view.superview.frame.size;
	CGRect rect = self.view.frame;
    double animationDuration = (animated ? 0.25 : 0.0);
    
    if (reveal) {
		rect.size.height = screenSize.height - keyboardRect.size.height;
        
        // animate the bang bar's appearance
        CGRect bangBarFrame = inputAccessory.frame;
        bangBarFrame.origin.y = rect.size.height - 46.0;
        bangBarFrame.size.width = rect.size.width;
        inputAccessory.frame = bangBarFrame;
        inputAccessory.hidden = NO;
        
        __block CGRect f = inputAccessory.frame;
        f.origin.y += keyboardRect.size.height;
        inputAccessory.frame = f;
        [UIView animateWithDuration:animationDuration
                              delay:0 
                            options:UIViewAnimationCurveEaseOut 
                         animations:^{
                             f.origin.y -= keyboardRect.size.height;
                             inputAccessory.frame = f;                                 
                         } completion:nil];
        
        [UIView animateWithDuration:animationDuration animations:^{
            _background.alpha = (reveal ? 1.0 : 0.0);
        }];
        
    } else {
		// clip to search entry height
		rect.size.height = 46.0;
        
        // animate the bang bar's disappearance
        [UIView animateWithDuration:animationDuration
                              delay:0 
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             CGRect f = inputAccessory.frame;
                             f.origin.y = screenSize.height-f.size.height;
                             inputAccessory.frame = f;
                         }
                         completion:nil];
        
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.5 * animationDuration * NSEC_PER_SEC);
        dispatch_after(time, dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:animationDuration*0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 CGRect f = inputAccessory.frame;
                                 f.origin.y = screenSize.height;
                                 inputAccessory.frame = f;
                             }
                             completion:nil];
        });
    }
    [self revealAutocomplete:reveal animated:animated]; // if we're revealing, we'll show it again after the animation
    
    // expand the frame to fullscreen for a moment so that the background looks like it's behind the keyboard, then adjust it to appropriate size once the animation completes.
    
    if(animated)
        self.view.frame = self.view.superview.bounds;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.view.frame = rect;
    });
    
    [UIView animateWithDuration:animationDuration animations:^{
        _background.alpha = (reveal ? 1.0 : 0.0);
    }];
}


-(void)revealAutocomplete:(BOOL)reveal animated:(BOOL)animated {
    CGFloat animationDuration = (animated ? 0.25 : 0);
    if(reveal) {
        _tableView.hidden = NO;
        _tableView.alpha = 0;
        [UIView animateWithDuration:animationDuration
                         animations:^{
                             _tableView.alpha = 1;
                         }];
    } else {
        [UIView animateWithDuration:animationDuration
                         animations:^{
                             _tableView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             _tableView.alpha = 1;
                             _tableView.hidden = YES;
                         }];
    }
}

// cancelInput destroys the table view instantly, which causes issues when a cell is tapped and that needs to be processed before destroying the table view, so we wait for a tiny bit first.
-(void)cancelInputAfterDelay {
    [self performSelector:@selector(cancelInput) withObject:nil afterDelay:0.01];
}

-(void)cancelInput {
    
    [_searchField resignFirstResponder];
    if(!barUpdated) {
        _searchField.text = oldSearchText;
        oldSearchText = nil;
    }
    if([_searchHandler respondsToSelector:@selector(searchControllerAddressBarWillCancel)])
        [_searchHandler searchControllerAddressBarWillCancel];
}

-(void)updateBarWithURL:(NSURL *)url {
    barUpdated = YES;
    NSString *query = [self queryFromDDGURL:url];
    _searchField.text = (query ? query : url.absoluteString);
}

-(void)resetOmnibar {
    _searchField.text = @"";
    [_tableView reloadData];
}

#pragma mark - Input accesory

-(void)createInputAccessory {
    inputAccessory = [[DDGInputAccessoryView alloc] initWithFrame:CGRectMake(0, 0, 0, 46)];
    inputAccessory.hidden = YES;
    
    
    UIButton *bangButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [bangButton setBackgroundImage:[UIImage imageNamed:@"bang_button.png"] forState:UIControlStateNormal];
    bangButton.frame = CGRectMake(0, 0, 46, 46);
    bangButton.tag = 103;
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

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, 46)];
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.contentSize = CGSizeMake(0, 46);
    scrollView.tag = 102;
    scrollView.hidden = YES;
    [inputAccessory addSubview:scrollView];
    
    [self.view addSubview:inputAccessory];
}

-(void)bangButtonPressed {
    NSString *textToAdd;
    if(_searchField.text.length==0 || [_searchField.text characterAtIndex:_searchField.text.length-1]==' ')
        textToAdd = @"!";
    else
        textToAdd = @" !";

    [self textField:_searchField 
          shouldChangeCharactersInRange:NSMakeRange(_searchField.text.length, 0) 
          replacementString:textToAdd];
    _searchField.text = [_searchField.text stringByAppendingString:textToAdd];
}

-(void)bangAutocompleteButtonPressed:(UIButton *)sender {
    if(currentWordRange.location == NSNotFound) {
        if(_searchField.text.length == 0)
            _searchField.text = sender.titleLabel.text;
        else
            [_searchField setText:[_searchField.text stringByAppendingFormat:@" %@",sender.titleLabel.text]];
    } else {
        [_searchField setText:[_searchField.text stringByReplacingCharactersInRange:currentWordRange withString:sender.titleLabel.text]];
    }
}

-(void)loadSuggestionsForBang:(NSString *)bang {
    UIScrollView *scrollView = (UIScrollView *)[inputAccessory viewWithTag:102];
    
    NSArray *suggestions = [DDGBangsProvider bangsWithPrefix:bang];
    if(suggestions.count > 0) {
        scrollView.hidden = NO;
        UIButton *bangButton = (UIButton *)[inputAccessory viewWithTag:103];
        [bangButton setBackgroundImage:[UIImage imageNamed:@"bang_button_open.png"] forState:UIControlStateNormal];
        bangButton.hidden = YES;
    }
    UIImage *backgroundImg = [[UIImage imageNamed:@"empty_bang_button.png"] stretchableImageWithLeftCapWidth:7.0 topCapHeight:0];

    for(NSDictionary *suggestionDict in suggestions) {
        NSString *suggestion = [suggestionDict objectForKey:@"name"];

        UIButton *button;
        if([unusedBangButtons count] > 0) {
            button = [unusedBangButtons lastObject];
            [unusedBangButtons removeLastObject];
        } else {
            button = [UIButton buttonWithType:UIButtonTypeCustom];   
            [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button.titleLabel setShadowOffset:CGSizeMake(0, 1)];
        }

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
        if([subview isKindOfClass:[UIButton class]]) {
            [subview removeFromSuperview];
            [unusedBangButtons addObject:subview];
        }
    }
    scrollView.hidden = YES;
    UIButton *bangButton = (UIButton *)[inputAccessory viewWithTag:103];
    [bangButton setBackgroundImage:[UIImage imageNamed:@"bang_button.png"] forState:UIControlStateNormal];
    bangButton.hidden = NO;
}

#pragma mark - Search suggestions

- (void)reloadSuggestions {
    NSString *newSearchText = _searchField.text;
    
    if([newSearchText isEqualToString:[self validURLStringFromString:newSearchText]]) {
        // we're definitely editing a URL, don't bother with autocomplete.
        return;
    }
    
	if(newSearchText.length) {
		// load our new best cached result, and download new autocomplete suggestions.
        [suggestionsProvider downloadSuggestionsForSearchText:newSearchText success:^{
            [_tableView reloadData];
        }];
	} else {
        // search text is blank; clear the suggestions cache, reload, and hide the table
        [suggestionsProvider emptyCache];
    }
    // either way, reload the table view.
    [_tableView reloadData];
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
    
    [self clearBangSuggestions];
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{    
    if([_searchHandler respondsToSelector:@selector(searchControllerAddressBarWillOpen)])
        [_searchHandler searchControllerAddressBarWillOpen];
    
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentWordRange = NSMakeRange(NSNotFound, 0);
    
    // save search text in case user cancels input without navigating somewhere
    if(!oldSearchText)
        oldSearchText = textField.text;
    barUpdated = NO;
    
    if(![self isQuery:textField.text]) {
        textField.text = @"";
    }
    
    textField.rightView = nil;
    [self reloadSuggestions];
    
    if([_searchField.text isEqualToString:@""])
        [self loadSuggestionsForBang:@"!"];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if(!_childViewControllerVisible)
        [self revealBackground:NO animated:YES];
    
    if(_state==DDGSearchControllerStateWeb)
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
	
    [self loadQueryOrURL:([_searchField.text length] ? _searchField.text : nil)];

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
    if([_searchField.text isEqualToString:@""])
        return 1;
    else
        return ([[suggestionsProvider suggestionsForSearchText:_searchField.text] count] +
            [[historyProvider pastHistoryItemsForPrefix:_searchField.text] count]);
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if([_searchField.text isEqualToString:@""]) {
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:bookmarksCellID];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:bookmarksCellID];
            cell.textLabel.text = @"Saved";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
        }
        return cell;
    }
    
    NSArray *history = [historyProvider pastHistoryItemsForPrefix:_searchField.text];
    NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:_searchField.text];
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
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[[tv cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:bookmarksCellID]) {
        DDGBookmarksViewController *bookmarksVC = [[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil];
        bookmarksVC.searchController = self;
        [self.parentViewController.navigationController pushViewController:bookmarksVC animated:YES];
        self.childViewControllerVisible = YES;
    	[tv deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        NSArray *history = [historyProvider pastHistoryItemsForPrefix:_searchField.text];
        NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:_searchField.text];
        if(indexPath.row < history.count) {
            NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
            [self loadQueryOrURL:[historyItem objectForKey:@"text"]];        
        } else {
            NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row - history.count];
            if([suggestionItem objectForKey:@"phrase"]) // if the server gave us bad data, phrase might be nil
                [self loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];
        }
        
        [tv deselectRowAtIndexPath:indexPath animated:YES];
        [_searchField resignFirstResponder];
    }
}

- (void)viewDidUnload {
    [self setActionButton:nil];
    [super viewDidUnload];
}
@end
