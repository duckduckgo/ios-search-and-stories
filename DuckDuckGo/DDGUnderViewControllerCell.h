//
//  DDGUnderViewControllerCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 08/03/2013.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum DDGUnderViewControllerCellMode {
    DDGUnderViewControllerCellModeNormal = 0,
    DDGUnderViewControllerCellModeRecent
} DDGUnderViewControllerCellMode;

@interface DDGUnderViewControllerCell : UITableViewCell
@property (nonatomic) DDGUnderViewControllerCellMode cellMode;
@end
