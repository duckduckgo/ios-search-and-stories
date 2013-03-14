//
//  NSString+URLEncodingDDG.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 14/03/2013.
//
//

#import "NSString+URLEncodingDDG.h"

@implementation NSString (URLEncodingDDG)

- (NSString *)URLDecodedStringDDG
{
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
}

- (NSString *)URLEncodedStringDDG
{
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																						(__bridge CFStringRef)self,
																						NULL,
																						CFSTR("!*'();:@&=$,/?%#[]"), // BUT NOT + 'cause we'll take care of that
																						kCFStringEncodingUTF8);
	return [s stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
}

@end
