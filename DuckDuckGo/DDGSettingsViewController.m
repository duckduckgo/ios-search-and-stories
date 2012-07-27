//
//  DDGSettingsViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSettingsViewController.h"
#import "DDGCache.h"
#import "DDGNewsSourcesViewController.h"

@implementation DDGSettingsViewController

+(void)loadDefaultSettings {
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], @"history",
                              [NSNumber numberWithBool:YES], @"refresh3g",
                              [NSNumber numberWithBool:NO], @"quack",
                              nil];
    
    for(NSString *key in defaults) {
        if(![DDGCache objectForKey:key inCache:@"settings"])
            [DDGCache setObject:[defaults objectForKey:key] 
                         forKey:key 
                        inCache:@"settings"];
    }
}

-(void)configure {
    self.title = @"Settings";
    
    [self addSectionWithTitle:@"General"];
    [self addSwitch:@"Quack on refresh" enabled:[[DDGCache objectForKey:@"quack" inCache:@"settings"] boolValue]];

    [self addSectionWithTitle:nil footer:@"History is stored on your phone."];
    [self addSwitch:@"Record history" enabled:[[DDGCache objectForKey:@"history" inCache:@"settings"] boolValue]];


    [self addSectionWithTitle:@"Water Cooler"];
    [self addSwitch:@"Refresh over 3G" enabled:[[DDGCache objectForKey:@"refresh3g" inCache:@"settings"] boolValue]];
    [self addButton:@"Change sources" action:^{
        DDGNewsSourcesViewController *sourcesVC = [[DDGNewsSourcesViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:sourcesVC animated:YES];
    }];
}

-(void)saveData:(NSDictionary *)formData {
    [DDGCache setObject:[formData objectForKey:@"Record history"] 
                 forKey:@"history" 
                inCache:@"settings"];

    [DDGCache setObject:[formData objectForKey:@"Refresh over 3G"]
                 forKey:@"refresh3g"
                inCache:@"settings"];
    
    [DDGCache setObject:[formData objectForKey:@"Quack on refresh"] 
                 forKey:@"quack" 
                inCache:@"settings"];
}

@end
