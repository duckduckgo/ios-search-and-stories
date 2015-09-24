//
//  DDGSearchController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSearchController.h"
#import "DDGSearchSuggestionsProvider.h"
#import "AFNetworking.h"
#import "DDGBangsProvider.h"
#import "DDGInputAccessoryView.h"
#import "DDGBookmarksViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGHistoryProvider.h"
#import "DDGWebViewController.h"
#import "DDGAddressBarTextField.h"

#import "NSMutableString+DDGDumpView.h"
#import "DDGPopoverViewController.h"
#import "DDGDuckViewController.h"
#import "UIViewController+DDGSearchController.h"
#import "DDGUtility.h"

NSString * const emailRegEx =
@"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

@interface DDGSearchController () <DDGPopoverViewControllerDelegate>
@property (nonatomic, strong) DDGHistoryProvider *historyProvider;
@property (nonatomic, strong) DDGDuckViewController* autocompleteController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, getter = isDraggingTopViewController) BOOL draggingTopViewController;
@property (nonatomic, copy) void (^keyboardDidHideBlock)(BOOL completed);
@property (nonatomic, strong) DDGPopoverViewController *bangInfoPopover;
@property (nonatomic, strong) DDGPopoverViewController *autocompletePopover;
@property (nonatomic, strong) NSPredicate *emailPredicate;
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic) BOOL showBangTooltip;
@property (nonatomic, getter = isTransitioningViewControllers) BOOL transitioningViewControllers;
@property (nonatomic, weak) UIView* customToolbar;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* contentBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* searchBarMaxWidthConstraint;
@property UIView* shadowView;

@end

@implementation DDGSearchController {
    id keyboardDidHideObserver;
    id keyboardWillShowObserver;
    id keyboardWillHideObserver;
}

-(id)initWithHomeController:(DDGHomeViewController*)homeController
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	self = [super initWithNibName:@"DDGSearchController" bundle:nil];
    
	if (self) {
        self.homeController = homeController;
        self.managedObjectContext = managedObjectContext;
        self.showBangTooltip = ![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingSuppressBangTooltip];
        self.shouldPushSearchHandlerEvents = YES;
	}
	return self;
}

- (void)dealloc {
    if (nil != self.keyboardDidHideBlock)
        self.keyboardDidHideBlock(NO);
    self.keyboardDidHideBlock = nil;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:keyboardWillShowObserver];
    [center removeObserver:keyboardWillHideObserver];
    [center removeObserver:keyboardDidHideObserver];
    [self.view removeFromSuperview];
}

