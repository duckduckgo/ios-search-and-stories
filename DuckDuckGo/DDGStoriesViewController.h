//
//  DDGStoriesViewController.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "DDGSearchHandler.h"
#import "DDGSearchController.h"
#import "EGORefreshTableHeaderView.h"

@interface DDGStoriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, EGORefreshTableHeaderDelegate, UIScrollViewDelegate>
{}
@property (nonatomic, readonly, weak) id <DDGSearchHandler> searchHandler;

- (id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler;
@end
