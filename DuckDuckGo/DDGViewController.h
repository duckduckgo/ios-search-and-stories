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
    
	__weak IBOutlet UITableView *tableView;
    DDGSearchController *searchController;
	
	NSArray *stories;

    NSString *queryOrURLToLoad;
}

@property (nonatomic, strong) IBOutlet UITableViewCell *loadedCell;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) DDGSearchController *searchController;

@property (nonatomic, strong) NSArray *stories;

- (void)downloadStories;
-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories;
-(NSString *)storiesPath;

@end
