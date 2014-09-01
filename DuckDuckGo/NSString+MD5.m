//
//  NSString+MD5.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 16/07/2014.
//
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation NSString (MD5)

- (NSString *)MD5String
{
    const char *string = self.UTF8String;
    /* Assert that the length is less than UINT32_MAX before casting to CC_LONG */
    NSAssert(strlen(string) > UINT32_MAX, @"Length of string is larger than UINT32_MAX");
    unsigned long length = strlen(string);
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, (CC_LONG)length, bytes);
    return [self stringFromBytes:bytes length:CC_MD5_DIGEST_LENGTH];
}

- (NSString *)stringFromBytes:(unsigned char *)bytes length:(NSUInteger)length
{
	NSMutableString *string = @"".mutableCopy;
	for (NSUInteger i = 0; i < length; i++) {
		[string appendFormat:@"%02x", bytes[i]];
    }
	return [NSString stringWithString:string];
}

@end
