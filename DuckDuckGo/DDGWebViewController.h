//
//  DDGWebViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDGSearchController.h"

@interface DDGWebViewController : UIViewController<UIWebViewDelegate, DDGSearchHandler, UIActionSheetDelegate> {
    BOOL viewsInitialized;
    NSString *queryOrURLToLoad;
    NSURL *webViewURL;
    
    NSUInteger webViewLoadingDepth;
    NSUInteger webViewLoadEvents;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet DDGSearchController *searchController;
@property (nonatomic, strong) NSDictionary *params;

-(void)loadQueryOrURL:(NSString *)queryOrURLString;

@end