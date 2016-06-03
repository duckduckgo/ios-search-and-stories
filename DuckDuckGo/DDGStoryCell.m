//
//  DDGStoryCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 12/02/2013.
//
//

#import "DDGFaviconButton.h"
#import "DDGStoryCell.h"
#import "DDGStoryFeed.h"
#import "DDGPopoverViewController.h"
#import "DDGActivityItemProvider.h"
#import "DDGActivityViewController.h"
#import "DDGSafariActivity.h"
#import "DDGStoriesViewController.h"
#import "DDGHistoryItem.h"
#import "DDGStoryMenu.h"

NSString *const DDGStoryCellIdentifier = @"StoryCell";


@interface DDGStoryCell ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIButton *menuButton;
@property (nonatomic, strong) UIButton *backupMenuButton;
@property (nonatomic, strong) UIButton* categoryButton;
@property (nonatomic, strong) UIButton *backupCategoryButton;
@property (nonatomic, strong) UIView *titleBackgroundView;
@property (nonatomic, strong) UIView *dropShadowView;
@property (nonatomic, strong) UIView *innerShadowView;
@property (nonatomic, strong) UIView *imageBottomView;
@property (nonatomic, strong) UILabel* textLabel;
@property (nonatomic, weak) DDGStoryMenu* menu;
@property (nonatomic, assign, getter = isRead) BOOL read;
@property (nonatomic, strong) DDGFaviconButton *faviconButton;
@property (nonatomic, strong) DDGPopoverViewController* menuPopover;

@end

@implementation DDGStoryCell

#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}

-(NSString*)reuseIdentifier
{
    return DDGStoryCellIdentifier;
}


-(void)saveStoryAndClose
{
    DDGPopoverViewController* popover = self.menuPopover;
    
    [self saveStory];
    if(popover) {
        // we should remove the popover if the story has disappeared
        [popover dismissViewControllerAnimated:TRUE completion:nil];
    }
}


-(void)share
{
    DDGPopoverViewController* popover = self.menuPopover;
    void(^share)() = ^() {
        [self.storyDelegate shareStory:self.story fromView:self.menuButton];
    };
    if(popover==nil) {
        share();
    } else {
        [popover dismissViewControllerAnimated:TRUE completion:share];
    }
}



-(void)openInBrowser
{
    DDGPopoverViewController* popover = self.menuPopover;
    void(^openInBrowser)() = ^() {
        [self.storyDelegate openStoryInBrowser:self.story];
    };
    if(popover==nil) {
        openInBrowser();
    } else {
        [popover dismissViewControllerAnimated:TRUE completion:openInBrowser];
    }
}


-(void)removeHistoryItem
{
    DDGPopoverViewController* popover = self.menuPopover;
    void(^removeItem)() = ^() {
        [self.storyDelegate removeHistoryItem:self.historyItem];
    };
    if(popover==nil) {
        removeItem();
    } else {
        [popover dismissViewControllerAnimated:TRUE completion:removeItem];
    }
}



#pragma mark -

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    // Empty stub!
}

- (void)setImage:(UIImage *)image
{
    [self.backgroundImageView setImage:image];
}

- (void)setRead:(BOOL)read
{
    _read = read;
    [self.textLabel setTextColor:(read ? [UIColor duckStoryReadColor] : [UIColor duckBlack])];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // Empty stub!
}

- (void)setStory:(DDGStory *)story
{
    _story = story;
    self.textLabel.text = story.title;
    [self.categoryButton setTitle:story.category forState:UIControlStateNormal];
    self.read = story.readValue;
    if (story.feed) {
        UIImage* img = story.feed.image;
        if(img) {
            [self.faviconButton setImage:img forState:UIControlStateNormal];
            self.faviconButton.backgroundColor = [UIColor clearColor];
            self.faviconButton.layer.cornerRadius = 0.0f;
        } else {
            [self.faviconButton setImage:img forState:UIControlStateNormal];
            self.faviconButton.backgroundColor = UIColorFromRGB(0xDDDDDD);
            self.faviconButton.layer.cornerRadius = 2.0f;
        }
        
    }
}

- (void)setHistoryItem:(DDGHistoryItem *)historyItem
{
    if(historyItem!=nil) {
        self.story = historyItem.story;
    }
    _historyItem = historyItem;
}

- (void)menuButtonSelected:(id)sender
{
    DDGStoryMenu* menu = [[DDGStoryMenu alloc] initWithStoryCell:self];
    self.menu          = menu;
    self.menuPopover   = [[DDGPopoverViewController alloc] initWithContentViewController:menu
                                                                 andTouchPassthroughView:self.touchPassthroughView];
    self.menuPopover.delegate = self;
    [self.menuPopover presentPopoverFromView:self.menuButton
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:TRUE];
    self.isShowingMenu = YES;
}

-(void)categoryButtonSelected:(id)sender
{
    [self.storyDelegate toggleCategoryPressed:self.story.category onStory:self.story];
}


#pragma mark -

