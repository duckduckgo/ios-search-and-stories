//
//  IGFormRadioOption.h
//  Programming
//
//  Created by Ishaan Gulrajani on 4/4/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IGFormElement.h"

@interface IGFormRadioOption : IGFormElement {
	NSString *__weak category;
	BOOL value;
}
@property(weak, nonatomic,readonly) NSString *category;
@property(nonatomic) BOOL value;

-(id)initWithCategory:(NSString *)aCategory title:(NSString *)aTitle;

@end
