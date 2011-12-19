//
//  DDGViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DDGSearchController.h"
#import "DataHelper.h"

@interface DDGViewController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, DDGSearchProtocol, DataHelperDelegate>
{
	IBOutlet UITableViewCell		*loadedCell;
	IBOutlet UITableView			*tableView;
	IBOutlet DDGSearchController	*searchController;
	
	id								entries;
	DataHelper						*dataHelper;
}

@property (nonatomic, retain) IBOutlet UITableViewCell		*loadedCell;
@property (nonatomic, retain) IBOutlet UITableView			*tableView;
@property (nonatomic, retain) IBOutlet DDGSearchController	*searchController;

@property (nonatomic, retain) id							entries;

- (void)loadEntries;
- (UIImage*)loadImage:(NSString*)url;

@end
