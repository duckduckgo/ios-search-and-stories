//
//  DDGSettingsViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "IGFormViewController.h"
#import <MessageUI/MessageUI.h>

@interface DDGSettingsViewController : IGFormViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

+(void)loadDefaultSettings;

@end
