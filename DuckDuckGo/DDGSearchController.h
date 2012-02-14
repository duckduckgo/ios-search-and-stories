//
//  DDGSearchController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DataHelper.h"
#import "CacheController.h"
#import "DDGSearchHandler.h"

typedef enum {
	DDGSearchControllerStateHome = 0,
	DDGSearchControllerStateWeb
	
} DDGSearchControllerState;

@interface DDGSearchController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate>
{
	
	IBOutlet UITableViewCell	*loadedCell;
	
    IBOutlet UITableView		*tableView;
    IBOutlet UITextField		*__weak search;
	IBOutlet UIButton			*__weak searchButton;
    IBOutlet UIView *__weak background;
    
	DDGSearchControllerState state;
	CGRect						keyboardRect;
	
	id<DDGSearchHandler>		__weak searchHandler;
	
	NSMutableURLRequest			*serverRequest;
    NSMutableDictionary *suggestionsCache;
    NSString *oldSearchText;
}

@property (nonatomic, strong) NSMutableURLRequest			*serverRequest;

@property (nonatomic, strong) NSMutableDictionary			*serverCache;

@property (nonatomic, strong) IBOutlet		UITableViewCell	*loadedCell;
@property (nonatomic, readonly) IBOutlet	UITextField		*search;
@property (nonatomic, weak) IBOutlet		UIButton		*searchButton;
@property(nonatomic, weak) IBOutlet UIView *background;

@property (nonatomic, assign) DDGSearchControllerState state;

@property (nonatomic, weak) id<DDGSearchHandler> searchHandler;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent;

- (IBAction)searchButtonAction:(UIButton*)sender;


-(NSArray *)currentSuggestions;
-(void)downloadSuggestionsForSearchText:(NSString *)searchText;


// TODO (ishaan): make these private?
-(void)revealBackground:(BOOL)reveal animated:(BOOL)animated;
-(void)revealAutocomplete:(BOOL)reveal;
-(void)cancelInput;
-(void)updateBarWithURL:(NSURL *)url;
-(NSString *)validURLStringFromString:(NSString *)urlString;

@end

UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeySnippet; 
UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeyPhrase; 
UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeyImage; 

