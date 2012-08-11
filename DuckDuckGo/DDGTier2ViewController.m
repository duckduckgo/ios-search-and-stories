//
//  DDGTier2ViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/6/12.
//
//

#import "DDGTier2ViewController.h"
#import "DDGNewsProvider.h"
#import "DDGSearchController.h"
#import "DDGStory.h"

@implementation DDGTier2ViewController

- (id)initWithSuggestionItem:(NSDictionary *)suggestionItem {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.suggestionItem = suggestionItem;
        
        // download news
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSArray *keywords = @[[suggestionItem objectForKey:@"phrase"]];
            NSMutableArray *theNews = [NSMutableArray array];
            [[DDGNewsProvider sharedProvider] downloadCustomStoriesForKeywords:keywords
                                                                       toArray:theNews];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                news = theNews.copy;
                [[self tableView] reloadData];
            });
        });
        
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(DDGSearchController *)searchController {
    return (DDGSearchController *)self.navigationController.parentViewController;
}

#pragma mark - Suggestion item management

-(void)setSuggestionItem:(NSDictionary *)suggestionItem {
    _suggestionItem = suggestionItem;
    
    self.title = [_suggestionItem objectForKey:@"phrase"];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"News";
        case 1:
            return @"Calls";
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return news.count;
        case 1:
            return [[_suggestionItem objectForKey:@"calls"] count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CallCellIdentifier = @"CallCell";
    static NSString *NewsCellIdentifier = @"NewsCell";

    UITableViewCell *cell;
    if(indexPath.section==0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CallCellIdentifier];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NewsCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textLabel.text = [[news objectAtIndex:indexPath.row] title];
    } else if(indexPath.section==1) {
        cell = [tableView dequeueReusableCellWithIdentifier:CallCellIdentifier];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CallCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        NSString *call = [[_suggestionItem objectForKey:@"calls"] objectAtIndex:indexPath.row];
        cell.textLabel.text = call;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0) {
        [self.searchController.searchHandler loadQueryOrURL:[(DDGStory *)[news objectAtIndex:indexPath.row] url]];
    } else if(indexPath.section==1) {
        NSString *call = [[_suggestionItem objectForKey:@"calls"] objectAtIndex:indexPath.row];
        NSString *query = [[_suggestionItem objectForKey:@"phrase"] stringByAppendingFormat:@" %@",call];
        
        [self.searchController.searchHandler loadQueryOrURL:query];
    }
    [self.searchController dismissAutocomplete];
    
    // workaround for a UINavigationController bug
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.navigationController popViewControllerAnimated:NO];
    });
}

@end