- (void)setSearchBarOrangeButtonImage {
    
    UIImage *image = nil;
    
    if(self.navController.viewControllers.count > 1) {
        UIViewController *incomingViewController = self.rootViewInNavigator;
        image = incomingViewController.searchControllerBackButtonIconDDG;
    }
    
    if (image == nil) {
        image = [[UIImage imageNamed:@"Home"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    [self.searchBar.orangeButton setImage:image forState:UIControlStateNormal];
}

- (void)pushContentViewController:(UIViewController *)contentController animated:(BOOL)animated {
    if (self.isTransitioningViewControllers)
        return;
    if([contentController isKindOfClass:DDGDuckViewController.class]) {
        ((DDGDuckViewController*)contentController).underPopoverMode = [self shouldUsePopover];
    }
    [self view]; // force the view to be loaded
    contentController.view.frame = self.background.frame;
    [self.navController pushViewController:contentController animated:animated];
    [self updateToolbars:FALSE];
}

- (BOOL)canPopContentViewController {
    return self.navController.viewControllers.count > 1 && !self.isTransitioningViewControllers;
}

- (void)popContentViewControllerAnimated:(BOOL)animated {
    if ([self canPopContentViewController]) {
        NSTimeInterval duration = (animated) ? 0.3 : 0.0;
        
        [self setState:DDGSearchControllerStateHome animationDuration:duration];
        [self setSearchBarOrangeButtonImage];
        [self.searchBar.searchField resetField];
        [self setProgress:1.0f animated:FALSE];
        
        [self.navController popViewControllerAnimated:animated];
    }
}

-(UIViewController*)rootViewInNavigator {
    NSArray* navigableViewControllers = self.navController.viewControllers;
    return navigableViewControllers.count>0 ? navigableViewControllers[0] : nil;
}

- (NSArray *)contentControllers {
    return [self.navController.viewControllers copy];
}

- (DDGHistoryProvider *)historyProvider {
    if (nil == _historyProvider) {
        _historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
    }
    
    return _historyProvider;
}


#pragma mark - View lifecycle

- (void)viewWillLayoutSubviews
{
	if (self.view.frame.origin.y < 0.0)	{
        self.contentBottomConstraint.constant = 0;
	}
}

-(BOOL)shouldUsePopover {
    if([self respondsToSelector:@selector(traitCollection)]) {
        return self.traitCollection.horizontalSizeClass==UIUserInterfaceSizeClassRegular;
    }
    return IPAD;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.searchBarWrapper setBackgroundColor:[UIColor duckSearchBarBackground]];
    
    if(self.autocompleteController==nil) {
        self.autocompleteController = [[DDGDuckViewController alloc] initWithSearchController:self managedObjectContext:self.managedObjectContext];
        self.autocompleteController.historyProvider = self.historyProvider;
    }
    
    DDGAddressBarTextField *searchField = self.searchBar.searchField;
    [searchField addTarget:self action:@selector(searchFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [searchField.stopButton addTarget:self action:@selector(stopOrReloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [searchField.reloadButton addTarget:self action:@selector(stopOrReloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [searchField setRightButtonMode:DDGAddressBarRightButtonModeDefault];
    
    unusedBangButtons = [[NSMutableArray alloc] initWithCapacity:50];
    
    searchField.leftViewMode = UITextFieldViewModeAlways;
    searchField.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spacer8x16.png"]];
	searchField.delegate = self;    
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    __weak typeof(self) weakSelf = self;
    keyboardWillShowObserver = [center addObserverForName:UIKeyboardWillShowNotification object:nil queue:queue usingBlock:^(NSNotification *note) {
        if (weakSelf) {
            [weakSelf keyboardWillShow:note];
        }
    }];
    keyboardWillHideObserver = [center addObserverForName:UIKeyboardWillHideNotification object:nil queue:queue usingBlock:^(NSNotification *note) {
        if (weakSelf) {
            [weakSelf keyboardWillHide:note];
        }
    }];
    keyboardDidHideObserver = [center addObserverForName:UIKeyboardDidHideNotification object:nil queue:queue usingBlock:^(NSNotification *note) {
        if (weakSelf) {
            [weakSelf keyboardDidHide:note];
        }
    }];
    UINavigationController* navController = [[UINavigationController alloc] init];
    navController.navigationBarHidden = TRUE;
    navController.view.backgroundColor = [UIColor duckSearchBarBackground];
    navController.interactivePopGestureRecognizer.enabled = TRUE;
    navController.interactivePopGestureRecognizer.delegate = self;
    navController.delegate = self;
    navController.view.frame = self.background.frame;
    [self addChildViewController:navController];
    [self.view insertSubview:navController.view belowSubview:self.background];
    [navController didMoveToParentViewController:self];
    self.navController = navController;
    
    CGRect searchBarFrame = self.searchBar.frame;
    self.shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, searchBarFrame.origin.y + searchBarFrame.size.height,
                                                               self.view.frame.size.width, 0.5)];
    self.shadowView.opaque = FALSE;
    self.shadowView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
    self.shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.shadowView];
    
    [self setNeedsStatusBarAppearanceUpdate];
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

-(void)updateiPadSearchBarToLandscape:(BOOL)isLandscape
{
    if(IPAD) {
        self.searchBarMaxWidthConstraint.constant = isLandscape ? 514 : 414;
    }
}

//-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
//{
//    if(IPAD) {
//        [self updateiPadSearchBarToLandscape:(size.width > size.height)];
//    }
//}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateiPadSearchBarToLandscape:UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    if(self.autocompletePopover.isBeingPresented) {
        //self.autocompletePopover.view.alpha = 0.0;
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(self.autocompletePopover.isBeingPresented) {
        CGRect autocompleteRect = self.autocompleteController.view.frame;
        autocompleteRect.origin.x = 0;
        autocompleteRect.origin.y = 0;
        autocompleteRect.size.width = self.searchBar.frame.size.width + 0;
        autocompleteRect.size.height = 490;
        self.autocompleteController.preferredContentSize = autocompleteRect.size;
        //self.autocompletePopover.view.alpha = 1.0;
    }
}

- (void)viewDidUnload {
    [self setAutocompleteNavigationController:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateiPadSearchBarToLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
    
    if([self shouldUsePopover]) {
        if(self.autocompleteNavigationController) {
            [self.autocompleteNavigationController.view removeFromSuperview];
            [self.autocompleteNavigationController removeFromParentViewController];
            self.autocompleteNavigationController = nil;
            
            [self.autocompleteController removeFromParentViewController];
            [self.autocompleteController.view removeFromSuperview];
        }
        
        [self.background removeFromSuperview];
        self.autocompleteController.popoverMode = TRUE;
        if(self.autocompletePopover==nil) {
            self.autocompletePopover = [[DDGPopoverViewController alloc] initWithContentViewController:self.autocompleteController
                                                                               andTouchPassthroughView:self.view];
            self.autocompletePopover.largeMode = TRUE;
            self.autocompletePopover.popoverParentController = self;
            self.autocompletePopover.shouldDismissUponOutsideTap = FALSE;
        }
    } else {
        if(self.autocompletePopover) {
            [self.autocompletePopover removeFromParentViewController];
            [self.autocompletePopover.view removeFromSuperview];
            self.autocompletePopover = nil;
            
            [self.autocompleteController removeFromParentViewController];
            [self.autocompleteController.view removeFromSuperview];
        }
        
        if(self.autocompleteNavigationController==nil) {
            [self.autocompleteController removeFromParentViewController];
            self.autocompleteNavigationController = [[UINavigationController alloc] initWithRootViewController:self.autocompleteController];
            self.autocompleteNavigationController.delegate = self;
            [self addChildViewController:self.autocompleteNavigationController];
            self.autocompleteNavigationController.view.frame = _background.bounds;
            [self.background addSubview:self.autocompleteNavigationController.view];
            [self.autocompleteNavigationController didMoveToParentViewController:self];
        }
    }
    
    [self revealAutocomplete:NO animated:NO];
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSAssert(self.state != DDGSearchControllerStateUnknown, nil);
    
    if(self.autocompletePopover.isBeingPresented) {
        CGRect autocompleteRect = self.autocompleteController.view.frame;
        autocompleteRect.origin.x = 0;
        autocompleteRect.origin.y = 0;
        autocompleteRect.size.width = self.searchBar.frame.size.width + 0;
        autocompleteRect.size.height = 490;
        self.autocompleteController.preferredContentSize = autocompleteRect.size;
        //self.autocompletePopover.preferredContentSize = autocompleteRect.size;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}



#pragma mark - Keyboard notifications

- (void)slidingViewTopDidAnchorRight:(NSNotification *)notification {
    [self.searchBar.searchField resignFirstResponder];
}

-(void)keyboardWillShow:(NSNotification *)notification {
    [self keyboardWillShow:YES notification:notification];
}

-(void)keyboardWillHide:(NSNotification *)notification {
    [self keyboardWillShow:NO notification:notification];
}

-(void)keyboardDidHide:(NSNotification *)notification {
    if (self.keyboardDidHideBlock)
        self.keyboardDidHideBlock(YES);
    self.keyboardDidHideBlock = nil;
}

-(void)keyboardWillShow:(BOOL)show notification:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    CGRect keyboardBegin = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    keyboardBegin = [self.view.superview convertRect:keyboardBegin fromView:nil];
    CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardEnd = [self.view.superview convertRect:keyboardEnd fromView:nil];
    double dy = keyboardEnd.origin.y - keyboardBegin.origin.y;
    if(ABS(dy) < 1) {
        
        // this isn't a standard up/down animation so don't try animating
        
        [self revealInputAccessory:show animationDuration:0.0];
        
        double delayInSeconds = (show ? [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] : 0.0);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if(show) {
                self.contentBottomConstraint.constant = -keyboardEnd.size.height;
            } else {
                self.contentBottomConstraint.constant = 0;
            }
        });
        
    } else {
        double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [self revealInputAccessory:show animationDuration:duration];
        
        UIViewController *controller = self.navController.visibleViewController;
        if ([controller isKindOfClass:[DDGDuckViewController class]]) {
            [controller.view layoutIfNeeded];
        }
        [UIView animateWithDuration:duration
                              delay:0
                            options:[[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]
                         animations:^{
//                             if ([controller isKindOfClass:[DDGDuckViewController class]]) {
//                                 [(DDGDuckViewController *)controller updateContainerHeightConstraint:show];
//                                 [controller.view layoutIfNeeded];
//                             }
//                             CGRect f = self.view.frame;
//                             f.size.height = keyboardEnd.origin.y - f.origin.y;
//                             self.view.frame = f;
//                             self.contentBottomConstraint.constant = -keyboardEnd.size.height;
                         } completion:nil];
    }
}

#pragma mark - DDGSearchHandler

-(void)searchControllerStopOrReloadButtonPressed {
    UIViewController *contentViewController = self.navController.visibleViewController;
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        UIViewController <DDGSearchHandler> *searchHandler = (UIViewController <DDGSearchHandler> *)contentViewController;
        if([searchHandler respondsToSelector:@selector(searchControllerStopOrReloadButtonPressed)])
            [searchHandler searchControllerStopOrReloadButtonPressed];
    } else {
        if([_searchHandler respondsToSelector:@selector(searchControllerStopOrReloadButtonPressed)])
            [_searchHandler searchControllerStopOrReloadButtonPressed];
    }
}

-(void)searchControllerActionButtonPressed:(id)sender {
    UIViewController *contentViewController = self.navController.visibleViewController;
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        UIViewController <DDGSearchHandler> *searchHandler = (UIViewController <DDGSearchHandler> *)contentViewController;
        if([searchHandler respondsToSelector:@selector(searchControllerActionButtonPressed:)]) {
            [searchHandler searchControllerActionButtonPressed:sender];
        }
    } else {
        if([_searchHandler respondsToSelector:@selector(searchControllerActionButtonPressed:)]) {
            [_searchHandler searchControllerActionButtonPressed:sender];
        }
    }
}

-(void)searchControllerLeftButtonPressed {
    [self.searchBar.searchField resignFirstResponder];
    UIViewController *contentViewController = self.navController.visibleViewController;
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        [(UIViewController <DDGSearchHandler> *)contentViewController searchControllerLeftButtonPressed];
    } else {
        if (self.navController.viewControllers.count > 1) {
            [self popContentViewControllerAnimated:YES];
        } else {
            [_searchHandler searchControllerLeftButtonPressed];
        }
    }
    [self.searchBar.searchField resignFirstResponder];
}

-(void)loadQueryOrURL:(NSString *)queryOrURLString {
    UIViewController *contentViewController = self.navController.visibleViewController;
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        [(UIViewController <DDGSearchHandler> *)contentViewController loadQueryOrURL:queryOrURLString];
    } else {
        if (self.shouldPushSearchHandlerEvents) {
            DDGWebViewController *webViewController = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
            webViewController.searchController = self;
            [self pushContentViewController:webViewController animated:YES];
            [webViewController loadQueryOrURL:queryOrURLString];
        } else {
            [_searchHandler loadQueryOrURL:queryOrURLString];
        }
    }
}

-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode {
    UIViewController *contentViewController = self.navController.visibleViewController;
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        [(UIViewController <DDGSearchHandler> *)contentViewController loadStory:story readabilityMode:readabilityMode];
    } else {
        if (self.shouldPushSearchHandlerEvents) {
            DDGWebViewController *webViewController = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
            webViewController.searchController = self;
            [self pushContentViewController:webViewController animated:YES];
            [webViewController loadStory:story readabilityMode:readabilityMode];
        } else {
            [_searchHandler loadStory:story readabilityMode:readabilityMode];
        }
    }
}

-(void)prepareForUserInput {
    UIViewController *contentViewController = self.navController.visibleViewController;
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        [(UIViewController <DDGSearchHandler> *)contentViewController prepareForUserInput];
    } else {
        [_searchHandler prepareForUserInput];
    }
}

