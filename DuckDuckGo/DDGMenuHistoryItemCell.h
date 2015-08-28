//
//  DDGMenuHistoryItemCell.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 28/03/2014.
//
//

#import <UIKit/UIKit.h>
#import "DDGHistoryItem.h"

@class DDGMenuHistoryItemCell;

@protocol DDGHistoryItemCellDelegate <NSObject>

-(void)plusButtonWasPushed:(DDGMenuHistoryItemCell*)menuCell;

@end


@interface DDGMenuHistoryItemCell : UITableViewCell

@property (nonatomic, strong) DDGHistoryItem* historyItem;
@property (nonatomic, strong) NSDictionary* bookmarkItem;
@property (nonatomic, strong) NSDictionary* suggestionItem;
@property (nonatomic, strong) id<DDGHistoryItemCellDelegate> historyDelegate;

-(id)initWithReuseIdentifier:(NSString*)reuseIdentifier;

-(void)configureForAutocompletion;

-(void)setIsLastItem:(BOOL)isLastItem;

-(void)setIcon:(UIImage*)image;

@end
