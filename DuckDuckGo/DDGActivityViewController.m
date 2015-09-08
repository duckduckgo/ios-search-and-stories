//
//  DDGActivityViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 11/03/2013.
//
//

#import "DDGActivityViewController.h"
#import "DDGSafariActivity.h"

@interface DDGActivityViewController ()
@end

@implementation DDGActivityViewController

- (id)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities
{
    DDGSafariActivity *safariActivity = [[DDGSafariActivity alloc] init];
    applicationActivities = [applicationActivities arrayByAddingObjectsFromArray:@[safariActivity]];
    
    self = [super initWithActivityItems:activityItems applicationActivities:applicationActivities];
    if (self) {
        // Custom initialization
    }
    return self;
}

// this was a failed attempt to get the mail and message sheets to use the UIStatusBarStyleLightContent status bar
//- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
//    [super presentViewController:viewControllerToPresent animated:flag completion:^{
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//        if (completion) {
//            completion();
//        }
//    }];
//}
//
//-(UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}


@end
