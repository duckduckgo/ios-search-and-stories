//
//  DDGProgressBarTextField.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 5/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DDGAddressBarRightButtonModeNone    = -1,
    DDGAddressBarRightButtonModeDefault = 0,
    DDGAddressBarRightButtonModeRefresh = 1,
    DDGAddressBarRightButtonModeStop    = 2,
} DDGAddressBarRightButtonMode;

@interface DDGAddressBarTextField : UITextField <UITextFieldDelegate> {
    CGFloat progress;
}

@property CGFloat additionalLeftSideInset;
@property CGFloat additionalRightSideInset;
@property UIButton* clearButton;
@property UIButton* stopButton;
@property UIButton* reloadButton;

@property (nonatomic, strong) IBOutlet UIView* placeholderView;

-(void)setRightButtonMode:(DDGAddressBarRightButtonMode)newMode;

-(void)resetField;
- (void)safeUpdateText:(NSString*)textToUpdate;

@end
