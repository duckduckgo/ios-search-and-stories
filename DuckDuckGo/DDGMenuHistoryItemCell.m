//
//  DDGMenuHistoryItemCell.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 28/03/2014.
//
//


#import "DDGMenuHistoryItemCell.h"

@interface DDGMenuHistoryItemCell () {
    BOOL _isLastItem;
}

@property BOOL autocompleteMode;
@property UIButton* plusButton;
//@property (nonatomic, strong) UIView* separatorView;

@end

@implementation DDGMenuHistoryItemCell

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if(self) {
        self.tintColor = [UIColor duckRed];
        self.imageView.contentMode = UIViewContentModeLeft;
        self.autocompleteMode = FALSE;
        _isLastItem = FALSE;
        
        CGRect plusRect = self.frame;
        plusRect.origin.x = plusRect.size.width-44;
        plusRect.size.width = 44;
        self.plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.plusButton setImage:[UIImage imageNamed:@"Plus"] forState:UIControlStateNormal];
        self.plusButton.frame = plusRect;
        self.plusButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.plusButton];
        
        self.selectedBackgroundView.backgroundColor = [UIColor duckTableSeparator];
        
        self.textLabel.font = [UIFont duckFontWithSize:17.0f];
        self.detailTextLabel.font = [UIFont duckFontWithSize:15.0f];
        
        self.textLabel.textColor = [UIColor duckListItemTextForeground];
        self.detailTextLabel.textColor = [UIColor duckListItemDetailForeground];
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.autoresizingMask = UIViewAutoresizingNone;
        
        [self.plusButton addTarget:self action:@selector(plusButtonWasPushed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)configureForAutocompletion
{
    self.autocompleteMode = TRUE;
}


-(void)layoutSubviews {
   [super layoutSubviews];
    
    CGRect frame         = self.frame;
    CGRect imgRect       = self.imageView.frame;
    imgRect.origin.x     = 15;
    self.imageView.frame = imgRect;
    
    CGRect tmpFrame      = self.textLabel.frame;
    tmpFrame.origin.x    = 49;
    tmpFrame.size.width  = frame.size.width - tmpFrame.origin.x - self.plusButton.frame.size.width;
    self.textLabel.frame = tmpFrame;
    
    tmpFrame                   = self.detailTextLabel.frame;
    tmpFrame.origin.x          = 49;
    tmpFrame.size.width        = frame.size.width - tmpFrame.origin.x - self.plusButton.frame.size.width;
    self.detailTextLabel.frame = tmpFrame;
    
}


-(void)plusButtonWasPushed:(DDGHistoryItem*)historyItem;
{
    if ([self.historyDelegate respondsToSelector:@selector(plusButtonWasPushed:)]) {
        [self.historyDelegate plusButtonWasPushed:self];
    }
}

-(void)setBookmarkItem:(NSDictionary*)bookmark
{
    _bookmarkItem = bookmark;
    NSString* title = bookmark[@"title"];
    self.textLabel.text = title;
    self.imageView.image = [UIImage imageNamed:@"favorite-small"];
}

-(void)setSuggestionItem:(NSDictionary *)suggestion
{
    _suggestionItem = suggestion;
    self.textLabel.text = [suggestion objectForKey:@"phrase"];
    self.detailTextLabel.text = [suggestion objectForKey:@"snippet"];
    self.imageView.image = nil; // the image should be set in the view controller, which can maintain a shared image cache
    
    if([suggestion objectForKey:@"calls"] && [[suggestion objectForKey:@"calls"] count]) {
        self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

-(void)setIcon:(UIImage *)image
{
    self.imageView.image = image;
    [self.imageView setNeedsDisplay];
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
}

@end
