//
//  DDGUnderViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import <UIKit/UIKit.h>

@class DDGHomeViewController, DDGSettingsViewController, DDGStory;

@interface DDGUnderViewController : UITableViewController
{
    UIViewController	*_homeViewController;
	NSInteger			menuIndex;
}

@property(nonatomic,strong) UIViewController *homeViewController;

-(id)initWithHomeViewController:(UIViewController *)homeViewController;
-(void)configureViewController:(UIViewController *)viewController;

-(void)loadQueryOrURL:(NSString *)queryOrURL;
-(void)loadStory:(DDGStory *)story;
-(void)loadHomeViewController;

@end
