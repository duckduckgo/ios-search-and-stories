//
//  DDGSettingsViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSettingsViewController.h"
#import "DDGCache.h"
#import "DDGChooseSourcesViewController.h"
#import "DDGChooseRegionViewController.h"
#import "SHK.h"
#import "SVProgressHUD.h"
#import <sys/utsname.h>
#import "DDGHistoryProvider.h"
#import "ECSlidingViewController.h"
#import "DDGRegionProvider.h"

@implementation DDGSettingsViewController

+(void)loadDefaultSettings {
    NSDictionary *defaults = @{
        @"history": @(YES),
        @"quack": @(NO),
		@"region": @"us-en"
    };
    
    for(NSString *key in defaults) {
        if(![DDGCache objectForKey:key inCache:@"settings"])
            [DDGCache setObject:[defaults objectForKey:key] 
                         forKey:key 
                        inCache:@"settings"];
    }
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"triforce_button.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 38, 31); // the actual image is 36px wide but we need 1px horizontal padding on either side
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    
    [button addTarget:self action:@selector(leftButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
	self.tableView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];
}

-(void)leftButtonPressed {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

#pragma mark - Form view controller

-(void)configure {
    self.title = @"Settings";
    // referencing self directly in the blocks below leads to retain cycles, so use weakSelf instead
    __weak DDGSettingsViewController *weakSelf = self;
    
    [self addSectionWithTitle:@"Water Cooler"];
    [self addSwitch:@"Quack on Refresh" enabled:[[DDGCache objectForKey:@"quack" inCache:@"settings"] boolValue]];
    [self addButton:@"Change Sources" detailTitle:nil type:IGFormButtonTypeDisclosure action:^{
        DDGChooseSourcesViewController *sourcesVC = [[DDGChooseSourcesViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [weakSelf.navigationController pushViewController:sourcesVC animated:YES];
    }];
    
    [self addSectionWithTitle:@"Regions"];
    [self addButton:@"Region" detailTitle:[[DDGRegionProvider shared] titleForRegion:[[DDGRegionProvider shared] region]] type:IGFormButtonTypeDisclosure action:^{
        DDGChooseRegionViewController *rvc = [[DDGChooseRegionViewController alloc] initWithDefaults];
        [weakSelf.navigationController pushViewController:rvc animated:YES];
    }];
    
    [self addSectionWithTitle:@"Privacy"];
    [self addSwitch:@"Record History" enabled:[[DDGCache objectForKey:@"history" inCache:@"settings"] boolValue]];
    [self addSectionWithTitle:nil footer:@"History is stored on your phone."];
    [self addButton:@"Clear History" action:^{
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to clear history? This cannot be undone."
                                                                 delegate:weakSelf
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Clear History", nil];
        [actionSheet showInView:weakSelf.view];
    }];
    
    [self addSectionWithTitle:nil];
    [self addButton:@"Send Feedback" action:^{
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = self;
        [mailVC setToRecipients:@[@"help@duckduckgo.com"]];
        [mailVC setSubject:@"DuckDuckGo app feedback"];
        [mailVC setMessageBody:[NSString stringWithFormat:@"I'm running %@. Here's my feedback:",[weakSelf deviceInfo]] isHTML:NO];
        [weakSelf presentModalViewController:mailVC animated:YES];
    }];
    [self addButton:@"Share This App" action:^{
        SHKItem *shareItem = [SHKItem URL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/duckduckgo-search/id479988136?mt=8&uo=4"] title:@"Check out the DuckDuckGo app!" contentType:SHKURLContentTypeWebpage];
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:shareItem];
        [actionSheet showInView:weakSelf.view];
    }];
    [self addButton:@"Rate This App" action:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=479988136&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
    }];
}

-(void)saveData:(NSDictionary *)formData {
    [DDGCache setObject:[formData objectForKey:@"Record History"]
                 forKey:@"history" 
                inCache:@"settings"];
    
    [DDGCache setObject:[formData objectForKey:@"Quack on Refresh"]
                 forKey:@"quack" 
                inCache:@"settings"];
}

#pragma mark - Helper methods

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        [[DDGHistoryProvider sharedProvider] clearHistory];
        [SVProgressHUD showSuccessWithStatus:@"History cleared!"];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if(result == MFMailComposeResultSent) {
        [SVProgressHUD showSuccessWithStatus:@"Feedback sent!"];
    } else if(result == MFMailComposeResultFailed) {
        [SVProgressHUD showErrorWithStatus:@"Feedback send failed!"];
    }
    [self dismissModalViewControllerAnimated:YES];
}

-(NSString *)deviceInfo {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *device = [NSString stringWithCString:systemInfo.machine
                                          encoding:NSUTF8StringEncoding];
    NSDictionary *deviceNames = @{
        @"x86_64"    : @"iOS simulator",
        @"i386"      : @"iOS simulator",
        @"iPod1,1"   : @"iPod touch 1G",
        @"iPod2,1"   : @"iPod touch 2G",
        @"iPod3,1"   : @"iPod touch 3G",
        @"iPod4,1"   : @"iPod touch 4G",
        @"iPhone1,1" : @"iPhone",
        @"iPhone1,2" : @"iPhone 3G",
        @"iPhone2,1" : @"iPhone 3GS",
        @"iPad1,1"   : @"iPad",
        @"iPad2,1"   : @"iPad 2",
        @"iPhone3,1" : @"iPhone 4",
        @"iPhone4,1" : @"iPhone 4S"
    };
    if([deviceNames objectForKey:device])
        device = [deviceNames objectForKey:device];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    
    return [NSString stringWithFormat:@"DuckDuckGo v%@ on an %@ (iOS %@)",appVersion,device,osVersion];
}
@end
