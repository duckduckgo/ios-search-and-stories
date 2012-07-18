//
//  IGFormSection.h
//  CramberryPad
//
//  Created by Ishaan Gulrajani on 4/3/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IGFormElement : NSObject {
	NSString *title;
}
@property(nonatomic,readonly) NSString *title;

-(id)initWithTitle:(NSString *)aTitle;

@end
