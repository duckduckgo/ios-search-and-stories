//
//  DDGUnderViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import <UIKit/UIKit.h>
#import "DDGSearchHandler.h"

@class DDGSettingsViewController, DDGStory;

@interface DDGUnderViewController : UITableViewController <DDGSearchHandler>
{
    UIViewController	*_homeViewController;
	NSInteger			menuIndex;
}

@property(nonatomic,strong) UIViewController *homeViewController;

-(void)configureViewController:(UIViewController *)viewController;

-(void)loadQueryOrURL:(NSString *)queryOrURL;
-(void)loadStory:(DDGStory *)story;
-(void)loadSelectedViewController;

@end
