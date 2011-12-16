//
//  DDGSearchController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DataHelper.h"
#import "CacheControl.h"
#import "DDGSearchProtocol.h"

enum eSearchState
{
	eViewStateHome = 0,
	eViewStateWebResults
	
};

@interface DDGSearchController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate, DataHelperDelegate>
{
	IBOutlet UITableView		*tableView;

	IBOutlet UITableViewCell	*loadedCell;
	IBOutlet UITextField		*search;
	IBOutlet UIButton			*searchButton;
	
	enum eSearchState			state;
	CGRect						kbRect;
	
	id<DDGSearchProtocol>		searchHandler;
	
	NSMutableURLRequest			*serverRequest;

	NSMutableDictionary			*serverCache;
	
	DataHelper					*dataHelper;
	NSTimer						*probeTimer;
}

@property (nonatomic, retain) NSMutableURLRequest			*serverRequest;

@property (nonatomic, retain) NSMutableDictionary			*serverCache;

@property (nonatomic, retain) IBOutlet		UITableViewCell	*loadedCell;
@property (nonatomic, readonly) IBOutlet	UITextField		*search;
@property (nonatomic, assign) IBOutlet		UIButton		*searchButton;

@property (nonatomic, assign) enum eSearchState			state;

@property (nonatomic, assign) id<DDGSearchProtocol>		searchHandler;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent;

- (IBAction)searchButtonAction:(UIButton*)sender;

- (void)autoCompleteReveal:(BOOL)reveal;

- (NSArray*)currentResultForItem:(NSUInteger)item;
- (void)cacheCurrentResult:(NSArray*)result forItem:(NSUInteger)item;

@end


UIKIT_EXTERN NSString *const ksDDGSearchControllerAction; 
UIKIT_EXTERN NSString *const ksDDGSearchControllerActionHome; 
UIKIT_EXTERN NSString *const ksDDGSearchControllerActionWeb; 

UIKIT_EXTERN NSString *const ksDDGSearchControllerSearchTerm; 
UIKIT_EXTERN NSString *const ksDDGSearchControllerSearchURL; 

UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeySnippet; 
UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeyPhrase; 
UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeyImage; 

