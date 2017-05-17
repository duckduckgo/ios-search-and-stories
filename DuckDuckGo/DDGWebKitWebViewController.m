//
//  DDGWebKitWebViewController.m
//  DuckDuckGo
//
//  Created by Josiah Clumont on 2/02/16.
//
//

@import AssetsLibrary;

#import "DDGWebKitWebViewController.h"
#import "DDGConstraintHelper.h"
#import "DDGAddressBarTextField.h"
#import "DDGBookmarksProvider.h"
#import "DDGUtility.h"
#import "DDGStory.h"
#import "AFNetworking.h"
#import "DDGActivityViewController.h"
#import "DDGImageActivityItemProvider.h"


@interface DDGWebKitView : WKWebView {
    UIView *_blackHoleView;
}

@property (nonatomic, weak) DDGWebKitWebViewController *webKitController;
@property (readonly) UIView *blackHoleView;

@end

@implementation DDGWebKitView

-(UIView*)blackHoleView {
    if(_blackHoleView==nil) {
        _blackHoleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    }
    return _blackHoleView;
}

-(UIView*)hitTest:(CGPoint)tapPoint withEvent:(UIEvent *)event
{
    
    // if someone taps the bottom toolbar area, swallow the tap and show the toolbar
    if(tapPoint.y + 50 > self.frame.size.height) {
        [self.webKitController setHideToolbarAndNavigationBar:FALSE forScrollview:self.scrollView];
        return self.blackHoleView;
    }
    return [super hitTest:tapPoint withEvent:event];
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
    __block NSString *resultURLString = nil;
    __block BOOL finished = NO;
    
    [self evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                resultURLString = [NSString stringWithFormat:@"%@", result];
            }
        } else {
            NSLog(@"error : %@", error.localizedDescription);
        }
        finished = YES;
    }];
    
    while (!finished)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    return resultURLString;
}

@end

@interface DDGWebKitWebViewController ()

@end

@implementation DDGWebKitWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.webView.UIDelegate = nil;
    self.webView.navigationDelegate = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self shouldEnableNavControllerSwipe:true];
}

- (void)loadView {
    // Set up web view
    [super loadView];
    
    CGRect viewFrame = self.view.frame;
    viewFrame.origin = CGPointMake(0, 0);
    DDGWebKitView *webKitView   = [[DDGWebKitView alloc] initWithFrame:viewFrame];
    webKitView.webKitController = self;
    self.webView                = webKitView;
    self.webView.UIDelegate     = self;
    self.webView.navigationDelegate = self;    
    [self.webView setBackgroundColor:[UIColor duckNoContentColor]];
    
    _webViewLoadingDepth = 0;
    [self.view addSubview:self.webView];
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:false];
    [DDGConstraintHelper pinView:self.webView intoView:self.view];
    
    [self setUpWebToolBar];
    [self updateButtons];
}

