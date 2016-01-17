//
//  DDGStoryMenu.h
//  DuckDuckGo
//
//  Created by Josiah Clumont on 18/01/16.
//
//

#import <Foundation/Foundation.h>
#import "DDGStoryCell.h"

@interface DDGStoryMenu : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) DDGStoryCell* storyCell;
@property (nonatomic, assign) BOOL showRemoveAction;

-(id)initWithStoryCell:(DDGStoryCell*)cell;
@end
