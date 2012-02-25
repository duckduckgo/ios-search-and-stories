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

@interface DDGSearchController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
{
	
	IBOutlet UITableViewCell	*loadedCell;
	
    IBOutlet UITableView	 *tableView;
    IBOutlet UITextField	 *__weak searchField;
	IBOutlet UIButton *__weak searchButton;
    IBOutlet UIView *__weak background;
    
	DDGSearchControllerState state;
	CGRect keyboardRect;
	
	id<DDGSearchHandler> __weak searchHandler;

	NSMutableURLRequest *serverRequest;
    NSMutableDictionary *suggestionsCache;
    NSString *oldSearchText;
    
    UIButton *stopOrReloadButton;
}

@property (nonatomic, strong) IBOutlet UITableViewCell *loadedCell;
@property (nonatomic, weak) IBOutlet	UITextField *searchField;
@property (nonatomic, weak) IBOutlet UIButton *searchButton;
@property(nonatomic, weak) IBOutlet UIView *background;

@property (nonatomic, strong) NSMutableURLRequest *serverRequest;
@property (nonatomic, assign) DDGSearchControllerState state;
@property (nonatomic, weak) id<DDGSearchHandler> searchHandler;

-(id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent;

-(IBAction)leftButtonPressed:(UIButton*)sender;
-(void)updateBarWithURL:(NSURL *)url;

// the web view needs to call these at the appropriate times to update the stop/reload button
-(void)webViewStartedLoading;
-(void)webViewFinishedLoading;

@end

UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeySnippet;
UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeyPhrase;
UIKIT_EXTERN NSString *const ksDDGSearchControllerServerKeyImage;