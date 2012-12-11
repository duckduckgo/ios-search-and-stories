//
//  DDGUtility.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 12/11/12.
//
//

#import "DDGUtility.h"

@implementation DDGUtility

+ (NSString*)agentDDG
{
	return [@"DDG-iOS-" stringByAppendingString:(__bridge NSString*)CFBundleGetValueForInfoDictionaryKey (CFBundleGetMainBundle(), kCFBundleVersionKey)];
}

@end
