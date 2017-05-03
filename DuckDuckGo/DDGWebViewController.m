//
//  DDGWebViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

@import AssetsLibrary;
#import "DDGWebViewController.h"
#import "DDGAddressBarTextField.h"
#import "DDGBookmarksProvider.h"
#import "DDGUtility.h"
#import "DDGStory.h"
#import "AFNetworking.h"
#import "DDGSettingsViewController.h"
#import "DDGActivityViewController.h"
#import "NSString+URLEncodingDDG.h"
#import "DDGBookmarkActivity.h"
#import "DDGReadabilityToggleActivity.h"
#import "DDGActivityItemProvider.h"
#import "DDGSafariActivity.h"
#import "DDGImageActivityItemProvider.h"
#import "DDGToolbarAndNavigationBarAutohider.h"
#import "Constants.h"

@interface DDGWebViewController () <UIGestureRecognizerDelegate, DDGToolbarAndNavigationBarAutohiderDelegate> {
    BOOL _isFavorited;
    CGPoint lastOffset;
    CGFloat lastUpwardsScrollDistance;
}

@property (nonatomic, readwrite) BOOL inReadabilityMode;
@property UIView* toolbar;
@property IBOutlet UIButton* backButton;
@property IBOutlet UIButton* forwardButton;
@property IBOutlet UIButton* favButton;
@property IBOutlet UIButton* shareButton;
@property IBOutlet UIButton* tabsButton;
@property IBOutlet NSLayoutConstraint* tabBarTopBorderConstraint; // this exists to force the border to be 0.5px
@property DDGToolbarAndNavigationBarAutohider* toolbarHider;
@property NSLayoutConstraint* bottomToolbarTopConstraint;
@property UITapGestureRecognizer *tapGestureRecognizer;

@property BOOL isFavorited;

@end


@interface DDGWebView : UIWebView {
    UIView* _blackHoleView;
}

@property (nonatomic, weak) DDGWebViewController* webController;
@property (readonly) UIView* blackHoleView;

@end



@implementation DDGWebView


-(UIView*)blackHoleView {
    if(_blackHoleView==nil) {
        _blackHoleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    }
    return _blackHoleView;
}

-(UIView*)hitTest:(CGPoint)tapPoint withEvent:(UIEvent *)event
{

    // if someone taps the bottom toolbar area, swallow the tap and show the toolbar
    if(tapPoint.y + 50 > self.frame.size.height) {
        [self.webController setHideToolbarAndNavigationBar:FALSE forScrollview:self.scrollView];
        return self.blackHoleView;
    }
    return [super hitTest:tapPoint withEvent:event];
}

@end




@implementation DDGWebViewController

-(UIView*)alternateToolbar {
    if([self view]) return self.toolbar;
    return nil;
}

- (void)setUpWebToolBar {
    [[UINib nibWithNibName:@"DDGWebToolbar" bundle:nil] instantiateWithOwner:self options:nil];
    [self.view addSubview:self.webToolbar];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webToolbar
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webToolbar
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1 constant:0]];
    self.bottomToolbarTopConstraint = [NSLayoutConstraint constraintWithItem:self.webToolbar
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1 constant:0];
    [self.view addConstraint:self.bottomToolbarTopConstraint];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tabBarTopBorderConstraint.constant = 0.5f;
    UIMenuItem *search = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Search", @"Search") action:@selector(search:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[search]];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.tapGestureRecognizer.delegate = self;
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.webView addGestureRecognizer:self.tapGestureRecognizer];
    
    self.toolbarHider = [[DDGToolbarAndNavigationBarAutohider alloc] initWithContainerView:self.view scrollView:self.webView.scrollView delegate:self];
}

- (void)setSearchController:(DDGSearchController *)searchController {
    if (searchController == _searchController)
        return;
    
    _searchController = searchController;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.searchControllerDDG.homeController registerScrollableContent:self.webView.scrollView];
}

