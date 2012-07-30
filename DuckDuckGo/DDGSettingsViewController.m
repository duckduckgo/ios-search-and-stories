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
#import "SHK.h"

@implementation DDGSettingsViewController

+(void)loadDefaultSettings {
    NSDictionary *defaults = @{@"history": @(YES),
                              @"refresh3g": @(YES),
                              @"quack": @(NO)};
    
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
    
    [self addSectionWithTitle:nil];
    [self addButton:@"Share this app" action:^{
        SHKItem *shareItem = [SHKItem URL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/duckduckgo-search/id479988136?mt=8&uo=4"] title:@"Check out the DuckDuckGo app!" contentType:SHKURLContentTypeWebpage];
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:shareItem];
        [actionSheet showInView:self.view];
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