#pragma mark - Interactions with search handler

- (IBAction)actionButtonPressed:(id)sender {
    [self searchControllerActionButtonPressed:sender];
}

-(IBAction)bangButtonPressed:(UIButton*)sender {
    [self.autocompleteNavigationController popViewControllerAnimated:YES];
    [self bangButtonPressed];
}

-(IBAction)orangeButtonPressed:(UIButton*)sender {
    [self searchControllerLeftButtonPressed];
}

-(void)setState:(DDGSearchControllerState)searchControllerState {
    [self setState:searchControllerState animationDuration:0];
}

-(void)setState:(DDGSearchControllerState)searchControllerState animationDuration:(NSTimeInterval)duration {
    if (_state == searchControllerState)
        return;
    
	_state = searchControllerState;
    [self view];
    
    if(_state == DDGSearchControllerStateHome) {
        self.searchBar.showsCancelButton = NO;
        self.searchBar.showsLeftButton = NO;
        self.homeController.alternateButtonBar = nil;
        self.searchBar.progressView.percentCompleted = 100;
        self.searchBar.showsBangButton = FALSE;
        [self.searchBar.searchField setRightButtonMode:DDGAddressBarRightButtonModeDefault];
        if (duration > 0) [self.searchBar layoutIfNeeded:duration];
        
        [self clearAddressBar];
        
    } else if (_state == DDGSearchControllerStateWeb) {
        self.searchBar.showsCancelButton = NO;
        self.searchBar.showsLeftButton = YES;
        self.searchBar.showsBangButton = NO;
        self.homeController.alternateButtonBar = self.customToolbar;
        
        if (duration > 0) [self.searchBar layoutIfNeeded:duration];
    }
}

