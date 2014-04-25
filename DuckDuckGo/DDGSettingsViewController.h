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

#define DDG_SETTINGS_HEADER(view, title) view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];           \
view.opaque = NO;   \
view.backgroundColor = [UIColor clearColor];    \
{UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 16.0, 0.0)];  \
titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;   \
titleLabel.opaque = NO; \
titleLabel.backgroundColor = [UIColor clearColor];  \
titleLabel.font = [UIFont systemFontOfSize:15.0];    \
titleLabel.text = title;   \
titleLabel.textColor = [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];   \
[view addSubview:titleLabel];}

#define DDG_SETTINGS_FOOTER(view, title) view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];           \
view.opaque = NO;   \
view.backgroundColor = [UIColor clearColor];    \
{UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 16.0, 0.0)];  \
titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;   \
titleLabel.opaque = NO; \
titleLabel.backgroundColor = [UIColor clearColor];  \
titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13];    \
titleLabel.textAlignment = NSTextAlignmentCenter; \
titleLabel.text = title;   \
titleLabel.textColor = [UIColor colorWithRed:0.341 green:0.376 blue:0.424 alpha:1.000]; \
[view addSubview:titleLabel];}

#define DDG_SETTINGS_TITLE_LABEL(titleLabel) \
titleLabel.font = [UIFont systemFontOfSize:17.0]; \
titleLabel.textColor = [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];

#define DDG_SETTINGS_DETAIL_LABEL(detailTextLabel) \
detailTextLabel.font = [UIFont systemFontOfSize:15.0];    \
detailTextLabel.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];

@interface DDGSettingsViewController : DDGFormViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

+(void)loadDefaultSettings;
-(IBAction)save:(id)sender;

@end
