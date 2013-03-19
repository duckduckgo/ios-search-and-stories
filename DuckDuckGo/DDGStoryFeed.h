#import "_DDGStoryFeed.h"

@interface DDGStoryFeed : _DDGStoryFeed {}

@property(nonatomic, strong) NSURL *URL;
@property(nonatomic, strong) NSURL *imageURL;
@property(nonatomic, readonly) UIImage *image;

- (void)writeImageData:(NSData *)data completion:(void (^)(BOOL success))completion;

@end