-(void)viewWillDisappear:(BOOL)animated {
    if (self.webView.isLoading)
        [self.webView stopLoading];

    [self resetLoadingDepth];
    
    // Bring back the expanded state
    [self.searchController expandNavigationBar];
    
    [super viewWillDisappear:animated];
    [UIMenuController sharedMenuController].menuItems = nil;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.webView.scrollView.contentInset = UIEdgeInsetsZero;
    self.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    lastOffset = self.webView.scrollView.contentOffset;
    lastUpwardsScrollDistance = 0;
}

- (void)dealloc
{
    self.webView.scrollView.delegate = nil;
    [self resetLoadingDepth];    
    
    self.tapGestureRecognizer.delegate = nil;
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    if([self.webView respondsToSelector:@selector(setDelegate:)]) {
        [self.webView setDelegate:nil];
    }
    self.webView = nil;
	self.webViewURL = nil;
     
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
	return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.searchController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


#pragma mark - Handle long-press on images

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    DLog(@"empty tap handler");
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
            otherGestureRecognizer.state==UIGestureRecognizerStateBegan && 
            gestureRecognizer.state==UIGestureRecognizerStateFailed) 
    {
        CGPoint touchLoc = [otherGestureRecognizer locationInView:self.webView];
        NSURL* imageURL = [self findImageForTap:touchLoc];
        if(imageURL!=nil) {
            [self longPressOnImage:imageURL atLocation:touchLoc];
            return YES;
        }
    }
    return YES;
}


#pragma mark - Private

-(void)handleLongPress:(UIGestureRecognizer*)sender
{
    CGPoint touchLocation = [sender locationInView:self.webView];
    NSURL* imageURL = [self findImageForTap:touchLocation];
    if(imageURL) {
        [self longPressOnImage:imageURL atLocation:touchLocation];
    }
}

- (NSURL*)findImageForTap:(CGPoint)tapLocation
{
    NSString *javascript = @"var ddg_url = '';" \
    "var node = document.elementFromPoint(%f, %f);" \
    "while(node) {" \
    "  if (node.tagName) {" \
    "    if(node.tagName.toLowerCase() == 'img' && node.src && node.src.length > 0) {" \
    "      ddg_url = node.src;" \
    "      break;" \
    "    }" \
    "  }" \
    "  node = node.parentNode;" \
    "}";
    NSString* url = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:javascript, tapLocation.x, tapLocation.y]];
    //NSString *url = [self stringByEvaluatingJavaScriptFromString:@"ddg_url"];
    if(url && url.length > 0 && [DDGUtility looksLikeURL:url]) {
        NSLog(@" tapped on image: %@", url);
        return [NSURL URLWithString:url];
    }
    return nil;
}




#pragma mark - Readability Mode

- (BOOL)currentURLIsNonReadabilityURL {
    return [self.story.URL isEqual:self.webView.request.URL];
}

- (BOOL)canSwitchToReadabilityMode {
    if (self.inReadabilityMode)
        return NO;

    BOOL readabilityAvailable = (nil != self.story.articleURLString);
    
    return (readabilityAvailable && !self.webView.canGoBack);
}

- (void)switchReadabilityMode:(BOOL)on {
    if (on) {
        if (![self canSwitchToReadabilityMode])
            return;
        
            [self loadStory:self.story readabilityMode:YES];
    } else {
        if (!self.inReadabilityMode)
            return;
        
            [self loadStory:self.story readabilityMode:NO];
    }
}

#pragma mark - Actions

-(void)setHideToolbarAndNavigationBar:(BOOL)shouldHide forScrollview:(UIScrollView*)scrollView
{
    CGFloat newConstant = shouldHide ? 50 : 0;
    // if (shouldHide && self.isAStory) {
    if (shouldHide) {
        [self.searchController compactNavigationBar];
    } else {
        [self.searchController expandNavigationBar];
    }
    if(self.bottomToolbarTopConstraint.constant!=newConstant) {
        self.bottomToolbarTopConstraint.constant = newConstant;
        CGFloat toolbarBottomInset = shouldHide ? 0 : 50;
        [UIView animateWithDuration:0.25 animations:^{
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, toolbarBottomInset, 0);
            scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, toolbarBottomInset, 0);
            [self.view layoutSubviews];
        }];
    }
}


