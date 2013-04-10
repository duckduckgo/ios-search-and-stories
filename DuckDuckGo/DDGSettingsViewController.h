//
//  DDGSettingsViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "IGFormViewController.h"
#import <MessageUI/MessageUI.h>

extern NSString * const DDGSettingRecordHistory;
extern NSString * const DDGSettingQuackOnRefresh;
extern NSString * const DDGSettingRegion;
extern NSString * const DDGSettingAutocomplete;
extern NSString * const DDGSettingStoriesReadView;
extern NSString * const DDGSettingHomeView;

extern NSString * const DDGSettingHomeViewTypeStories;
extern NSString * const DDGSettingHomeViewTypeRecents;
extern NSString * const DDGSettingHomeViewTypeDuck;

@interface DDGSettingsViewController : IGFormViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

+(void)loadDefaultSettings;

@end
