//
//  DDGSearchController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+DDGSearchController.h"
#import "DDGSearchHandler.h"
#import "DDGSearchBar.h"
#import "DDGHomeViewController.h"
#import "DDGToolbar.h"

typedef enum {
	DDGSearchControllerStateUnknown = 0,
    DDGSearchControllerStateHome,
	DDGSearchControllerStateWeb
} DDGSearchControllerState;

@class DDGSearchSuggestionsProvider, DDGHistoryProvider;

@interface DDGSearchController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, DDGSearchHandler, UIGestureRecognizerDelegate> {
    NSString *oldSearchText;
    BOOL barUpdated;
    BOOL autocompleteOpen;
    
    NSRange currentWordRange;
    NSMutableArray *unusedBangButtons;
}

@property (nonatomic, strong) DDGToolbar *toolbarView;
@property (nonatomic, weak) IBOutlet DDGSearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UIView *searchBarWrapper;
@property (nonatomic, weak) IBOutlet UIView *background;
@property (nonatomic, weak) IBOutlet UIView *bangInfo;
@property (weak, nonatomic) IBOutlet UITextView *bangTextView;
@property (nonatomic, weak) IBOutlet UIButton *bangQueryButton;
@property (nonatomic, strong) NSArray *contentControllers;
@property (nonatomic, strong) UINavigationController *autocompleteNavigationController;
@property (nonatomic, strong) DDGHomeViewController* homeController;
@property (nonatomic, assign) DDGSearchControllerState state;
@property (nonatomic, weak, readonly) id<DDGSearchHandler> searchHandler;
@property (nonatomic) BOOL shouldPushSearchHandlerEvents;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *barWrapperHeightConstraint;
@property (nonatomic) BOOL navBarIsCompact;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundTopWrapperConstraint;
@property (nonatomic, strong) UINavigationController *navController;

- (void)setContentViewController:(UIViewController *)contentController tabPosition:(NSUInteger)tabPosition animated:(BOOL)animated;
- (void)pushContentViewController:(UIViewController *)contentController animated:(BOOL)animated;
- (void)popContentViewControllerAnimated:(BOOL)animated;
- (BOOL)canPopContentViewController;

-(IBAction)bangButtonPressed:(UIButton*)sender;
-(IBAction)orangeButtonPressed:(UIButton*)sender;
-(IBAction)actionButtonPressed:(id)sender;
-(IBAction)cancelButtonPressed:(id)sender;
- (IBAction)hideBangTooltipForever:(id)sender;

-(id)initWithHomeController:(DDGHomeViewController*)homeController
       managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

// managing the search controller
-(void)updateBarWithURL:(NSURL *)url;
-(void)clearAddressBar;
-(void)dismissAutocomplete;

// the web view needs to call these at the appropriate times
-(void)webViewStartedLoading;
-(void)webViewFinishedLoading;
-(void)webViewCancelledLoading;
-(void)setProgress:(CGFloat)progress;
-(void)webViewCanGoBack:(BOOL)canGoBack;

// helper methods
-(NSString *)validURLStringFromString:(NSString *)urlString;
-(BOOL)isQuery:(NSString *)queryOrURL;
+(NSString *)queryFromDDGURL:(NSURL *)url;

-(void)searchFieldDidChange:(id)sender;
-(void)dismissKeyboard:(void (^)(BOOL completed))completion;
- (BOOL)doesViewControllerExistInTheNavStack:(UIViewController*)viewController;


// Navbar Methods
- (void)compactNavigationBar;
- (void)expandNavigationBar;

@end