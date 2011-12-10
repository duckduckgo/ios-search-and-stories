//
//  NetworkActivityStatus.h
//  CHS Systems
//
//  Created by Chris Heimark on 8/31/09.
//  Copyright 2009 CHS Systems. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NetworkActivityStatus : NSObject
{
}

+ (NetworkActivityStatus*)sharedManager;

- (void)activityStarted:(BOOL)started;

@end
