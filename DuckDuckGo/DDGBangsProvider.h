//
//  DDGBangsProvider.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 6/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDGBangsProvider : NSObject

+(NSArray *)bangs;
+(NSArray *)bangsWithPrefix:(NSString *)prefix;

@end
