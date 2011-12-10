//
//  DDGSearchController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DDGSearchProtocol.h"

enum eSearchState
{
	eViewStateHome = 0,
	eViewStateWebResults
	
};

@interface DDGSearchController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UITableView		*tableView;

	IBOutlet UITableViewCell	*loadedCell;
	IBOutlet UITextField		*search;
	IBOutlet UIButton			*searchButton;
	
	enum eSearchState			state;
	CGRect						kbRect;
	
	id<DDGSearchProtocol>		searchHandler;
}

@property (nonatomic, retain) IBOutlet		UITableViewCell	*loadedCell;
@property (nonatomic, readonly) IBOutlet	UITextField		*search;
@property (nonatomic, assign) IBOutlet		UIButton		*searchButton;;

@property (nonatomic, assign) id<DDGSearchProtocol>		searchHandler;

- (id)initWithNibName:(NSString *)nibNameOrNil view:(UIView*)parent;

- (IBAction)searchButtonAction:(UIButton*)sender;
- (void)switchModeTo:(enum eSearchState)state;

- (void)autoCompleteReveal:(BOOL)reveal;

@end
