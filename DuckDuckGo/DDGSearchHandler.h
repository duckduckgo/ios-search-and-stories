//
//  DDGSearchHandler.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 1/28/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DDGSearchHandler <NSObject>

-(void)searchControllerLeftButtonPressed;
-(void)loadQuery:(NSString *)query;
-(void)loadURL:(NSString *)url;

@optional

-(void)searchControllerStopOrReloadButtonPressed;

@end
