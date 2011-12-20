//
//  DDGTopicsTrendsPick.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DataHelper.h"

@interface DDGTopicsTrendsPick : UIViewController<UITableViewDataSource, UITableViewDelegate, DataHelperDelegate>
{
	IBOutlet UITableViewCell		*loadedCell;
	IBOutlet UITableView			*tableView;
	
	id								entries;
	DataHelper						*dataHelper;
}

@property (nonatomic, retain) IBOutlet UITableViewCell		*loadedCell;
@property (nonatomic, retain) IBOutlet UITableView			*tableView;

@property (nonatomic, retain) id							entries;

- (IBAction)done:(id)sender;

@end
