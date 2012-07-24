//
//  DDGAddCustomSourceViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/24/12.
//
//

#import "DDGAddCustomSourceViewController.h"

@implementation DDGAddCustomSourceViewController

-(void)configure {
    self.title = @"Add Source";
    
    [self addTextField:@"News keyword"];
}

-(void)saveData:(NSDictionary *)formData {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"not yet implemented" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
