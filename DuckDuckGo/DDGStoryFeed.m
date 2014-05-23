#import "DDGStoryFeed.h"

@implementation DDGStoryFeed

// Custom logic goes here.

- (void)setURL:(NSURL *)URL {
    self.urlString = [URL absoluteString];
}

- (NSURL *)URL {
    NSURL *URL = nil;
    NSString *URLString = self.urlString;
    if (nil != URLString)
        URL = [NSURL URLWithString:URLString];
    return URL;
}

- (void)setImageURL:(NSURL *)imageURL {
    self.imageURLString = [imageURL absoluteString];
}

- (NSURL *)imageURL {
    NSURL *imageURL = nil;
    NSString *imageURLString = self.imageURLString;
    if (nil != imageURLString)
        imageURL = [NSURL URLWithString:imageURLString];
    return imageURL;
}

-(NSString *)baseFilePath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" %@ - %@", self.id, self.title];
}

- (BOOL)isImageDownloaded {
    return self.imageDownloadedValue;
}

#pragma mark - Image

-(UIImage *)image {
    UIImage *image = nil;
    if (self.imageDownloadedValue) {
        NSData *imageData = [NSData dataWithContentsOfFile:self.imageFilePath];
        image = [UIImage imageWithData:imageData];
    }
    
    return image;
}

-(void)deleteImage {
    [[NSFileManager defaultManager] removeItemAtPath:[self imageFilePath] error:nil];
    self.imageDownloaded = NO;
}

- (void)writeImageData:(NSData *)data completion:(void (^)(BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL suceess = [data writeToFile:[self imageFilePath] atomically:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion)
                completion(suceess);
        });
    });
}

-(NSString *)imageFilePath {
    return [[self baseFilePath] stringByAppendingPathComponent:[@"feed-image-" stringByAppendingFormat:@"%@.png",self.id]];
}

- (DDGStoryFeedState)feedState
{
    DDGStoryFeedState state = [self.enabled integerValue];
    if (state == DDGStoryFeedStateDefault) {
        state = (DDGStoryFeedState)[self.enabledByDefault integerValue];
    }
    return state;
}

- (void)setFeedState:(DDGStoryFeedState)feedState
{
    self.enabled = [NSNumber numberWithInteger:feedState];
}

@end
