//
//  DDGStory.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import "_DDGStory.h"

@interface DDGStory : _DDGStory

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, strong) UIImage *blurredImage;
@property (nonatomic, readonly) BOOL isImageDownloaded;
@property (nonatomic, readonly) BOOL isHTMLDownloaded;
@property (nonatomic, copy, readonly) NSString *cacheKey;

- (void)deleteImage;
- (void)deleteHTML;

- (NSString *)HTML;
- (NSURLRequest *)HTMLURLRequest;

- (void)writeHTMLString:(NSString *)html completion:(void (^)(BOOL success))completion;
- (BOOL)writeImageData:(NSData *)data;

@end
