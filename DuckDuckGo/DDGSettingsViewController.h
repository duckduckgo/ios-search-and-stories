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
extern NSString * const DDGSettingSuppressBangTooltip;
extern NSString * const DDGSettingRegion;
extern NSString * const DDGSettingAutocomplete;
extern NSString * const DDGSettingStoriesReadabilityMode;
extern NSString * const DDGSettingHomeView;

extern NSString * const DDGSettingHomeViewTypeStories;
extern NSString * const DDGSettingHomeViewTypeSaved;
extern NSString * const DDGSettingHomeViewTypeRecents;
extern NSString * const DDGSettingHomeViewTypeDuck;

typedef enum DDGReadabilityMode {
    DDGReadabilityModeOff,
    DDGReadabilityModeOnIfAvailable,
    DDGReadabilityModeOnExclusive
} DDGReadabilityMode;

#define DDG_SETTINGS_BACKGROUND_COLOR [UIColor colorWithRed:0.910 green:0.914 blue:0.922 alpha:1.000]

@interface DDGSettingsViewController : IGFormViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

+(void)loadDefaultSettings;
-(IBAction)save:(id)sender;

@end