-(void)updateToolbars:(BOOL)animated
{
//    BOOL showBackButton = (viewController != [navigationController.viewControllers objectAtIndex:0]);
//    [self.searchBar setShowsLeftButton:showBackButton animated:YES];
    NSTimeInterval duration = (animated) ? 0.3 : 0.0;
    
    [self.homeController setAlternateButtonBar:self.navController.topViewController.alternateToolbar animated:animated];
    [self setState:([self canPopContentViewController]) ? DDGSearchControllerStateWeb : DDGSearchControllerStateHome animationDuration:duration];
    [self setSearchBarOrangeButtonImage];
}


-(void)stopOrReloadButtonPressed {
    [self searchControllerStopOrReloadButtonPressed];
}

-(void)webViewStartedLoading {
    if([self canPopContentViewController]) {
        [self.searchBar.searchField setRightButtonMode:DDGAddressBarRightButtonModeStop];
    }
}

-(void)webViewCancelledLoading {
    if([self canPopContentViewController]) {
        [self.searchBar.searchField setRightButtonMode:DDGAddressBarRightButtonModeRefresh];
        [self.searchBar cancel];
    }
}

-(void)webViewFinishedLoading {
    if([self canPopContentViewController]) {
        [self.searchBar.searchField setRightButtonMode:DDGAddressBarRightButtonModeRefresh];
        [self.searchBar finish];
    }
}

