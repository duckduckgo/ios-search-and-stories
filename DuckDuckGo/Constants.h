//
//  Constants.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/1/12.
//
//

#import <UIKit/UIKit.h>

extern NSString * const kDDGTypeInfoURLString;
extern NSString * const kDDGStoriesURLString;
extern NSString * const kDDGCustomStoriesURLString;
extern NSString * const kDDGSuggestionsURLString;
extern NSString * const kDDGSettingsRefreshData;
extern NSString * const kDDGNotificationExpandToolNavBar;
extern NSString * const kDDGMiniOnboardingName;

// System version macros
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define SYSTEM_VERSION_MAJOR_AS_INT                 ([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue])

#define DEVICE_IS_IPAD ( UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM())
