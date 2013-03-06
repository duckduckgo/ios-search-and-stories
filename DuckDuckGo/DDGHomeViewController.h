//
//  DDGViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDGSearchController.h"

@class DDGStoryCell;
@class DDGScrollbarClockView;
@interface DDGHomeViewController : UIViewController<UITextFieldDelegate, DDGSearchHandler> {    
}

@property (nonatomic, strong) DDGSearchController *searchController;
@property (nonatomic, strong) UIViewController *contentController;

@end