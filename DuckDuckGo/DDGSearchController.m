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
#import "DDGAutocompleteViewController.h"
#import "ECSlidingViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGHistoryProvider.h"
#import "DDGWebViewController.h"
#import "DDGPanGestureRecognizer.h"

#import "NSMutableString+DDGDumpView.h"
#import "DDGPopoverViewController.h"

NSString * const emailRegEx =
@"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

@interface DDGSearchController () <DDGPopoverViewControllerDelegate>
@property (nonatomic, weak, readwrite) id<DDGSearchHandler> searchHandler;
@property (nonatomic, strong) DDGHistoryProvider *historyProvider;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray *controllers;
@property (nonatomic, getter = isDraggingTopViewController) BOOL draggingTopViewController;
@property (nonatomic, copy) void (^keyboardDidHideBlock)(BOOL completed);
@property (nonatomic, strong) DDGPopoverViewController *bangInfoPopover;
@property (nonatomic, strong) NSPredicate *emailPredicate;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic) BOOL showBangTooltip;
@property (nonatomic, getter = isTransitioningViewControllers) BOOL transitioningViewControllers;
@end

@implementation DDGSearchController

-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext; {
	self = [super initWithNibName:@"DDGSearchController" bundle:nil];
    
	if (self) {
        self.searchHandler = searchHandler;
        self.managedObjectContext = managedObjectContext;
        self.controllers = [NSMutableArray arrayWithCapacity:2];
        self.showBangTooltip = ![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingSuppressBangTooltip];
	}
	return self;
}

- (void)dealloc {
    if (nil != self.keyboardDidHideBlock)
        self.keyboardDidHideBlock(NO);
    self.keyboardDidHideBlock = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.view removeFromSuperview];
}

- (CGRect)contentRect {
    [self view];
    
    CGRect searchbarRect = self.searchBar.frame;
    CGRect frame = self.view.bounds;
    CGRect intersection = CGRectIntersection(frame, searchbarRect);
    frame.origin.y = intersection.origin.y + intersection.size.height;
    frame.size.height = frame.size.height - frame.origin.y;
    
    return frame;
}

- (void)setSearchBarOrangeButtonImage {
    
    UIImage *image = nil;
    
    if ([self.controllers count] > 1) {
        UIViewController *incommingViewController = [self.controllers objectAtIndex:self.controllers.count-2];
        image = [incommingViewController searchControllerBackButtonIconDDG];
    }
    
    if (image == nil)
        image = [UIImage imageNamed:@"button_menu_glyph_under"];
    
    [self.searchBar.orangeButton setImage:image forState:UIControlStateNormal];
    [self.searchBar.orangeButton setImage:nil forState:UIControlStateHighlighted];
}