-(BOOL)isFavorited
{
    return _isFavorited;
}

-(void)setIsFavorited:(BOOL)isFavorited
{
    if(isFavorited) {
        [self.favButton setImage:[UIImage imageNamed:@"webbar-fav-active"] forState:UIControlStateNormal];
    } else {
        [self.favButton setImage:[UIImage imageNamed:@"webbar-fav"] forState:UIControlStateNormal];
    }
    _isFavorited = isFavorited;
}

-(void)searchControllerActionButtonPressed:(id)sender
{
    // strip extra params from DDG search URLs
    NSURL *shareURL = self.webViewURL;
    NSString *query = [DDGSearchController queryFromDDGURL:shareURL];
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if(query) {
        NSString *escapedQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        shareURL = [NSURL URLWithString:[@"https://duckduckgo.com/?q=" stringByAppendingString:escapedQuery]];
    } else if(self.story) {
        shareURL = self.story.URL;
        pageTitle = self.story.title;
    }
    
    NSString* shareString = [NSString stringWithFormat:NSLocalizedString(@"%@\n\nvia DuckDuckGo for iOS\n\n", @"%@\n\nvia DuckDuckGo for iOS\n\n"), pageTitle];
    
    NSArray *applicationActivities = @[];
    NSArray *items = @[shareString, shareURL];
    
    if (self.inReadabilityMode) {
        DDGReadabilityToggleActivity *toggleActivity = [[DDGReadabilityToggleActivity alloc] init];
        toggleActivity.toggleMode = DDGReadabilityToggleModeOff;
        applicationActivities = [applicationActivities arrayByAddingObject:toggleActivity];
    } else if ([self canSwitchToReadabilityMode]) {
        DDGReadabilityToggleActivity *toggleActivity = [[DDGReadabilityToggleActivity alloc] init];
        toggleActivity.toggleMode = DDGReadabilityToggleModeOn;
        applicationActivities = [applicationActivities arrayByAddingObject:toggleActivity];
    }
    
    DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:items applicationActivities:applicationActivities];
    
    if ( [avc respondsToSelector:@selector(popoverPresentationController)] ) {
        // iOS8
        avc.popoverPresentationController.sourceView = sender;
    }
    
    [self presentViewController:avc animated:YES completion:NULL];
}

-(void)longPressOnImage:(NSURL*)imageURL atLocation:(CGPoint)tapPoint
{
    NSArray *applicationActivities = @[];
    NSArray *items = @[ [[DDGImageActivityItemProvider alloc] initWithImageURL:imageURL ] ];
                        
    DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:items
                                                                        applicationActivities:applicationActivities];
    if ( [avc respondsToSelector:@selector(popoverPresentationController)] ) {
        // iOS8
        avc.popoverPresentationController.sourceView = self.view;
        avc.popoverPresentationController.sourceRect = CGRectMake(tapPoint.x, tapPoint.y, 1, 1);
    }
    
    [self presentViewController:avc animated:YES completion:NULL];
}

#pragma mark - Search handler

-(void)prepareForUserInput {
    if (self.searchController.searchBar.searchField.window)
        [self.searchController.searchBar.searchField becomeFirstResponder];
}

-(IBAction)backButtonPressed:(id)sender {
    if (self.webView.canGoBack) {
        [self.webView goBack];
    } else if ([self.searchController canPopContentViewController]) {
        [self.searchController popContentViewControllerAnimated:YES];
    }
}

-(IBAction)forwardButtonPressed:(id)sender {
    if (self.webView.canGoForward) {
        [self.webView goForward];
    }
}

