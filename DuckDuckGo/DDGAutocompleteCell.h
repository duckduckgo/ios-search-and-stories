//
//  DDGAutocompleteCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 22/05/2013.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DDGAutocompleteCell : UITableViewCell

@property (nonatomic, assign, readwrite) BOOL showsSeparatorLine;

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
- (void)setAdorned:(BOOL)adorned;

@end
