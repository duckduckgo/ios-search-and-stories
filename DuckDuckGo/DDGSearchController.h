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
@interface DDGSearchController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
{
	
	IBOutlet UITableViewCell	*loadedCell;
	
    __weak IBOutlet UITableView *tableView;
    __weak IBOutlet DDGAddressBarTextField *searchField;
	__weak IBOutlet UIButton *searchButton;
    __weak IBOutlet UIView *background;
    
    
    DDGSearchControllerState state;
	CGRect keyboardRect;
    
    id<DDGSearchHandler> __weak searchHandler;
    
    NSString *oldSearchText;
    BOOL barUpdated;
    
    DDGSearchSuggestionsProvider *suggestionsProvider;
    DDGSearchHistoryProvider *historyProvider;
    
    UIButton *stopOrReloadButton;
    DDGInputAccessoryView *inputAccessory;
    NSRange currentWordRange;
    
    NSMutableArray *unusedBangButtons;
    
    NSDate *loadingBeginTime;
    NSTimer *loadingTimer;
}

@property(nonatomic, strong) IBOutlet UITableViewCell *loadedCell;

@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic, weak) IBOutlet DDGAddressBarTextField *searchField;
@property(nonatomic, weak) IBOutlet UIButton *searchButton;
@property(nonatomic, weak) IBOutlet UIView *background;

@property(nonatomic, assign) DDGSearchControllerState state;
@property(nonatomic, weak) id<DDGSearchHandler> searchHandler;

-(id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent;

-(IBAction)leftButtonPressed:(UIButton*)sender;
-(void)updateBarWithURL:(NSURL *)url;
-(void)resetOmnibar;

-(NSString *)validURLStringFromString:(NSString *)urlString;
-(BOOL)isQuery:(NSString *)queryOrURL;

// the web view needs to call these at the appropriate times to update the stop/reload button
-(void)webViewStartedLoading;
-(void)webViewFinishedLoading;

@end