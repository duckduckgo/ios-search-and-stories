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
                    @"title" : @"Saved",
                    @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil]]
                },
                @{
                    @"title" : @"Settings",
                    @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGSettingsViewController alloc] initWithDefaults]]
                }
            ],
            @[].mutableCopy
        ].mutableCopy;
    
        self.tableView.scrollsToTop = NO;
        
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_bg.png"]];
        self.tableView.separatorColor = [UIColor colorWithWhite:0 alpha:0.25];

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

    void (^insertAndLoad)() = ^{
        DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
        [webVC loadQueryOrURL:queryOrURL];
        
        [[viewControllers lastObject] insertObject:@{@"title" : title, @"viewController" : webVC} atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0
                                                    inSection:viewControllers.count-1];
        
        [self.tableView insertRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationTop];
        
        // wait for the insert animation to finish before selecting/loading the new page
        CGFloat delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            UIViewController *newTopViewController = [[[viewControllers objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"viewController"];
            
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
            
            [self configureViewController:newTopViewController];
        });
    };

    if(self.slidingViewController.underLeftShowing) {
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:insertAndLoad];
    } else {
        CGFloat oldAnchorRightRevealAmount = self.slidingViewController.anchorRightRevealAmount;
        self.slidingViewController.anchorRightRevealAmount = 50.0;
        [self.slidingViewController anchorTopViewTo:ECRight animations:nil onComplete:^{
            insertAndLoad();
            self.slidingViewController.anchorRightRevealAmount = oldAnchorRightRevealAmount;
        }];
    }
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
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
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
