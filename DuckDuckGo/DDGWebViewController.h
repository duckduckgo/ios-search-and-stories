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

@interface DDGWebViewController : UIViewController<UIWebViewDelegate, DDGSearchHandler, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
    BOOL viewsInitialized;
    NSString *queryOrURLToLoad;
    
    NSUInteger webViewLoadingDepth;
    NSUInteger webViewLoadEvents;
}

@property(nonatomic, strong) IBOutlet UIWebView *webView;
@property(nonatomic, strong) IBOutlet DDGSearchController *searchController;
@property(nonatomic, strong) NSDictionary *params;
@property(nonatomic, strong) NSURL *webViewURL;

-(void)loadQueryOrURL:(NSString *)queryOrURLString;

@end