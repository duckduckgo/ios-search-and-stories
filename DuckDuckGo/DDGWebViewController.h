//
//  DDGWebViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DDGSearchController.h"

@interface DDGWebViewController : UIViewController<UIWebViewDelegate, DDGSearchProtocol>
{
	IBOutlet UIWebView				*www;
	IBOutlet DDGSearchController	*searchController;
    
    NSDictionary					*params;
	NSInteger						callDepth;
}

@property (nonatomic, strong) IBOutlet UIWebView			*www;
@property (nonatomic, strong) IBOutlet DDGSearchController	*searchController;

@property (nonatomic, strong) NSDictionary					*params;

@end