- (void)pushContentViewController:(UIViewController *)contentController animated:(BOOL)animated {
    
    if (self.isTransitioningViewControllers)
        return;
    
    NSTimeInterval duration = (animated) ? 0.3 : 0.0;    
    
    [self.controllers addObject:contentController];
    [self setState:([self canPopContentViewController]) ? DDGSearchControllerStateWeb : DDGSearchControllerStateHome animationDuration:duration];
    [self setSearchBarOrangeButtonImage];
    
    NSInteger count = self.controllers.count-1;
    for (NSInteger i=0; i<count; i++)
        [self clearScrollsToTop:[[self.controllers objectAtIndex:i] view]];
    [contentController reenableScrollsToTop];
    
    self.transitioningViewControllers = YES;
    __weak DDGSearchController *weakSelf = self;
    [self.pageViewController setViewControllers:@[contentController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:animated
                                     completion:^(BOOL finished) {
                                         weakSelf.transitioningViewControllers = NO;
                                     }];
    
    if (self.controllers.count == 1)
        [self configurePanGestureForViewController:contentController];
}

- (void)configurePanGestureForViewController:(UIViewController *)viewController {
    UIGestureRecognizer *panGesture = self.slidingViewController.panGesture;
    if (nil == panGesture)
        return;
    
    for (UIGestureRecognizer *g in viewController.view.gestureRecognizers) {
        if ([g isKindOfClass:[UIPanGestureRecognizer class]])
            [g requireGestureRecognizerToFail:panGesture];
    }
    [viewController.view addGestureRecognizer:panGesture];
}

- (BOOL)canPopContentViewController {
    return ([self.controllers count] > 1 && !self.isTransitioningViewControllers);
}

- (void)popContentViewControllerAnimated:(BOOL)animated {
    if ([self canPopContentViewController]) {
        NSTimeInterval duration = (animated) ? 0.3 : 0.0;
        
        UIViewController *popped = [self.controllers lastObject];
        [self clearScrollsToTop:popped.view];
        
        [self.controllers removeLastObject];
        [self setState:([self canPopContentViewController]) ? DDGSearchControllerStateWeb : DDGSearchControllerStateHome animationDuration:duration];        
        [self setSearchBarOrangeButtonImage];        
        
        UIViewController *contentController = [self.controllers lastObject];
        [contentController reenableScrollsToTop];
        
        self.transitioningViewControllers = YES;        
        __weak DDGSearchController *weakSelf = self;
        [self.pageViewController setViewControllers:@[contentController]
                                          direction:UIPageViewControllerNavigationDirectionReverse
                                           animated:animated
                                         completion:^(BOOL finished) {
                                             weakSelf.transitioningViewControllers = NO;
                                         }];
        
        [contentController reenableScrollsToTop];
    }
}

- (NSArray *)contentControllers {
    return [self.controllers copy];
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
	if (self.view.frame.origin.y < 0.0)
	{
//		// uncoment these lines to get/see a nicely formatted view hiearchy dump
//		NSMutableString *s = [NSMutableString string];
//		[s dumpView:self.view atIndent:0];
//		NSLog (@"DDGSearchController:viewWILLLayoutSubviews \n%@", s);

		// repair damage occuring deep in the bowels of this view hiearchy
		CGRect r = self.view.frame;
		r.origin.y = 0.0;
		self.view.frame = r;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DDGAutocompleteViewController *autocompleteVC = [[DDGAutocompleteViewController alloc] initWithStyle:UITableViewStylePlain];
    autocompleteVC.historyProvider = self.historyProvider;
    self.autocompleteNavigationController = [[UINavigationController alloc] initWithRootViewController:autocompleteVC];
    _autocompleteNavigationController.delegate = self;
    [self addChildViewController:_autocompleteNavigationController];
    [_background addSubview:_autocompleteNavigationController.view];
    _autocompleteNavigationController.view.frame = _background.bounds;
    [_autocompleteNavigationController didMoveToParentViewController:self];
    // [_autocompleteNavigationController pushViewController:autocompleteVC animated:NO];
    
    [self revealBackground:NO animated:NO];
    
    DDGAddressBarTextField *searchField = self.searchBar.searchField;
    
    searchField.placeholder = NSLocalizedString(@"SearchPlaceholder", nil);
    [searchField addTarget:self action:@selector(searchFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    stopOrReloadButton = [[UIButton alloc] init];
    stopOrReloadButton.frame = CGRectMake(0, 0, 31, 31);
    [stopOrReloadButton addTarget:self action:@selector(stopOrReloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    unusedBangButtons = [[NSMutableArray alloc] initWithCapacity:50];    
    
    [self createInputAccessory];
    
	searchField.rightViewMode = UITextFieldViewModeAlways;
	searchField.leftViewMode = UITextFieldViewModeAlways;
	searchField.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spacer8x16.png"]];
	searchField.delegate = self;    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                               navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                             options:@{
                                                       UIPageViewControllerOptionInterPageSpacingKey: @10.f
                                                }];
    pageViewController.delegate = self;
    pageViewController.dataSource = self;
    
    pageViewController.view.backgroundColor = [UIColor colorWithRed:0.200 green:0.212 blue:0.251 alpha:1.000];
    pageViewController.view.frame = [self contentRect];
    
    [self addChildViewController:pageViewController];
    [self.view insertSubview:pageViewController.view belowSubview:self.background];
    [pageViewController didMoveToParentViewController:self];
    
    self.pageViewController = pageViewController;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewDidUnload {
    [self setAutocompleteNavigationController:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    NSAssert(self.state != DDGSearchControllerStateUnknown, nil);
    
    [self configurePanGestureForViewController:[self.controllers objectAtIndex:0]];
}

#pragma mark - UIPageViewControllerDelegate, UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger i = [self.controllers indexOfObject:viewController];
    if (i==NSNotFound || i == 0) {
        return nil;
    }
    
    return self.controllers[i-1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger i = [self.controllers indexOfObject:viewController];
    if (i==NSNotFound || i == self.controllers.count -1) {
        return nil;
    }
    
    return self.controllers[i+1];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    self.transitioningViewControllers = YES;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    self.transitioningViewControllers = NO;
    if (completed) {
        UIViewController *viewController = [previousViewControllers lastObject];
        NSUInteger index = [self.controllers indexOfObject:viewController];
        if (index != NSNotFound) {
            NSRange range = NSMakeRange(index, self.controllers.count - index);
            NSArray *poppedControllers = [self.controllers subarrayWithRange:range];
            for (UIViewController *v in poppedControllers) {
                [self clearScrollsToTop:v.view];
            }
            [self.controllers removeObjectsInRange:range];
        }        
        [[self.controllers lastObject] reenableScrollsToTop];
        [self setState:([self canPopContentViewController]) ? DDGSearchControllerStateWeb : DDGSearchControllerStateHome animationDuration:0.2];
        [self setSearchBarOrangeButtonImage];
    }
}

#pragma mark - Keyboard notifications

- (void)slidingViewTopDidAnchorRight:(NSNotification *)notification {
    [self.searchBar.searchField resignFirstResponder];
}

-(void)keyboardWillShow:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slidingViewTopDidAnchorRight:) name:ECSlidingViewTopDidAnchorRight object:self.slidingViewController];
    [self keyboardWillShow:YES notification:notification];
}

-(void)keyboardWillHide:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ECSlidingViewTopDidAnchorRight object:self.slidingViewController];
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
            CGRect f = self.view.frame;
            
            if(show)
                f.size.height = self.view.superview.bounds.size.height - f.origin.y - keyboardEnd.size.height;
            else
                f.size.height = self.view.superview.bounds.size.height - f.origin.y;
            
            self.view.frame = f;
        });
                
    } else {
        double animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        [self revealInputAccessory:show animationDuration:animationDuration];
        
        UIViewAnimationCurve curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        UIViewAnimationOptions options = 0;
        switch (curve) {
            case UIViewAnimationCurveEaseIn:
                options = UIViewAnimationOptionCurveEaseIn;
                break;
            case UIViewAnimationCurveEaseInOut:
                options = UIViewAnimationOptionCurveEaseInOut;
                break;
            case UIViewAnimationCurveEaseOut:
                options = UIViewAnimationOptionCurveEaseOut;
                break;
            case UIViewAnimationCurveLinear:
                options = UIViewAnimationOptionCurveLinear;
                break;
            default:
                options = UIViewAnimationOptionCurveEaseInOut;
                break;
        }

        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:options
                         animations:^{
                             CGRect f = self.view.frame;
                             f.size.height = keyboardEnd.origin.y - f.origin.y;
                             self.view.frame = f;
                         } completion:nil];
    }
}

