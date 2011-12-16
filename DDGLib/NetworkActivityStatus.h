//
//  NetworkActivityStatus.h
//  DuckDuckGo, Inc
//
//  Created by Chris Heimark on 8/31/09.
//  Copyright 2009 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NetworkActivityStatus : NSObject
{
}

+ (NetworkActivityStatus*)sharedManager;

- (void)activityStarted:(BOOL)started;

@end
