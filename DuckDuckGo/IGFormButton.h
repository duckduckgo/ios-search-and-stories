//
//  IGFormButton.h
//  Example
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 Ishaan Gulrajani. All rights reserved.
//

#import "IGFormElement.h"

@interface IGFormButton : IGFormElement

@property(nonatomic, strong) void(^action)(void);
@property(nonatomic, strong) NSString *path;
@property(nonatomic, assign) IGFormButtonType type;

-(id)initWithTitle:(NSString *)aTitle path:(NSString*)aPath action:(void(^)(void))anAction;

@end
