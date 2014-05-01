//
//  DDGStoryCell.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/02/2013.
//
//

#import <UIKit/UIKit.h>

extern NSString *const DDGStoryCellIdentifier;

@interface DDGStoryCell : UITableViewCell

@property (nonatomic, strong) UIImage *favicon;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign, getter = isRead) BOOL read;
@property (nonatomic, copy) NSString *title;

@end
