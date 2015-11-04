//
//  DDGImageActivityItemProvider.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 26/09/2015.
//
//

#import "DDGImageActivityItemProvider.h"

@interface DDGImageActivityItemProvider ()
@property NSURL* imageURL;
@end

@implementation DDGImageActivityItemProvider


#pragma mark UIActivityItemProvider

- (instancetype)initWithImageURL:(NSURL*)imageURL
{
    self = [super initWithPlaceholderItem:[DDGImageActivityItemProvider placeholderImage]];
    if(self) {
        self.imageURL = imageURL;
    }
    return self;
}

- (id)item
{
    if ([self.activityType isEqualToString:UIActivityTypeMail]) {
        return nil;
    }
    
    return [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageURL]];
}


+ (UIImage *)placeholderImage
{
    UIImage *placeholderImage = nil;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0f, 1.0f), NO, 0);
    placeholderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return placeholderImage;
}

@end