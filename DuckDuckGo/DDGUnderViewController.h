//
//  DDGUnderViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import <UIKit/UIKit.h>

@class DDGHomeViewController, DDGSettingsViewController;
@interface DDGUnderViewController : UITableViewController {
    NSMutableArray *viewControllers;
    UIViewController *_homeViewController;
}
@property(nonatomic,strong) UIViewController *homeViewController;

-(id)initWithHomeViewController:(UIViewController *)homeViewController;
-(void)configureViewController:(UIViewController *)viewController;

-(void)loadQueryOrURL:(NSString *)queryOrURL;
-(void)loadHomeViewController;

@end
