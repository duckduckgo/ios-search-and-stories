//
//  DDGSearchHandler.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 1/28/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DDGStory;
@protocol DDGSearchHandler <NSObject>

-(void)searchControllerLeftButtonPressed;
-(void)loadQueryOrURL:(NSString *)queryOrURLString;
-(void)prepareForUserInput;

@optional
-(void)beginSearchInputWithString:(NSString *)string;
-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode;
-(void)searchControllerStopOrReloadButtonPressed;
-(void)searchControllerAddressBarWillOpen;
-(void)searchControllerAddressBarWillCancel;
-(void)searchControllerActionButtonPressed:(id)sender;

@end