-(IBAction)favButtonPressed:(id)sender {
    NSURL *shareURL = self.webViewURL;
    NSString *query = [DDGSearchController queryFromDDGURL:shareURL];
    NSString *feed = [self.webViewURL absoluteString];
    DDGBookmarkActivityItem* bookmarkItem = nil;
    if (nil != self.story && !self.webView.canGoBack) { // bookmark the story, since we're at the top level
        bookmarkItem = [DDGBookmarkActivityItem itemWithStory:self.story];
    } else if (query) { // bookmark the query that we just used
        bookmarkItem = [DDGBookmarkActivityItem itemWithTitle:query URL:self.webViewURL feed:feed];
    } else { // there was no query... just bookmark this page
        NSString* title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        if(title==nil || [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length<=0) {
            title = self.webView.request.URL.absoluteString;
        }
        if(title!=nil) {
            bookmarkItem = [DDGBookmarkActivityItem itemWithTitle:title URL:self.webViewURL feed:feed];
        }
    }
    
    DDGBookmarksProvider *provider = [DDGBookmarksProvider sharedProvider];
    if(self.isFavorited) {
        if (bookmarkItem.story) {
            bookmarkItem.story.savedValue = NO;
        } else {
            [provider unbookmarkPageWithURL:bookmarkItem.URL];
        }
    } else {
        if (bookmarkItem.story) {
            bookmarkItem.story.savedValue = YES;
        } else {
            [provider bookmarkPageWithTitle:bookmarkItem.title feed:bookmarkItem.feed URL:bookmarkItem.URL];
        }
    }
    
    if (nil != bookmarkItem.story) {
        NSManagedObjectContext *context = bookmarkItem.story.managedObjectContext;
        [context performBlock:^{
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"error: %@", error);
            }
        }];
    }
    
    self.isFavorited = !self.isFavorited;
}

-(IBAction)shareButtonPressed:(id)sender {
    [self searchControllerActionButtonPressed:sender];
}

-(IBAction)tabsButtonPressed:(id)sender {
    NSLog(@"tabsButtonPressed");
}




-(void)searchControllerLeftButtonPressed {        
    if ([self.searchController canPopContentViewController]) {
        [self.searchController popContentViewControllerAnimated:YES];
    }
}

-(void)searchControllerStopOrReloadButtonPressed {
    if(self.webView.isLoading) {
        [self.webView stopLoading];
    } else {
        if (self.inReadabilityMode) {
            [self loadStory:self.story readabilityMode:YES];
        } else {
            [self.webView reload];
        }
    }
}

-(void)loadQueryOrURL:(NSString *)queryOrURLString
{
    [self view];
    NSString *urlString;
    if([self.searchController isQuery:queryOrURLString])
    {
        self.isAStory = false;
        NSLog(@"Is not a story for querystring %@", queryOrURLString);
        // direct query
        urlString = [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&ko=-1&kl=%@",
                     [queryOrURLString URLEncodedStringDDG], 
                     [[NSUserDefaults standardUserDefaults] objectForKey:DDGSettingRegion]];
    }
    else
    {
        self.isAStory = true;
        // a URL entered by user
        urlString = [self.searchController validURLStringFromString:queryOrURLString];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    [self loadWebViewWithUrl:url];
}

- (void)loadWebViewWithUrl:(NSURL*)url {
    NSURLRequest *request = [DDGUtility requestWithURL:url];
    [self.webView loadRequest:request];
    [self.searchController updateBarWithURL:url];
    self.webViewURL = url;
}

- (void)loadJSONForStory:(DDGStory *)story completion:(void (^)(id JSON))completion {
    self.isAStory = true;
    NSString *urlString = story.articleURLString;
    
    if (nil == urlString) {
        if (completion)
            completion(NULL);
        return;
    }
    
    __weak DDGWebViewController *weakSelf = self;
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [DDGUtility requestWithURL:url];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion)
            completion(responseObject);
        [weakSelf decrementLoadingDepthCancelled:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion)
            completion(nil);
        [weakSelf.searchController webViewFinishedLoading];
        [weakSelf decrementLoadingDepthCancelled:YES];
        [weakSelf loadQueryOrURL:story.urlString];
    }];
    
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/javascript"]];
    
    [self incrementLoadingDepth];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [operation start];
    });
}


