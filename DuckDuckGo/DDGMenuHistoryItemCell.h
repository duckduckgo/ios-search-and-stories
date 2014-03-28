//
//  DDGMenuHistoryItemCell.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 28/03/2014.
//
//

#import <UIKit/UIKit.h>

@interface DDGMenuHistoryItemCell : UITableViewCell

@property (nonatomic, assign, getter = isAuxiliaryViewHidden) BOOL auxiliaryViewHidden;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) UIImage *faviconImage;
@property (nonatomic, assign, getter = isNotification) BOOL notification;

@end
