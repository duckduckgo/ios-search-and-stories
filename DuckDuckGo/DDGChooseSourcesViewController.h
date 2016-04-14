//
//  DDGNewsSourcesViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface DDGChooseSourcesViewController : UITableViewController <UIAlertViewDelegate, MFMailComposeViewControllerDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

@end
