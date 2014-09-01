//
//  DDGAutocompleteTableView.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/4/12.
//
//

#import <UIKit/UIKit.h>

@protocol DDGTableViewDelegate <UITableViewDelegate>

- (void)tableViewBackgroundTouched;

@end

@interface DDGAutocompleteTableView : UITableView

@end