-(void)webViewCanGoBack:(BOOL)canGoBack {
    if(canGoBack) {
        [self.searchBar.orangeButton setImage:[[UIImage imageNamed:@"Back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                     forState:UIControlStateNormal];
    } else {
        [self setSearchBarOrangeButtonImage];
    }
}

-(void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:TRUE];
}

-(void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    [self.searchBar.progressView setPercentCompleted:((NSUInteger)(progress * 100)) animated:animated];
}

#pragma mark - Helper methods

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
        
        if (nil == self.emailPredicate) {
            NSPredicate *regExPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
            self.emailPredicate = regExPredicate;
        }
        
        if ([self.emailPredicate evaluateWithObject:urlString]) {
            return nil;            
        }
        
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
            if ([query length] > 1)
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

#pragma mark - Nav controller delegate

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if(self.autocompleteNavigationController==navigationController) {
        if(!autocompleteOpen)
            return;
        BOOL showBackButton = (viewController != [navigationController.viewControllers objectAtIndex:0]);
        [self.searchBar setShowsLeftButton:showBackButton animated:YES];
    } else if(self.navController==navigationController) {
        self.autocompletePopover.dimmedBackgroundView = viewController.dimmableContentView;
        self.shadowView.hidden = [viewController isKindOfClass:DDGTabViewController.class];
    }
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if(self.navController==navigationController) {
        [self updateToolbars:animated];
        if(viewController==self.rootViewInNavigator) {
            [self.searchBar.searchField resetField];
            [self setProgress:1.0f animated:FALSE];
        }
    }
}

#pragma mark - View management

// set up and reveal the autocomplete view
-(void)revealAutocomplete {    
    // save search text in case user cancels input without navigating somewhere
    if(!oldSearchText) oldSearchText = self.searchBar.searchField.text;
    barUpdated = NO;
    
    [self.searchBar.searchField setRightButtonMode:DDGAddressBarRightButtonModeDefault];
    [self revealAutocomplete:YES animated:YES];
    
    [UIView animateWithDuration:0.2f animations:^{
        [self.searchBar setShowsBangButton:YES animated:FALSE];
        [self.searchBar setShowsLeftButton:NO animated:FALSE];
        [self.searchBar setShowsCancelButton:YES animated:FALSE];
        [self.searchBar layoutIfNeeded];
    }];
    
    autocompleteOpen = YES;
}

// cleans up the search field and dismisses
-(void)dismissAutocomplete {
    if (!autocompleteOpen)
        return;
    
    autocompleteOpen = NO;

    if(!barUpdated) {
        self.searchBar.searchField.text = oldSearchText;
        oldSearchText = nil;
    }
    [self.searchBar.searchField resignFirstResponder];
    if([_searchHandler respondsToSelector:@selector(searchControllerAddressBarWillCancel)])
        [_searchHandler searchControllerAddressBarWillCancel];
    
    [self revealAutocomplete:NO animated:YES];
    
    [self.bangInfoPopover dismissPopoverAnimated:YES];
    self.bangInfoPopover = nil;
    
    [UIView animateWithDuration:0.2f animations:^{
        if(self.state == DDGSearchControllerStateWeb) {
            [self.searchBar.searchField setRightButtonMode:DDGAddressBarRightButtonModeDefault];
        }
        
        [self.searchBar setShowsLeftButton:(self.navController.viewControllers.count > 1) animated:NO];
        [self.searchBar setShowsBangButton:NO animated:NO];
        [self.searchBar setShowsCancelButton:NO animated:NO];
        [self.searchBar layoutIfNeeded];
    }];

}

// fade in or out the autocomplete view- to be used when revealing/hiding autocomplete
- (void)revealAutocomplete:(BOOL)reveal animated:(BOOL)animated {
    if(self.autocompletePopover) {
        if(reveal) {
            self.autocompletePopover.intrusion = 4;
            CGRect autocompleteRect = self.autocompleteController.view.frame;
            autocompleteRect.origin.x = 0;
            autocompleteRect.origin.y = 0;
            autocompleteRect.size.width = self.searchBar.frame.size.width + 0;
            autocompleteRect.size.height = 490;
            self.autocompleteController.view.frame = autocompleteRect;
            self.autocompletePopover.preferredContentSize = autocompleteRect.size;
            [self.autocompletePopover presentPopoverFromView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
        } else {
            [self.autocompletePopover dismissPopoverAnimated:animated];
        }
    } else if(self.autocompleteNavigationController) {
        if(self.autocompleteController==[self.contentControllers lastObject]) return;
        if(reveal) {
            [self.autocompleteNavigationController viewWillAppear:animated];
        } else {
            [self.autocompleteNavigationController viewWillDisappear:animated];
        }
        
        if(animated) {
            [UIView animateWithDuration:0.25 animations:^{
                _background.alpha = (reveal ? 1.0 : 0.0);
            } completion:^(BOOL finished) {
                if(reveal) {
                    [self.autocompleteNavigationController viewDidAppear:animated];
                } else {
                    [self.autocompleteNavigationController viewDidDisappear:animated];
                }
            }];
        } else {
            _background.alpha = (reveal ? 1.0 : 0.0);
            if(reveal) {
                [self.autocompleteNavigationController viewDidAppear:animated];
            } else {
                [self.autocompleteNavigationController viewDidDisappear:animated];
            }
        }
    }
    
}

// fade in or out the input accessory– to be used on keyboard show/hide
-(void)revealInputAccessory:(BOOL)reveal animationDuration:(CGFloat)animationDuration {
//    if(reveal) {
//        [UIView animateWithDuration:animationDuration animations:^{
//            inputAccessory.alpha = 1.0;
//        } completion:^(BOOL finished) {
//            [self positionNavControllerForInputAccessoryForceHidden:NO];
//        }];
//    } else {
//        [self positionNavControllerForInputAccessoryForceHidden:YES];
//        [UIView animateWithDuration:animationDuration animations:^{
//            inputAccessory.alpha = 0.0;
//        }];
//    }
}

-(IBAction)cancelButtonPressed:(id)sender {
    [self dismissAutocomplete];
}

-(void)updateBarWithURL:(NSURL *)url {
    barUpdated = YES;
    NSString *query = [self queryFromDDGURL:url];
    self.searchBar.searchField.text = (query ? query : url.absoluteString);
}

-(void)clearAddressBar {
    self.searchBar.searchField.text = @"";
    [self.searchBar.searchField setRightButtonMode:DDGAddressBarRightButtonModeDefault];
    [self dismissAutocomplete];
}


#pragma mark - DDGPopoverViewControllerDelegate

- (void)popoverControllerDidDismissPopover:(DDGPopoverViewController *)popoverController {
    self.bangInfoPopover = nil;    
}

#pragma mark - Input accessory (the bang button/bar)

- (IBAction)hideBangTooltipForever:(id)sender {
    self.showBangTooltip = NO;
    [self.bangInfoPopover dismissPopoverAnimated:YES];
    self.bangInfoPopover = nil;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DDGSettingSuppressBangTooltip];
}

- (IBAction)performExampleQuery:(id)sender;
{
    //Perform an example query.
    [self performSearch:@"!amazon lego"];
    
    //Dismiss the tooltip forever.
    [self hideBangTooltipForever:nil];
}

-(void)bangButtonPressed {
    DDGAddressBarTextField *searchField = self.searchBar.searchField;
    
//    if (self.showBangTooltip && nil == self.bangInfoPopover) {
//        if (!self.bangInfo)
//            [[NSBundle mainBundle] loadNibNamed:@"DDGBangInfo" owner:self options:nil];
//        
//        UIViewController *viewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
//        viewController.view = self.bangInfo;
//        CGRect frame = self.bangInfo.frame;
//        frame.size.width = self.view.bounds.size.width - 20.0;
//        
//        CGRect textRect = CGRectInset(frame, 12.0, 0.0);
//        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
//        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
//        CGSize textSize = CGRectIntegral([self.bangTextView.text boundingRectWithSize:CGSizeMake(textRect.size.width, MAXFLOAT)
//                                                               options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
//                                                            attributes:@{NSFontAttributeName: self.bangTextView.font,
//                                                                         NSParagraphStyleAttributeName: paragraphStyle}
//                                                               context:nil]).size;
//        
//        frame.size.height = textSize.height + 28.0;
//        if(frame.size.height < self.bangInfo.frame.size.height) {
//            frame.size.height = self.bangInfo.frame.size.height;
//        }
//        
//        viewController.preferredContentSize = frame.size;
//        
//        DDGPopoverViewController *popover = [[DDGPopoverViewController alloc] initWithContentViewController:viewController
//                                                                                    andTouchPassthroughView:self.view];
//        popover.delegate = self;
//        CGRect rect = [self.view convertRect:self.searchBar.bangButton.frame fromView:self.searchBar.bangButton.superview];
//        [popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//        self.bangInfoPopover = popover;
//    }
    
    NSString *text = searchField.text;
    NSString *textToAdd;
    if(text.length==0 || [text characterAtIndex:text.length-1]==' ') {
        textToAdd = @"!";
    } else {
        textToAdd = @" !";
    }
    
    [self textField:searchField shouldChangeCharactersInRange:NSMakeRange(text.length, 0) replacementString:textToAdd];
    searchField.text = [searchField.text stringByAppendingString:textToAdd];
    [self.autocompleteController searchFieldDidChange:nil];
}

-(void)bangAutocompleteButtonPressed:(UIButton *)sender {
    DDGAddressBarTextField *searchField = self.searchBar.searchField;
    if(currentWordRange.location == NSNotFound) {
        if(searchField.text.length == 0)
            searchField.text = sender.titleLabel.text;
        else
            [searchField setText:[searchField.text stringByAppendingFormat:@" %@",sender.titleLabel.text]];
    } else {
        [searchField setText:[searchField.text stringByReplacingCharactersInRange:currentWordRange withString:sender.titleLabel.text]];
    }
}

#pragma mark - Text field delegate

-(void)searchFieldDidChange:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingAutocomplete]) {
        // autocomplete only when enabled
        DDGDuckViewController *autocompleteViewController = [self.autocompleteNavigationController.viewControllers objectAtIndex:0];
        if(self.autocompleteController!=nil) {
            [self.autocompleteController searchFieldDidChange:self.searchBar.searchField];
        } else {
            if(self.autocompleteNavigationController.topViewController != autocompleteViewController) {
                [self.autocompleteNavigationController popToRootViewControllerAnimated:NO];
            }
            [autocompleteViewController searchFieldDidChange:self.searchBar.searchField];
        }
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // find the word that the cursor is currently in and update the bang bar based on it
    
    /* Prevent the search text being prefixed with a space */
    if (range.location == 0) {
        if (string.length > 0) {
            if ([[string substringWithRange:NSMakeRange(0, 1)] isEqualToString:@" "]) {
                return NO;
            }
        }
    }
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if(newString.length == 0) {
        currentWordRange = NSMakeRange(NSNotFound, 0);
        return YES; // there's nothing we can do with an empty string
    }
    
    // find word beginning
    unsigned long wordBeginning;
    for(wordBeginning = range.location + string.length; wordBeginning; wordBeginning--) {
        if(wordBeginning == 0 || [newString characterAtIndex:wordBeginning - 1] == ' ')
            break;
    }

    // find word end
    unsigned long wordEnd;
    for(wordEnd = wordBeginning; wordEnd < newString.length; wordEnd++) {
        if(wordEnd == newString.length || [newString characterAtIndex:wordEnd] == ' ')
            break;
    }
    
    currentWordRange = NSMakeRange(wordBeginning, wordEnd-wordBeginning);
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	// save search text in case user cancels input without navigating somewhere
    if(!oldSearchText)
        oldSearchText = textField.text;
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if([_searchHandler respondsToSelector:@selector(searchControllerAddressBarWillOpen)])
        [_searchHandler searchControllerAddressBarWillOpen];
    
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentWordRange = NSMakeRange(NSNotFound, 0);
	// only open autocomplete if not already open and it is enabled for use
    if(!autocompleteOpen && [[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingAutocomplete])
        [self revealAutocomplete];
    [textField selectAll:self];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSString *s = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (![s length]) {
		textField.text = nil;
		return NO;
	}
	
    [self performSearch:self.searchBar.searchField.text];
	
	return YES;
}

- (void)performSearch:(NSString *)query;
{
    if (query.length > 0) {
        [self.historyProvider logSearchResultWithTitle:query];
    }
    
    __weak DDGSearchController *weakSelf = self;
    [self dismissKeyboard:^(BOOL completed) {
        [weakSelf loadQueryOrURL:query];
        [weakSelf dismissAutocomplete];
    }];
    
    oldSearchText = nil;
}

-(void)dismissKeyboard:(void (^)(BOOL completed))completion {
    if ([self.searchBar.searchField isFirstResponder]) {
        self.keyboardDidHideBlock = completion;
        [self.searchBar.searchField resignFirstResponder];
    } else {
        completion(YES);
    }
}

@end