#pragma mark == Loading ==
- (void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode {
    self.isAStory = true;
    [self view];
    if (self.webView.URL != nil) {
        if (self.webView.isLoading) {
            [self.webView stopLoading];
        }
        
        [self resetLoadingDepth];
    }
    
    void (^htmlDownloaded)(BOOL success) = ^(BOOL success){
        if (readabilityMode && success) {
            self.webViewURL = story.URL;
            NSURLRequest *cachedRequest = [story HTMLURLRequest];
            [self.searchController updateBarWithURL:self.webViewURL];
            if ([cachedRequest.URL.absoluteString containsString:@"file://"]) {
                if ([self.webView respondsToSelector:@selector(loadFileURL:allowingReadAccessToURL:)]) {
                    [self.webView loadFileURL:cachedRequest.URL allowingReadAccessToURL:cachedRequest.URL];
                } else {
                    [self loadQueryOrURL:self.webViewURL.absoluteString];
                }
            } else {
                [self.webView loadRequest:[story HTMLURLRequest]];
            }
        } else {
            [self loadQueryOrURL:story.urlString];
        }
    };
    
    void (^completion)(id JSON) = ^(id JSON) {
        NSString *html = [self htmlFromJSON:JSON];
        if (nil != html) {
            [story writeHTMLString:html completion:htmlDownloaded];
        } else {
            htmlDownloaded(story.isHTMLDownloaded);
        }
        
        story.readValue = YES;
        
        NSManagedObjectContext *context = story.managedObjectContext;
        [context performBlock:^{
            NSError *error = nil;
            BOOL success = [context save:&error];
            if (!success) {
                NSLog(@"error: %@", error);
            }
        }];
    };
    
    self.story = story;
    
    if (readabilityMode && !story.isHTMLDownloaded) {
        [self loadJSONForStory:story completion:completion];
    } else {
        completion(nil);
    }
}

- (void)loadJSONForStory:(DDGStory *)story completion:(void (^)(id JSON))completion {
    self.isAStory       = true;
    NSString *urlString = story.articleURLString;
    
    if (nil == urlString) {
        if (completion)
            completion(NULL);
        return;
    }
    
    __weak DDGWebKitWebViewController *weakSelf = self;
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [DDGUtility requestWithURL:url];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion)
            completion(responseObject);
        [weakSelf decrementLoadingDepthCancelled:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion)
            completion(nil);
        [weakSelf.searchController webViewFinishedLoading];
        [weakSelf decrementLoadingDepthCancelled:YES];
        [weakSelf loadQueryOrURL:story.urlString];
    }];
    
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/javascript"]];
    
    [self incrementLoadingDepth];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [operation start];
    });
}

- (void)loadWebViewWithUrl:(NSURL*)url {
    NSURLRequest *request = [DDGUtility requestWithURL:url];
    [self.webView loadRequest:request];
    [self.searchController updateBarWithURL:url];
    self.webViewURL = url;
}

#pragma mark == WKUIDelegate ==
- (WKWebView*)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark == WKNavigationDelegate ==
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self updateButtons];
    [self incrementLoadingDepth];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // Update bar
    [self updateBarWithRequest:[NSURLRequest requestWithURL:webView.URL]];
    [self updateButtons];
    [self decrementLoadingDepthCancelled:NO];
    [self shouldEnableNavControllerSwipe:!webView.canGoBack];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self decrementLoadingDepthCancelled:YES];
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSDate* ignoreUntil = self.ignoreTapsUntil;
        if(ignoreUntil && [ignoreUntil compare:[NSDate new]]==NSOrderedDescending) {
            // ignore clicks within a certain range
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        UIApplication* app = UIApplication.sharedApplication;
        NSURL* url = navigationAction.request.URL;
        
        NSString* scheme = url.scheme.lowercaseString;
        if ([scheme isEqualToString:@"mailto"]) {
            // user is interested in mailing so use the internal mail API
            [self performSelector:@selector(internalMailAction:) withObject:navigationAction.request.URL afterDelay:0.05];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        
        if([scheme isEqualToString:@"tel"]) { // if it's a tel: URL, then replace it with "telprompt:" to avoid initiating a call without confirmation!
            scheme = @"telprompt";
            url = [NSURL URLWithString:[url.absoluteString stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:scheme]];
        }
        
        if([url.scheme isEqualToString:@"telprompt"] || [url.scheme isEqualToString:@"tel"]) {
            if ([app canOpenURL:url]) {
                [app openURL:url];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        if (!navigationAction.targetFrame) {
            [self loadQueryOrURL: url.absoluteString];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        } 
    }
    [self updateBarWithRequest:[NSURLRequest requestWithURL:webView.URL]];
    decisionHandler(WKNavigationActionPolicyAllow);
}


#pragma mark == Navigation Swiping Methods
- (void)shouldEnableNavControllerSwipe:(BOOL)enable {
    if ([self.searchController.navController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.searchController.navController.interactivePopGestureRecognizer.enabled  = enable;
        self.searchController.navController.interactivePopGestureRecognizer.delegate = enable ? nil:self;
        self.webView.allowsBackForwardNavigationGestures = !enable;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.searchController.navController.interactivePopGestureRecognizer) {
        return NO;
    }
    
    return YES;
}


@end

