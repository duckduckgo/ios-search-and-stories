//
//  IGFormSwitch.h
//  Example
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormElement.h"

@interface IGFormSwitch : IGFormElement
@property(nonatomic, strong) UISwitch *switchControl;

-(id)initWithTitle:(NSString *)aTitle enabled:(BOOL)enabled;

@end
