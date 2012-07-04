//
//  DDGProgressBarTextField.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 5/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DDGAddressBarTextField : UITextField <UITextFieldDelegate> {
    CGFloat progress;
}

-(void)setProgress:(CGFloat)newProgress;

@end
