//
//  DDGSearchHandler.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DDGSearchHandler <NSObject>

-(void)loadButton;
-(void)loadQuery:(NSString *)query;
-(void)loadURL:(NSString *)url;

@end
