//
//  DDGWebToolbar.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 23/07/2015.
//
//

#import <UIKit/UIKit.h>
#import "DDGWebViewController.h"

@interface DDGWebToolbar : UIView

@property IBOutlet UIButton* backButton;
@property IBOutlet UIButton* forwardButton;
@property IBOutlet UIButton* favButton;
@property IBOutlet UIButton* shareButton;
@property IBOutlet UIButton* tabsButton;

-(id)initWithDDGWebController:(DDGWebViewController*)webController
                     andFrame:(CGRect)frame;

@end
