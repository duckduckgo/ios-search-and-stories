//
//  DDGActivityViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 11/03/2013.
//
//

#import "DDGActivityViewController.h"
#import "DDGSafariActivity.h"

@interface DDGActivityViewController ()
@end

@implementation DDGActivityViewController

- (id)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities
{
    DDGSafariActivity *safariActivity = [[DDGSafariActivity alloc] init];
    applicationActivities = [applicationActivities arrayByAddingObjectsFromArray:@[safariActivity]];
    
    self = [super initWithActivityItems:activityItems applicationActivities:applicationActivities];
    if (self) {
        // Custom initialization
    }
    return self;
}

@end
