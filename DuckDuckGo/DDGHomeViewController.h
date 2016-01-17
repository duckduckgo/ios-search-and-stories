//
//  DDGHomeViewController.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 26/06/2015.
//
//

#import <UIKit/UIKit.h>

#import "DDGSearchHandler.h"
#import "DDGTabViewController.h"


@interface DDGHomeViewController : UIViewController <DDGTabViewControllerDelegate, UITabBarControllerDelegate>

//@property (nonatomic, strong) UIView* alternateButtonBar;

+(DDGHomeViewController*)newHomeController;
-(id<DDGSearchHandler>)currentSearchHandler;

-(void)showSearchAndPrepareInput;
-(void)showSaved;
-(void)registerScrollableContent:(UIScrollView*)contentView;


-(IBAction)showRecents;
-(IBAction)showFavorites;
-(IBAction)showStories;
-(IBAction)showDuck;
-(IBAction)showSettings;
- (void)checkAndRefreshSettings;

@end
