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
#import "DDGJSONViewController.h"

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
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_suggestionItem objectForKey:@"phrase"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_suggestionItem objectForKey:@"calls"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CallCellIdentifier = @"CallCell";
    
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:CallCellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CallCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [[[_suggestionItem objectForKey:@"calls"] objectAtIndex:indexPath.row] objectForKey:@"name"];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *call = [[_suggestionItem objectForKey:@"calls"] objectAtIndex:indexPath.row];
    BOOL dismissAutocomplete = NO;

        NSURL *external = [NSURL URLWithString:[call objectForKey:@"external"]];
        if(external && [[UIApplication sharedApplication] canOpenURL:external]) {
            [[UIApplication sharedApplication] openURL:external];
            dismissAutocomplete = YES;
        } else if([call objectForKey:@"json"]) {
            DDGJSONViewController *jsonVC = [[DDGJSONViewController alloc] init];
            jsonVC.jsonURL = [NSURL URLWithString:[call objectForKey:@"json"]];
            
            [self.navigationController pushViewController:jsonVC animated:YES];
        } else {
            [self.searchController.searchHandler loadQueryOrURL:[call objectForKey:@"url"]];
            dismissAutocomplete = YES;
        }
    
    if(dismissAutocomplete) {
        [self.searchController dismissAutocomplete];
        // workaround for a UINavigationController bug
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.navigationController popViewControllerAnimated:NO];
        });
    }
}

@end
