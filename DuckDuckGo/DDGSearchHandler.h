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
-(void)loadQueryOrURL:(NSString *)queryOrURLString;

@optional

-(void)searchControllerStopOrReloadButtonPressed;
-(void)searchControllerAddressBarWillOpen;
-(void)searchControllerAddressBarWillCancel;

@end
