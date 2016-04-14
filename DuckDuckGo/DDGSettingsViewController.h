//
//  DDGSettingsViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGFormViewController.h"
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

#define DDG_SETTINGS_BACKGROUND_COLOR [UIColor colorWithRed:248.0f/255.0f green:248.0f/255.0f blue:248.0f/255.0f alpha:1.000]


@interface DDGSettingsViewController : DDGFormViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

-(IBAction)save:(id)sender;

- (UIViewController*)duckContainerController;

+(void)loadDefaultSettings;
+(UIView*)createSectionHeaderView:(NSString*)title;
+(UIView*)createSectionFooterView:(NSString*)title;
+(void)configureSettingsCell:(UITableViewCell*)cell;
+(void)configureTable:(UITableView*)tableView;

@end