-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode {
    [self view];
    
    if (nil != self.webView.request) {
        if (self.webView.isLoading) {
            [self.webView stopLoading];
        }
        [self resetLoadingDepth];
    }
    
    void (^htmlDownloaded)(BOOL success) = ^(BOOL success){
        if (readabilityMode && success) {
            self.webViewURL = story.URL;
            [self.webView loadRequest:[story HTMLURLRequest]];
//            [self.webView loadHTMLString:[story HTML] baseURL:nil];
        } else {
            [self loadQueryOrURL:story.urlString];
        }
    };
    
    void (^completion)(id JSON) = ^(id JSON) {
        NSString *html = [self htmlFromJSON:JSON];
        if (nil != html) {
            [story writeHTMLString:html completion:htmlDownloaded];
        } else {
            htmlDownloaded(story.isHTMLDownloaded);
        }
        
        story.readValue = YES;
        
        NSManagedObjectContext *context = story.managedObjectContext;
        [context performBlock:^{
            NSError *error = nil;
            BOOL success = [context save:&error];
            if (!success) {
                NSLog(@"error: %@", error);
            }
        }];
    };
    
    self.story = story;
    
    if (readabilityMode && !story.isHTMLDownloaded) {
        [self loadJSONForStory:story completion:completion];
    } else {
        completion(nil);
    }
}

#pragma mark - Searching for selected text

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(search:)) {
        return ![self.searchController.searchBar.searchField isFirstResponder];
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)search:(UIMenuItem *)menuItem
{
    NSString *selection = [self.webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    [self loadQueryOrURL:selection];
}

#pragma mark - Mail sender deleagte

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)internalMailAction:(NSURL*)url
{
	if ([MFMailComposeViewController canSendMail])
	{
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
        NSString *mailtoParameterString = [[url absoluteString] substringFromIndex:[@"mailto:" length]];
        NSUInteger questionMarkLocation = [mailtoParameterString rangeOfString:@"?"].location;
		
        if (questionMarkLocation == NSNotFound)
		{
			// simply a to parameter
			[params setObject:mailtoParameterString forKey:@"to"];
		}
		else
		{
			// more than just a to field
			[params setObject:[mailtoParameterString substringToIndex:questionMarkLocation] forKey:@"to"];
            NSString *parameterString = [mailtoParameterString substringFromIndex:questionMarkLocation + 1];
            NSArray *keyValuePairs = [parameterString componentsSeparatedByString:@"&"];
            for (NSString *queryString in keyValuePairs)
			{
                NSArray *keyValuePair = [queryString componentsSeparatedByString:@"="];
                if (keyValuePair.count == 2)
                    [params setObject:[[keyValuePair objectAtIndex:1] URLDecodedStringDDG] forKey:[[keyValuePair objectAtIndex:0] URLDecodedStringDDG]];
            }
        }
		// now mail it
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		mailVC.mailComposeDelegate = self;
		if ([params objectForKey:@"to"])
			[mailVC setToRecipients:[[params objectForKey:@"to"] componentsSeparatedByString:@","]];
		else
			[mailVC setToRecipients:@[]];
		[mailVC setSubject:[params objectForKey:@"subject"]];
		[mailVC setMessageBody:[params objectForKey:@"body"] isHTML:YES];
		[self presentViewController:mailVC animated:YES completion:NULL];
	}
}

#pragma mark - Web view deleagte

