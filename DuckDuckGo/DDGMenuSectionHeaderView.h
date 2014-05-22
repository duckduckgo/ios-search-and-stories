//
//  DDGMenuSectionHeaderView.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 27/03/2014.
//
//

#import <UIKit/UIKit.h>

typedef void(^DDGMenuSectionHeaderCloseBlock)();

@interface DDGMenuSectionHeaderView : UIView

@property (nonatomic, copy) DDGMenuSectionHeaderCloseBlock closeBlock;
@property (nonatomic, copy) NSString *title;

@end
