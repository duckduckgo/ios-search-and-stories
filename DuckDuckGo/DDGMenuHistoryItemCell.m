//
//  DDGMenuHistoryItemCell.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 28/03/2014.
//
//

#import "DDGMenuHistoryItemCell.h"

@interface DDGMenuHistoryItemCell ()


@end

@implementation DDGMenuHistoryItemCell

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self) {
        UIButton* plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        plusButton.frame = CGRectMake(0, 0, 44, 44);
        self.tintColor = [UIColor duckRed];
        UIImage* plusImage = [UIImage imageNamed:@"Plus"];
        [plusButton setImage:plusImage forState:UIControlStateNormal];
        self.accessoryView = plusButton;
        self.imageView.image = [UIImage imageNamed:@"recent-small"];
        
        [plusButton addTarget:self action:@selector(plusButtonWasPushed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)plusButtonWasPushed:(DDGHistoryItem*)historyItem;
{
    [self.historyDelegate plusButtonWasPushed:self.historyItem];
}

-(void)viewDidLoad
{
    NSLog(@"TEST:  in DDGMenuHistoryItemCell viewDidLoad");
}

-(void)setBookmarkItem:(NSDictionary*)bookmark
{
    _bookmarkItem = bookmark;
    NSString* title = bookmark[@"title"];
    self.textLabel.text = title;
}


-(void)setHistoryItem:(DDGHistoryItem*)historyItem
{
    _historyItem = historyItem;
    NSString* title = historyItem.title;
    self.textLabel.text = title;
    
//    if (title.length > 0 && [title hasPrefix:@"!"]) {
//        self.faviconImage = [[UIImage imageNamed:@"TinyBang"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    } else {
//        self.imageView.image = [UIImage imageNamed:@"recent-small"];
//    }

}

//- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
//{
//    [super setHighlighted:highlighted animated:animated];
//    self.tintColor = highlighted ? [UIColor whiteColor] : [UIColor duckRed];
//    [self.contentLabel setTextColor:highlighted ? [UIColor whiteColor] : [UIColor duckBlack]];
//}
//
//- (void)setNotification:(BOOL)notification
//{
//    _notification = notification;
////    UIImage *image = nil;
////    if (notification) {
////        image = [[UIImage imageNamed:@"Notification"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
////    } else {
////        image = [UIImage imageNamed:@"favorite-small"];// imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
////    }
//}
//
//- (BOOL)shouldCauseMenuPanGestureToFail
//{
//    return YES;
//}

@end
