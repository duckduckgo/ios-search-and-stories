//
//  DDGSearchController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDGSearchHandler.h"

typedef enum {
	DDGSearchControllerStateHome = 0,
	DDGSearchControllerStateWeb
} DDGSearchControllerState;

@class DDGSearchSuggestionsProvider, DDGSearchHistoryProvider, DDGAddressBarTextField, DDGInputAccessoryView;
@interface DDGSearchController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate> {
	CGRect keyboardRect;
        
    NSString *oldSearchText;
    BOOL barUpdated;
    
    DDGSearchSuggestionsProvider *suggestionsProvider;
    DDGSearchHistoryProvider *historyProvider;
    
    UIButton *stopOrReloadButton;
    DDGInputAccessoryView *inputAccessory;
    NSRange currentWordRange;
    NSMutableArray *unusedBangButtons;
}

@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic, weak) IBOutlet DDGAddressBarTextField *searchField;
@property(nonatomic, weak) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property(nonatomic, weak) IBOutlet UIView *background;
@property(nonatomic, strong) IBOutlet UITableViewCell *loadedCell;

@property(nonatomic, weak) UIViewController *containerViewController;
@property(nonatomic, assign) DDGSearchControllerState state;
@property(nonatomic, weak) id<DDGSearchHandler> searchHandler;

@property(nonatomic, assign) BOOL childViewControllerVisible;

-(id)initWithNibName:(NSString *)nibNameOrNil containerViewController:(UIViewController *)container;

-(IBAction)leftButtonPressed:(UIButton*)sender;
-(void)updateBarWithURL:(NSURL *)url;
-(void)resetOmnibar;

-(NSString *)validURLStringFromString:(NSString *)urlString;
-(BOOL)isQuery:(NSString *)queryOrURL;

// the web view needs to call these at the appropriate times to update the stop/reload button
-(void)webViewStartedLoading;
-(void)webViewFinishedLoading;
-(void)setProgress:(CGFloat)progress;

-(void)loadQueryOrURL:(NSString *)queryOrURL;
-(NSString *)queryFromDDGURL:(NSURL *)url;

@end