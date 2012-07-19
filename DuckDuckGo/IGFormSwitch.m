//
//  IGFormSwitch.m
//  Example
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormSwitch.h"

@implementation IGFormSwitch
@synthesize switchControl;

-(id)initWithTitle:(NSString *)aTitle enabled:(BOOL)enabled {
    self = [super initWithTitle:aTitle];
    if(self) {
        self.switchControl = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.switchControl.on = enabled;
    }
    return self;
}

@end
