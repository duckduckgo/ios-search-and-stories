//
//  DDGViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DDGSearchController.h"

@interface DDGViewController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, DDGSearchHandler>
{
	IBOutlet UITableViewCell *loadedCell;
	IBOutlet UITableView *tableView;
	IBOutlet DDGSearchController *searchController;
	
	NSArray *stories;

    NSString *webQuery;
    NSString *webURL;
}

@property (nonatomic, strong) IBOutlet UITableViewCell *loadedCell;
@property (nonatomic, strong) IBOutlet UITableView	*tableView;
@property (nonatomic, strong) IBOutlet DDGSearchController *searchController;

@property (nonatomic, strong) id stories;

- (void)downloadStories;
-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories;
-(NSString *)storiesPath;

@end
