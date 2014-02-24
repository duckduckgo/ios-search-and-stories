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

@interface DDGWebViewController : UIViewController<UIWebViewDelegate, DDGSearchHandler, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate>
{
    NSUInteger _webViewLoadingDepth;
}

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, weak) DDGSearchController *searchController;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSURL *webViewURL;
@property (nonatomic, strong) DDGStory *story;
@property (nonatomic, readonly) BOOL inReadabilityMode;

-(void)loadQueryOrURL:(NSString *)queryOrURLString;
-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode;

- (BOOL)canSwitchToReadabilityMode;
- (void)switchReadabilityMode:(BOOL)on;

@end