#pragma mark - DDGSearchHandler

-(void)searchControllerStopOrReloadButtonPressed {
    UIViewController *contentViewController = [self.controllers lastObject];
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        UIViewController <DDGSearchHandler> *searchHandler = (UIViewController <DDGSearchHandler> *)contentViewController;
        if([searchHandler respondsToSelector:@selector(searchControllerStopOrReloadButtonPressed)])
            [searchHandler searchControllerStopOrReloadButtonPressed];
    } else {
        if([_searchHandler respondsToSelector:@selector(searchControllerStopOrReloadButtonPressed)])
            [_searchHandler searchControllerStopOrReloadButtonPressed];
    }
}

-(void)searchControllerActionButtonPressed {
    UIViewController *contentViewController = [self.controllers lastObject];
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        UIViewController <DDGSearchHandler> *searchHandler = (UIViewController <DDGSearchHandler> *)contentViewController;
        if([searchHandler respondsToSelector:@selector(searchControllerActionButtonPressed)])
            [searchHandler searchControllerActionButtonPressed];
    } else {
        if([_searchHandler respondsToSelector:@selector(searchControllerActionButtonPressed)])
            [_searchHandler searchControllerActionButtonPressed];
    }
}

-(void)searchControllerLeftButtonPressed {
    [self.searchBar.searchField resignFirstResponder];
    UIViewController *contentViewController = [self.controllers lastObject];
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        [(UIViewController <DDGSearchHandler> *)contentViewController searchControllerLeftButtonPressed];
    } else {
        if ([self.controllers count] > 1)
            [self popContentViewControllerAnimated:YES];
        else
            [_searchHandler searchControllerLeftButtonPressed];
    }
}

