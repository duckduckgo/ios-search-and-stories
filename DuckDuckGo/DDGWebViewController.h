//
//  DDGWebViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDGSearchController.h"

@interface DDGWebViewController : UIViewController<UIWebViewDelegate, DDGSearchHandler>
{
	IBOutlet UIWebView *webView;
	IBOutlet DDGSearchController *searchController;
    
    NSDictionary *params;
    
    BOOL viewsInitialized;
    NSString *queryOrURLToLoad;

    NSUInteger webViewLoadingDepth;
    
    BOOL addressBarIsAnimating;
    BOOL addressBarIsInside;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet DDGSearchController *searchController;

@property (nonatomic, strong) NSDictionary *params;

-(void)loadQueryOrURL:(NSString *)queryOrURLString;

@end