- (void)updateBarWithRequest:(NSURLRequest *)request {
    NSURL *url = request.URL;
    
    if ([url isEqual:request.mainDocumentURL])
    {
        NSString *scheme = [[url scheme] lowercaseString];
        if ([scheme isEqualToString:@"http"]
            || [scheme isEqualToString:@"https"]) {
            [self.searchController updateBarWithURL:request.URL];
            self.webViewURL = request.URL;
            self.inReadabilityMode = NO;
        } else if ((self.story && !self.webView.canGoBack)
                   || [[[self.story HTMLURLRequest].URL URLByStandardizingPath] isEqual:[url URLByStandardizingPath]]) {
            NSURL *storyURL = self.story.URL;
            [self.searchController updateBarWithURL:storyURL];
            self.webViewURL = storyURL;
            self.inReadabilityMode = YES;
        }
    }    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSDate* ignoreUntil = self.ignoreTapsUntil;
        if(ignoreUntil && [ignoreUntil compare:[NSDate new]]==NSOrderedDescending) return NO; // ignore clicks within a certain range
        
		if ([[[request.URL scheme] lowercaseString] isEqualToString:@"mailto"]) {
			// user is interested in mailing so use the internal mail API
			[self performSelector:@selector(internalMailAction:) withObject:request.URL afterDelay:0.005];
			return NO;
		}
	}
    
    //NSLog(@"shouldStartLoadWithRequest: %@ navigationType: %i", request, navigationType);
	return YES;
}


-(void)updateButtons {
    self.backButton.enabled = self.webView.canGoBack || self.navigationController.viewControllers.count>1;
    self.forwardButton.enabled = self.webView.canGoForward;
    
    if (nil != self.story && !self.webView.canGoBack) {
        // we're at the top level of a story, so we can fave/bookmark that story
        self.isFavorited = self.story.savedValue;
    } else { //if ([DDGSearchController queryFromDDGURL:self.webViewURL]) {
        // this is a query that has been favorited/bookmarked
        self.isFavorited = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:self.webViewURL];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
//    NSLog(@"webViewDidStartLoad events: %i", _webViewLoadEvents);
    [self updateButtons];
    [self incrementLoadingDepth];
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{    
    [self updateBarWithRequest:theWebView.request];
    //[self.searchController webViewCanGoBack:theWebView.canGoBack];
    [self updateButtons];
    [self decrementLoadingDepthCancelled:NO];

    
//    NSLog(@"webViewDidFinishLoad events: %i", _webViewLoadEvents);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self decrementLoadingDepthCancelled:YES];
    
//    NSLog(@"didFailLoadWithError events: %i", _webViewLoadEvents);
}

-(void)updateProgressBar {
    if(_webViewLoadingDepth == 1)
        [self.searchController setProgress:0.15];
    else if(_webViewLoadingDepth == 2)
        [self.searchController setProgress:0.7];
}

- (NSUInteger)incrementLoadingDepth {
	if (++_webViewLoadingDepth == 1) {
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
        [self.searchController webViewStartedLoading];
    }
    
    [self updateProgressBar];        
    
    return _webViewLoadingDepth;
}

- (NSUInteger)decrementLoadingDepthCancelled:(BOOL)cancelled {
	if (--_webViewLoadingDepth <= 0) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        if (cancelled)
            [self.searchController webViewCancelledLoading];
        else
            [self.searchController webViewFinishedLoading];
		_webViewLoadingDepth = 0;
	}
    return _webViewLoadingDepth;    
}

- (void)resetLoadingDepth {
    if (_webViewLoadingDepth > 0) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [self.searchController webViewCancelledLoading];
    }
    
    _webViewLoadingDepth = 0;
}

#pragma mark - Other

- (BOOL)hasAccessToPhotos
{
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    return (status == ALAuthorizationStatusNotDetermined || status == ALAuthorizationStatusAuthorized);
}

#pragma mark == Web Helper Methods ==
- (NSString *)htmlFromJSON:(id)JSON {
    if ([JSON isKindOfClass:[NSArray class]]) {
        
        NSArray *stories = JSON;
        if ([stories count] > 0) {
            NSDictionary *dictionary = [stories objectAtIndex:0];
            if ([dictionary isKindOfClass:[NSDictionary class]]) {
                NSString *html = [dictionary objectForKey:@"html"];
                if ([html isKindOfClass:[NSString class]])
                    return html;
            }
        }
    }
    
    return nil;
}
@end
