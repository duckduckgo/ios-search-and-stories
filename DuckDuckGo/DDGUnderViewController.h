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
}

-(id)initWithHomeViewController:(UIViewController *)homeViewController;
-(void)configureViewController:(UIViewController *)viewController;

-(void)addPageWithQueryOrURL:(NSString *)queryOrURL title:(NSString *)title;

@end
