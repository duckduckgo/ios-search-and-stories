//
//  DDGDuckViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import "DDGAddressBarTextField.h"
#import "DDGDuckViewController.h"
#import "DDGSearchBar.h"
#import "DDGSearchController.h"

@interface DDGDuckViewController ()

@property (nonatomic, weak) DDGSearchController *searchController;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;

@end

@implementation DDGDuckViewController

#pragma mark -

- (instancetype)initWithSearchController:(DDGSearchController *)searchController
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.searchController = searchController;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    DDGSearchBar *searchBar = [self.searchController searchBar];
    DDGAddressBarTextField *addressBarTextField = searchBar.searchField;
    [addressBarTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
    [self.searchController searchFieldDidChange:nil];
}

#pragma mark -

- (void)updateContainerHeightConstraint:(BOOL)keyboardShowing
{
    [self.containerViewHeightConstraint setConstant:keyboardShowing ? 170.0f : 230.0f];
}

@end