- (void)configure
{
    self.isShowingMenu    = NO;
    self.shouldGoToDetail = YES;
    self.backgroundImageView = [UIImageView new];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.backgroundImageView];
    
    // Set the Menu Backup button for a larger trigger area
    self.backupMenuButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backupMenuButton addTarget:self action:@selector(menuButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.backupMenuButton];
    
    self.menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.menuButton.backgroundColor = [UIColor duckStoryMenuButtonBackground];
    [self.menuButton setImage:[UIImage imageNamed:@"menu-white"] forState:UIControlStateNormal];
    self.menuButton.layer.cornerRadius = 4.0f;
    [self.menuButton addTarget:self action:@selector(menuButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.menuButton];
    
    // Set up the backup button first...
    self.backupCategoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backupCategoryButton addTarget:self action:@selector(categoryButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.backupCategoryButton];
    
    self.categoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.categoryButton.backgroundColor = [UIColor duckStoryMenuButtonBackground];
    self.categoryButton.titleLabel.textColor = [UIColor whiteColor];
    self.categoryButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    //self.categoryLabel.opaque = NO;
    self.categoryButton.layer.cornerRadius = 4.0f;
    [self.categoryButton addTarget:self action:@selector(categoryButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.categoryButton];
    
    
    self.titleBackgroundView = [UIView new];
    self.titleBackgroundView.backgroundColor = [UIColor duckStoryTitleBackground];
    [self.contentView addSubview:self.titleBackgroundView];
    
    UIView *dropShadowView = [UIView new];
    dropShadowView.backgroundColor = [UIColor duckStoryDropShadowColor];
    dropShadowView.opaque = NO;
    [self addSubview:dropShadowView];
    self.dropShadowView = dropShadowView;
    
    UIView *innerShadowView = [UIView new];
    innerShadowView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    innerShadowView.opaque = NO;
    [self.contentView addSubview:innerShadowView];
    self.innerShadowView = innerShadowView;
    
    UIView *imageBottomView = [UIView new];
    imageBottomView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
    imageBottomView.opaque = NO;
    [self.contentView addSubview:imageBottomView];
    self.imageBottomView = imageBottomView;
    
    self.textLabel = [UILabel new];
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.numberOfLines = 2;
    self.textLabel.opaque = NO;
    [self.contentView addSubview:self.textLabel];
    
    DDGFaviconButton *faviconButton = [DDGFaviconButton buttonWithType:UIButtonTypeCustom];
    faviconButton.frame = CGRectMake(15.0f, 15.0f, 27.0f, 27.0f);
    faviconButton.opaque = NO;
    faviconButton.backgroundColor = [UIColor clearColor];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [faviconButton addTarget:nil action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
#pragma clang diagnostic pop
    [self.contentView addSubview:faviconButton];
    self.faviconButton = faviconButton;
}

#pragma mark -

- (void)layoutSubviews
{
    // Always call your parents.
    [super layoutSubviews];
    
    CGRect bounds = self.contentView.bounds;
    
    // adjust the font sizes according to the space available
    self.categoryButton.titleLabel.font = [UIFont duckStoryCategory];
    self.textLabel.font = [UIFont duckStoryTitleSmall];
    
    CGRect faviconFrame = self.faviconButton.frame;
    CGFloat textWidth = bounds.size.width - faviconFrame.origin.x  -  faviconFrame.size.width - 30;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGRect backgroundImageViewBounds = bounds;
    backgroundImageViewBounds.size.height -= DDGTitleBarHeight;
    self.backgroundImageView.frame = backgroundImageViewBounds;
    
    self.innerShadowView.frame = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 0.5f);
    self.imageBottomView.frame = CGRectMake(bounds.origin.x, bounds.origin.y + backgroundImageViewBounds.size.height-0.5, bounds.size.width, 0.5f);
    self.dropShadowView.frame = CGRectMake(bounds.origin.x, bounds.size.height-0.5, bounds.size.width, 0.5);
    
    CGRect titleBackgroundFrame = [self.titleBackgroundView frame];
    titleBackgroundFrame.size.height = bounds.size.height - backgroundImageViewBounds.size.height;
    titleBackgroundFrame.origin.x = 0;
    titleBackgroundFrame.origin.y = bounds.size.height - titleBackgroundFrame.size.height;
    titleBackgroundFrame.size.width = bounds.size.width;
    
    [self.titleBackgroundView setFrame:titleBackgroundFrame];
    
    CGSize categorySize              = [self.categoryButton sizeThatFits:CGSizeMake(MAXFLOAT, 25)];
    categorySize.width              += 20; // add some space on either side of the text
    self.categoryButton.frame       = CGRectMake(bounds.size.width - 40 - 8 - 8 - categorySize.width, 8, categorySize.width, 25);
    self.backupCategoryButton.frame = CGRectMake(self.categoryButton.frame.origin.x, 0, categorySize.width, 33);
    self.menuButton.frame           = CGRectMake(bounds.size.width - 40 - 8, 8, 40, 25);
    CGFloat categoryButtonEndPoint  =  self.categoryButton.frame.size.width+self.categoryButton.frame.origin.x;
    self.backupMenuButton.frame     = CGRectMake(categoryButtonEndPoint, 0, bounds.size.width-categoryButtonEndPoint, 33);
    self.categoryButton.hidden      = self.story.category==nil;
    
    CGPoint center = [self.faviconButton center];
    center.y = CGRectGetMidY(titleBackgroundFrame);
    [self.faviconButton setCenter:center];
    
    CGRect textFrame = [self.titleBackgroundView frame];
    //textFrame.origin.y += 1.0;
    textFrame.origin.x = 57; //+= faviconFrame.size.width;
    textFrame.size.width = textWidth;
        
    self.textLabel.frame = textFrame;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.backgroundImageView setImage:nil];
}

#pragma mark - DDGPopoverViewController delegate method
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.isShowingMenu = NO;
}

#pragma mark == Save Story ==
- (void)saveStory {
    NSError *saveError;
    [self.story.managedObjectContext save:&saveError];
}

@end
