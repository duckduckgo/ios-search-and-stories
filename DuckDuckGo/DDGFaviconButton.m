//
//  DDGFaviconButton.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 22/02/2013.
//
//

#import "DDGFaviconButton.h"

@implementation DDGFaviconButton

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGSize imageSize = CGSizeMake(MIN(24.0, contentRect.size.width),
                                  MIN(24.0, contentRect.size.height));
    
    return CGRectIntegral(CGRectMake(contentRect.origin.x + ((contentRect.size.width - imageSize.width)/2.0),
                                     contentRect.origin.y + ((contentRect.size.height - imageSize.height)/2.0),
                                     imageSize.width,
                                     imageSize.height));
}

@end
