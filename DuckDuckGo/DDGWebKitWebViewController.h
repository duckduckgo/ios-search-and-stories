//
//  DDGWebKitWebViewController.h
//  DuckDuckGo
//
//  Created by Josiah Clumont on 2/02/16.
//
//

#import <UIKit/UIKit.h>
#import "DDGWebViewController.h"
#import <WebKit/WebKit.h>

@interface DDGWebKitWebViewController : DDGWebViewController <WKUIDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate>


@property (nonatomic, strong) WKWebView *webView;

@end
