//
//  DDGDuckViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import "DDGDuckViewController.h"

@interface DDGDuckViewController ()

@end

@implementation DDGDuckViewController

#pragma mark -

+ (id)duckViewController {
    return [[DDGDuckViewController alloc] initWithNibName:@"DDGDuckViewController" bundle:nil];
}

#pragma mark -

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

@end
