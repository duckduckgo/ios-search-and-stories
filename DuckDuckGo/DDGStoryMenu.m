//
//  DDGStoryMenu.m
//  DuckDuckGo
//
//  Created by Josiah Clumont on 18/01/16.
//
//

#import "DDGStoryMenu.h"


@interface DDGStoryMenuCell : UITableViewCell

@property (nonatomic, strong) UIView* separatorView;
@end


@implementation DDGStoryMenuCell

-(id)init {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DDGStoryMenuCell"];
    if(self) {
        CGRect sepRect      = self.contentView.frame;
        sepRect.origin.x    = -2;
        sepRect.origin.y    = sepRect.size.height-0.5f;
        sepRect.size.height = 0.5f;
        sepRect.size.width += 4;
        self.backgroundColor = [UIColor clearColor];
        self.separatorView = [[UIView alloc] initWithFrame:sepRect];
        self.separatorView.backgroundColor = [UIColor duckTableSeparator];
        self.separatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.separatorView];
        self.selectedBackgroundView.backgroundColor = [UIColor duckTableSeparator];
        
        self.textLabel.font = [UIFont duckFontWithSize:self.textLabel.font.pointSize];
    }
    return self;
}

@end


@implementation DDGStoryMenu


-(id)initWithStoryCell:(DDGStoryCell*)cell
{
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        self.storyCell = cell;
        self.preferredContentSize = CGSizeMake(180, 44 * [self tableView:self.tableView numberOfRowsInSection:0]);
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = FALSE;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger rows = 3; // add/remove-fave, share, view-in-browser[, remove]
    if(self.storyCell.historyItem!=nil) rows++;
    return rows;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGStoryMenuCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DDGStoryMenuCell"];
    cell.indentationWidth = 0;
    if(cell==nil) {
        cell = [[DDGStoryMenuCell alloc] init];
    }
    cell.separatorInset = UIEdgeInsetsMake(0, 10, 0, 10);
    if(indexPath.section==0) {
        switch(indexPath.row) {
            case 0:
                if(self.storyCell.story.savedValue) {
                    cell.textLabel.text = NSLocalizedString(@"Unfavorite", @"story menu item to remove the current story from the favorites");
                    
                } else {
                    cell.textLabel.text = NSLocalizedString(@"Add to Favorites", @"story menu item to add the current story to the favorites");
                }
                break;
            case 1:
                cell.textLabel.text = NSLocalizedString(@"Share", @"story menu item to share the current story");
                break;
            case 2:
                cell.textLabel.text = NSLocalizedString(@"View in Browser", @"story menu item to open the current story in an external browser");
                break;
            case 3:
                cell.textLabel.text = NSLocalizedString(@"Remove", @"story menu item to remove the current story from the history");
                break;
            default:
                cell.textLabel.text = @"?";
        }
    } else {
        cell.textLabel.text = @"?";
    }
    
    cell.separatorView.hidden = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.row) {
        case 0: // fave/un-fave
            self.storyCell.story.savedValue = !self.storyCell.story.savedValue;
            [self.tableView reloadData];
            [self.storyCell performSelector:@selector(saveStoryAndClose) withObject:nil afterDelay:0.5];
            break;
        case 1: // share
            [self.storyCell share];
            break;
        case 2: // open in browser
            [self.storyCell openInBrowser];
            break;
        case 3:
            [self.storyCell removeHistoryItem];
            break;
        default:
            NSLog(@"Warning: unexpected row selected in DDGStoryCellMenu: %@", indexPath);
            break;
    }
    
}

@end // DDGStoryMenu implementation

