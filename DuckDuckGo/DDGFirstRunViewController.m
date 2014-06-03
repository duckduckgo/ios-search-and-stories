//
//  DDGFirstRunViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 02/04/2013.
//
//

#import "DDGFirstRunViewController.h"

NSString * const DDGUserDefaultHasShownFirstRunKey = @"DDGUserDefaultHasShownFirstRun";

@interface DDGFirstRunViewController ()

@end

@implementation DDGFirstRunViewController

- (id)init
{
    self = [super initWithNibName:@"DDGFirstRunViewController" bundle:nil];
    if (self) {}
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Ensure the value is serialized immediately.
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DDGUserDefaultHasShownFirstRunKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
