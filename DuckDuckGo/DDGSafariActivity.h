//
//  DDGSafariActivity.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 28/03/2013.
//
//

#import <UIKit/UIKit.h>
#import "TUSafariActivity.h"

@interface DDGSafariActivityItem : NSObject
@property (nonatomic, strong) NSURL *URL;
+ (id)safariActivityItemWithURL:(NSURL *)URL;
@end

@interface DDGSafariActivity : TUSafariActivity

@end
