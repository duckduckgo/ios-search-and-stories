//
//  DDGNoContentViewController.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 17/08/2015.
//
//

#import <UIKit/UIKit.h>

@interface DDGNoContentViewController : UIViewController

@property (nonatomic, strong) NSString* contentTitle;
@property (nonatomic, strong) NSString* contentSubtitle;

@property (nonatomic, weak) IBOutlet UIImageView* noContentImageview;


@end
