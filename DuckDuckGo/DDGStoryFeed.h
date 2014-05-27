#import "_DDGStoryFeed.h"

typedef NS_ENUM(NSInteger, DDGStoryFeedState) {
    DDGStoryFeedStateDisabled = 0,
    DDGStoryFeedStateEnabled,
    DDGStoryFeedStateDefault
};

@interface DDGStoryFeed : _DDGStoryFeed {}

@property (nonatomic, assign) DDGStoryFeedState feedState;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, readonly) UIImage *image;

- (void)writeImageData:(NSData *)data completion:(void (^)(BOOL success))completion;

@end
