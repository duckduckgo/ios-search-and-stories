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
    if(![DDGCache objectForKey:@"history" inCache:@"settings"])
        [DDGCache setObject:[NSNumber numberWithBool:YES] 
                     forKey:@"history" 
                    inCache:@"settings"];
}

-(void)configure {
    self.title = @"Settings";
    
    [self addSectionWithTitle:@"General"];
    [self addSwitch:@"Record history" enabled:[[DDGCache objectForKey:@"history" inCache:@"settings"] boolValue]];
    
    [self addSectionWithTitle:@"News"];
    [self addButton:@"Configure news sources" action:^{
        DDGNewsSourcesViewController *sourcesVC = [[DDGNewsSourcesViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:sourcesVC animated:YES];
    }];
}

-(void)saveData:(NSDictionary *)formData {
    [DDGCache setObject:[formData objectForKey:@"Record history"] 
                 forKey:@"history" 
                inCache:@"settings"];
}

@end
