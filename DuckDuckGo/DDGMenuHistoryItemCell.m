//
//  DDGMenuHistoryItemCell.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 28/03/2014.
//
//


#import "DDGMenuHistoryItemCell.h"
#import "UIFont+DDG.h"

@interface DDGMenuHistoryItemCell () {
    BOOL _isLastItem;
}

@end

@implementation DDGMenuHistoryItemCell

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self) {
        self.tintColor = [UIColor duckRed];
        self.imageView.contentMode = UIViewContentModeLeft;
        _isLastItem = FALSE;
        
        CGRect plusRect = self.frame;
        plusRect.origin.x = plusRect.size.width-44;
        plusRect.size.width = 44;
        UIButton* plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [plusButton setImage:[UIImage imageNamed:@"Plus"] forState:UIControlStateNormal];
        plusButton.frame = plusRect;
        plusButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:plusButton];
        
        CGRect sepRect = self.frame;
        sepRect.origin.x = 15;
        sepRect.origin.y = sepRect.size.height-0.5;
        sepRect.size.height = 0.5;
        sepRect.size.width -= 15;
        self.separatorView = [[UIView alloc] initWithFrame:sepRect];
        self.separatorView.backgroundColor = [UIColor duckTableSeparator];
        self.separatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.separatorView];
        
        self.selectedBackgroundView.backgroundColor = [UIColor duckTableSeparator];
        
        self.textLabel.font = [UIFont duckFontWithSize:self.textLabel.font.pointSize];
        
        [plusButton addTarget:self action:@selector(plusButtonWasPushed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect imgRect = self.imageView.frame;
    imgRect.origin.x = 15;
    self.imageView.frame = imgRect;
    
    CGRect tmpFrame = self.textLabel.frame;
    tmpFrame.origin.x = 50;
    self.textLabel.frame = tmpFrame;
    
    tmpFrame = self.detailTextLabel.frame;
    tmpFrame.origin.x = 50;
    self.detailTextLabel.frame = tmpFrame;
    
    CGFloat sepIndent = _isLastItem ? 0 : 15;
    CGRect sepRect = self.frame;
    sepRect.origin.x = sepIndent;
    sepRect.origin.y = sepRect.size.height-0.5;
    sepRect.size.height = 0.5;
    sepRect.size.width -= sepIndent;
    self.separatorView.frame = sepRect;
}


-(void)plusButtonWasPushed:(DDGHistoryItem*)historyItem;
{
    [self.historyDelegate plusButtonWasPushed:self];
}

-(void)setBookmarkItem:(NSDictionary*)bookmark
{
    _bookmarkItem = bookmark;
    NSString* title = bookmark[@"title"];
    self.textLabel.text = title;
    self.imageView.image = [UIImage imageNamed:@"favorite-small"];
}



-(void)setIsLastItem:(BOOL)isLastItem
{
    _isLastItem = isLastItem;
}

-(void)setHistoryItem:(DDGHistoryItem*)historyItem
{
    _historyItem = historyItem;
    NSString* title = historyItem.title;
    self.textLabel.text = title;
    self.imageView.image = [UIImage imageNamed:@"recent-small"];
    
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
