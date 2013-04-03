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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DDGUserDefaultHasShownFirstRunKey];
}

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
