//
//  DDGSourceSettingCellTableViewCell.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 01/09/2015.
//
//

#import <UIKit/UIKit.h>

#import "DDGStoryFeed.h"

@interface DDGSourceSettingCellTableViewCell : UITableViewCell

@property (nonatomic, strong) DDGStoryFeed* feed;

-(id)initWithReuseIdentifier:(NSString*)reuseIdentifier;


@end