-(void)loadQueryOrURL:(NSString *)queryOrURLString {
    UIViewController *contentViewController = [self.controllers lastObject];
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
    UIViewController *contentViewController = [self.controllers lastObject];
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
    UIViewController *contentViewController = [self.controllers lastObject];
    if ([contentViewController conformsToProtocol:@protocol(DDGSearchHandler)]) {
        [(UIViewController <DDGSearchHandler> *)contentViewController prepareForUserInput];
    } else {
        [_searchHandler prepareForUserInput];
    }
}

#pragma mark - Interactions with search handler

- (IBAction)actionButtonPressed:(id)sender {
    [self searchControllerActionButtonPressed];
}

-(IBAction)bangButtonPressed:(UIButton*)sender {
    [_autocompleteNavigationController popViewControllerAnimated:YES];
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
//        [self.searchBar.leftButton setImage:[UIImage imageNamed:@"button_menu-default"] forState:UIControlStateNormal];
//        [self.searchBar.leftButton setImage:[UIImage imageNamed:@"button_menu-onclick"] forState:UIControlStateHighlighted];
        
        self.searchBar.showsCancelButton = NO;
        self.searchBar.showsRightButton = NO;
        self.searchBar.showsLeftButton = YES;

        if (duration > 0)
            [self.searchBar layoutIfNeeded:duration];
        
        [self clearAddressBar];
        
    } else if (_state == DDGSearchControllerStateWeb) {
//        [self.searchBar.leftButton setImage:[UIImage imageNamed:@"home_button.png"] forState:UIControlStateNormal];
//        [self.searchBar.leftButton setImage:nil forState:UIControlStateHighlighted];
        
        UIViewController *topViewController = [self.controllers lastObject];
        BOOL showsRightButton = [topViewController respondsToSelector:@selector(searchControllerActionButtonPressed)];
        
        self.searchBar.showsCancelButton = NO;
        self.searchBar.showsLeftButton = YES;
        self.searchBar.showsRightButton = showsRightButton;        
        self.searchBar.searchField.rightView = stopOrReloadButton;
        
        if (duration > 0)
            [self.searchBar layoutIfNeeded:duration];        
    }
}

-(void)stopOrReloadButtonPressed {
    [self searchControllerStopOrReloadButtonPressed];
}

-(void)webViewStartedLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
}

-(void)webViewCancelledLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];
    [self.searchBar.searchField cancel];
}

-(void)webViewFinishedLoading {
    [stopOrReloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];
    [self.searchBar.searchField finish];
}

-(void)webViewCanGoBack:(BOOL)canGoBack {
    if(canGoBack)
        [self.searchBar.orangeButton setImage:[UIImage imageNamed:@"button_menu_glyph_back"] forState:UIControlStateNormal];
    else
        [self setSearchBarOrangeButtonImage];
}

-(void)setProgress:(CGFloat)progress {
    [self.searchBar.searchField setProgress:progress];
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
    if(!autocompleteOpen)
        return;
    
    BOOL showBackButton = (viewController != [navigationController.viewControllers objectAtIndex:0]);
    [self.searchBar setShowsLeftButton:showBackButton animated:YES];
}

#pragma mark - View management

// set up and reveal the autocomplete view
-(void)revealAutocomplete {    
    // save search text in case user cancels input without navigating somewhere
    if(!oldSearchText)
        oldSearchText = self.searchBar.searchField.text;
    barUpdated = NO;
    
    if(![self isQuery:self.searchBar.searchField.text]) {
        [self clearAddressBar];
    }
    
    self.searchBar.searchField.rightView = nil;
    [self revealBackground:YES animated:YES];
    
    [self.searchBar setShowsBangButton:YES animated:YES];
            
    self.searchBar.showsLeftButton = YES;    
    self.searchBar.showsRightButton = NO;
    self.searchBar.showsCancelButton = YES;
    [self.searchBar layoutIfNeeded:0.25];
    
    self.slidingViewController.panGesture.enabled = NO;
    
    autocompleteOpen = YES;
}

