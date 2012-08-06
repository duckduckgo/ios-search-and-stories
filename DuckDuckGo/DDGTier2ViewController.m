//
//  DDGTier2ViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/6/12.
//
//

#import "DDGTier2ViewController.h"
#import "DDGSearchController.h"

@implementation DDGTier2ViewController

- (id)initWithSuggestionItem:(NSDictionary *)suggestionItem {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.suggestionItem = suggestionItem;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_suggestionItem objectForKey:@"calls"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *call = [[_suggestionItem objectForKey:@"calls"] objectAtIndex:indexPath.row];
    cell.textLabel.text = call;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *call = [[_suggestionItem objectForKey:@"calls"] objectAtIndex:indexPath.row];
    NSString *query = [[_suggestionItem objectForKey:@"phrase"] stringByAppendingFormat:@" %@",call];
    
    [self.searchController.searchHandler loadQueryOrURL:query];
    [self.searchController dismissAutocomplete];
    
    // workaround for a UINavigationController bug
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.navigationController popViewControllerAnimated:NO];
    });
}

@end
