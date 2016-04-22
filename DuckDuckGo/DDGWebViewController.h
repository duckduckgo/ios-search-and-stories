//
//  DDGWebViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "DDGSearchController.h"

@class DDGStory;

@interface DDGWebViewController : UIViewController <UIWebViewDelegate, DDGSearchHandler, UIActionSheetDelegate, UIScrollViewDelegate, MFMailComposeViewControllerDelegate>
{
    NSUInteger _webViewLoadingDepth;
}

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, weak) DDGSearchController *searchController;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSURL *webViewURL;
@property (nonatomic, strong) DDGStory *story;
@property (nonatomic, readonly) BOOL inReadabilityMode;
@property (nonatomic, strong) IBOutlet UIView* webToolbar;
@property (assign) BOOL isAStory;
@property NSDate* ignoreTapsUntil;

-(void)loadQueryOrURL:(NSString *)queryOrURLString;
-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode;

- (BOOL)canSwitchToReadabilityMode;
- (void)switchReadabilityMode:(BOOL)on;

-(UIView*)alternateToolbar;
-(IBAction)backButtonPressed:(id)sender;
-(IBAction)forwardButtonPressed:(id)sender;
-(IBAction)favButtonPressed:(id)sender;
-(IBAction)shareButtonPressed:(id)sender;
-(IBAction)tabsButtonPressed:(id)sender;


- (void)setHideToolbarAndNavigationBar:(BOOL)shouldHide forScrollview:(UIScrollView*)scrollView;
- (void)updateButtons;
- (void)setUpWebToolBar;
- (void)updateProgressBar;
- (NSUInteger)incrementLoadingDepth ;
- (NSUInteger)decrementLoadingDepthCancelled:(BOOL)cancelled;
- (void)resetLoadingDepth;
- (NSString *)htmlFromJSON:(id)JSON;
- (void)internalMailAction:(NSURL*)url;
- (void)updateBarWithRequest:(NSURLRequest *)request;
- (void)loadWebViewWithUrl:(NSURL*)url;
@end