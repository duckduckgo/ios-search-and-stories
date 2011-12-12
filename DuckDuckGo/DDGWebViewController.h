//
//  DDGWebViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DDGSearchController.h"

@interface DDGWebViewController : UIViewController<UIWebViewDelegate, DDGSearchProtocol>
{
	IBOutlet UIWebView				*www;
	IBOutlet DDGSearchController	*searchController;
    
    NSURL                           *url;
}

@property (nonatomic, retain) IBOutlet UIWebView			*www;
@property (nonatomic, retain) IBOutlet DDGSearchController	*searchController;

@property (nonatomic, retain) NSURL                         *url;

@end