//
//  IGFormTextField.h
//  CramberryPad
//
//  Created by Ishaan Gulrajani on 4/3/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IGFormElement.h"

@interface IGFormTextField : IGFormElement {
	UITextField *textField;
}
@property(nonatomic,readonly) UITextField *textField;

@end