// cleans up the search field and dismisses
-(void)dismissAutocomplete {
    if (!autocompleteOpen)
        return;
    
    autocompleteOpen = NO;

    self.slidingViewController.panGesture.enabled = YES;
    
    [self.searchBar.searchField resignFirstResponder];
    if(!barUpdated) {
        self.searchBar.searchField.text = oldSearchText;
        oldSearchText = nil;
    }
    if([_searchHandler respondsToSelector:@selector(searchControllerAddressBarWillCancel)])
        [_searchHandler searchControllerAddressBarWillCancel];
    
    [self revealBackground:NO animated:YES];
    if(self.state == DDGSearchControllerStateWeb)
        self.searchBar.searchField.rightView = stopOrReloadButton;
        
    [self.searchBar setShowsBangButton:NO animated:YES];
    
    [self.bangInfoPopover dismissPopoverAnimated:YES];
    self.bangInfoPopover = nil;
    
    self.searchBar.showsLeftButton = YES;
    self.searchBar.showsRightButton = (self.state == DDGSearchControllerStateWeb);
    self.searchBar.showsCancelButton = NO;
    [self.searchBar layoutIfNeeded:0.25];
}

// fade in or out the autocomplete view- to be used when revealing/hiding autocomplete
- (void)revealBackground:(BOOL)reveal animated:(BOOL)animated {
    
    if(reveal)
        [_autocompleteNavigationController viewWillAppear:animated];
    else
        [_autocompleteNavigationController viewWillDisappear:animated];
    
    if(animated)
        [UIView animateWithDuration:0.25 animations:^{
            _background.alpha = (reveal ? 1.0 : 0.0);
        } completion:^(BOOL finished) {
            if(reveal)
                [_autocompleteNavigationController viewDidAppear:animated];
            else
                [_autocompleteNavigationController viewDidDisappear:animated];
        }];
    else {
        _background.alpha = (reveal ? 1.0 : 0.0);
        if(reveal)
            [_autocompleteNavigationController viewDidAppear:animated];
        else
            [_autocompleteNavigationController viewDidDisappear:animated];
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
    self.searchBar.searchField.rightView = nil;
}

#pragma mark - DDGPopoverViewControllerDelegate

- (void)popoverControllerDidDismissPopover:(DDGPopoverViewController *)popoverController {
    self.bangInfoPopover = nil;    
}

#pragma mark - Input accessory (the bang button/bar)

-(void)createInputAccessory {
    inputAccessory = [[DDGInputAccessoryView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 46, self.view.bounds.size.width, 46)];
    inputAccessory.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    inputAccessory.alpha = 0.0;
    [self.view addSubview:inputAccessory];
    
    // add bang button
    UIButton *bangButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [bangButton setBackgroundImage:[UIImage imageNamed:@"bang_button.png"] forState:UIControlStateNormal];
    bangButton.frame = CGRectMake(0, 0, 46, 46);
    bangButton.tag = 103;
    [bangButton addTarget:self action:@selector(bangButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessory addSubview:bangButton];
    
    // add scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, inputAccessory.bounds.size.width, 46)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.contentSize = CGSizeMake(0, 46);
    scrollView.tag = 102;
    scrollView.hidden = YES;
    [inputAccessory addSubview:scrollView];
}

// if the input accessory isn't hidden, but is about to hide, you can set forceHidden to position nav controller as though input accessory is hidden. Use this e.g. when animating inputAccessory, so the nav controller shows up behind it.
-(void)positionNavControllerForInputAccessoryForceHidden:(BOOL)forceHidden {
    UIScrollView *scrollView = (UIScrollView *)[inputAccessory viewWithTag:102];
    
    CGRect f = _autocompleteNavigationController.view.frame;
    if(scrollView.hidden || inputAccessory.hidden || inputAccessory.alpha < 0.1 || forceHidden) {
        f.size.height = _autocompleteNavigationController.view.superview.bounds.size.height;
    } else {
        f.size.height = _autocompleteNavigationController.view.superview.bounds.size.height - 44.0;
    }
    _autocompleteNavigationController.view.frame = f;
}

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
    
    if (self.showBangTooltip && nil == self.bangInfoPopover) {
        if (!self.bangInfo)
            [[NSBundle mainBundle] loadNibNamed:@"DDGBangInfo" owner:self options:nil];
        
        UIViewController *viewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
        viewController.view = self.bangInfo;
        CGRect frame = self.bangInfo.frame;
        frame.size.width = self.view.bounds.size.width - 20.0;
        
        CGRect textRect = CGRectInset(frame, 12.0, 0.0);
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        CGSize textSize = CGRectIntegral([self.bangTextView.text boundingRectWithSize:CGSizeMake(textRect.size.width, MAXFLOAT)
                                                               options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:@{NSFontAttributeName: self.bangTextView.font,
                                                                         NSParagraphStyleAttributeName: paragraphStyle}
                                                               context:nil]).size;
        
        frame.size.height = textSize.height + 28.0;
        if(frame.size.height < self.bangInfo.frame.size.height)
            frame.size.height = self.bangInfo.frame.size.height;
        
        viewController.preferredContentSize = frame.size;
        
        DDGPopoverViewController *popover = [[DDGPopoverViewController alloc] initWithContentViewController:viewController];
        popover.delegate = self;
        CGRect rect = [self.view convertRect:self.searchBar.bangButton.frame fromView:self.searchBar.bangButton.superview];
        [popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        self.bangInfoPopover = popover;
    }
    
    NSString *text = searchField.text;
    NSString *textToAdd;
    if(text.length==0 || [text characterAtIndex:text.length-1]==' ')
        textToAdd = @"!";
    else
        textToAdd = @" !";
    
    [self textField:searchField shouldChangeCharactersInRange:NSMakeRange(text.length, 0) replacementString:textToAdd];
    searchField.text = [searchField.text stringByAppendingString:textToAdd];
    [(DDGAutocompleteViewController *)searchField.delegate searchFieldDidChange:nil];
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

-(void)loadSuggestionsForBang:(NSString *)bang {
    UIScrollView *scrollView = (UIScrollView *)[inputAccessory viewWithTag:102];
    
    NSArray *suggestions = [DDGBangsProvider bangsWithPrefix:bang];
    if(suggestions.count > 0) {
        scrollView.hidden = NO;
        [self positionNavControllerForInputAccessoryForceHidden:NO];
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
        CGSize titleSize = [suggestion sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
        
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
    [self positionNavControllerForInputAccessoryForceHidden:NO];
    
    UIButton *bangButton = (UIButton *)[inputAccessory viewWithTag:103];
    [bangButton setBackgroundImage:[UIImage imageNamed:@"bang_button.png"] forState:UIControlStateNormal];
    bangButton.hidden = NO;
}

#pragma mark - Text field delegate

-(void)searchFieldDidChange:(id)sender
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingAutocomplete])
	{
		// autocomplete only when enabled
		DDGAutocompleteViewController *autocompleteViewController = [_autocompleteNavigationController.viewControllers objectAtIndex:0];
		if(_autocompleteNavigationController.topViewController != autocompleteViewController)
			[_autocompleteNavigationController popToRootViewControllerAnimated:NO];
		
		[autocompleteViewController searchFieldDidChange:self.searchBar.searchField];
	}
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // find the word that the cursor is currently in and update the bang bar based on it
    
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

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if([_searchHandler respondsToSelector:@selector(searchControllerAddressBarWillOpen)])
        [_searchHandler searchControllerAddressBarWillOpen];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissAutocomplete)
                                                 name:ECSlidingViewUnderLeftWillAppear
                                               object:self.slidingViewController];
    
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentWordRange = NSMakeRange(NSNotFound, 0);
	// only open autocomplete if not already open and it is enabled for use
    if(!autocompleteOpen && [[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingAutocomplete])
        [self revealAutocomplete];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ECSlidingViewUnderLeftWillAppear
                                                  object:nil];
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
    if (query.length > 0)
        [self.historyProvider logSearchResultWithTitle:query];
    
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
