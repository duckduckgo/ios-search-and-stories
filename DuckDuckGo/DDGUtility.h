//
//  DDGUtility.h
//  DuckDuckGo
//
//  Created by Chris Heimark on 12/11/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGUtility : NSObject

+ (NSString*)agentDDG;
+ (NSURLRequest *)requestWithURL:(NSURL *)URL;
+ (BOOL)looksLikeURL:(NSString*)text;

@end
