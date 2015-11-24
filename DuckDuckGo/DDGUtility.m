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

+ (NSURLRequest *)requestWithURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    if ([[URL host] hasSuffix:@"duckduckgo.com"]) {
        [request setValue:[DDGUtility agentDDG] forHTTPHeaderField:@"User-Agent"];
    }
    return [request copy];
}

+(BOOL)looksLikeURL:(NSString*)text
{
    return [text hasPrefix:@"http://"] || [text hasPrefix:@"https://"];
}


@end
