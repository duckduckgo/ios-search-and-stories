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

-(NSString *)cacheDirPath {
  return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask,YES) objectAtIndex:0];
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" %@ - %@", self.id, self.title];
}

- (BOOL)isImageDownloaded {
  NSFileManager* fm = [NSFileManager defaultManager];
  return self.imageDownloadedValue && ([fm fileExistsAtPath:self.imageFilePath] || [fm fileExistsAtPath:self.oldImageFilePath]);
}

#pragma mark - Image

-(UIImage *)image {
  UIImage *image = nil;
  if([self isImageDownloaded]) {
    NSData *imageData = [NSData dataWithContentsOfFile:self.imageFilePath];
    if(imageData == nil) {
      imageData = [NSData dataWithContentsOfFile:self.oldImageFilePath];
    }
    image = [UIImage imageWithData:imageData];
  }
  
  return image;
}

-(void)deleteImage {
    [[NSFileManager defaultManager] removeItemAtPath:[self imageFilePath] error:nil];
    self.imageDownloadedValue = NO;
}

- (void)writeImageData:(NSData *)data completion:(void (^)(BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSURL* url = [NSURL fileURLWithPath:[self imageFilePath]];
      BOOL result = [data writeToURL:url atomically:NO];
      
      if(result) { // mark the file as not to be backed up
        NSError* error = nil;
        BOOL success = [url setResourceValue:[NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey
                                       error: &error];
        if(!success){
          NSLog(@"Error excluding %@ from backup %@", url, error);
        }
      }
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(result);
      });
    });
}

-(NSString *)imageFilePath {
  return [[self cacheDirPath] stringByAppendingPathComponent:[@"feed-image-" stringByAppendingFormat:@"%@.png",self.id]];
}

-(NSString *)oldImageFilePath {
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
