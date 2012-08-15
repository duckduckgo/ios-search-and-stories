//
//  DDGUnderViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import "DDGUnderViewController.h"
#import "ECSlidingViewController.h"
#import "DDGHomeViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGWebViewController.h"
#import "DDGBookmarksViewController.h"

@implementation DDGUnderViewController

-(id)initWithHomeViewController:(UIViewController *)homeViewController {
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        viewControllers = @[
            @[
                @{
                    @"title" : @"Stories",
                    @"viewController" : homeViewController
                },
                @{
                    @"title" : @"Saved Pages",
                    @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil]]
                },
                @{
                    @"title" : @"Settings",
                    @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGSettingsViewController alloc] initWithDefaults]]
                }
            ],
            @[].mutableCopy
        ].mutableCopy;
        
        self.clearsSelectionOnViewWillAppear = NO;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    return self;
}

-(void)configureViewController:(UIViewController *)viewController {
    [viewController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    viewController.view.layer.shadowOpacity = 0.75f;
    viewController.view.layer.shadowRadius = 10.0f;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

#pragma mark - Navigation management

-(void)addPageWithQueryOrURL:(NSString *)queryOrURL title:(NSString *)title {
    if(!title)
        title = queryOrURL;
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        
        DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
        [webVC loadQueryOrURL:queryOrURL];
        
        [[viewControllers lastObject] addObject:@{@"title" : title, @"viewController" : webVC}];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[viewControllers lastObject] count]-1
                                                    inSection:viewControllers.count-1];
        
        [self.tableView insertRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationTop];
    
        // wait for the insert animation to finish before selecting/loading the new page
        CGFloat delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        });
    }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return viewControllers.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[viewControllers objectAtIndex:section] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return (section == 1 ? @"Pages" : nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.textLabel.text = [[[viewControllers objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"title"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *newTopViewController = [[[viewControllers objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"viewController"];
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
        
        [self configureViewController:newTopViewController];
    }];
}

@end
