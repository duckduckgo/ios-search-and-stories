//
//  DDGStory.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import "DDGStory.h"
#import "NSOperationStack.h"
#import "DDGUtility.h"

@interface DDGStory () {
    UIImage *_image;
    UIImage *_blurredImage;
}
@end

@implementation DDGStory

@synthesize blurredImage = _blurredImage;

- (NSString *)cacheKey
{
    return self.imageURLString;
}

- (void)setURL:(NSURL *)URL
{
    self.urlString = [URL absoluteString];
}

- (NSURL *)URL
{
    NSURL *URL = nil;
    NSString *URLString = self.urlString;
    if (nil != URLString) {
        URL = [NSURL URLWithString:URLString];
    }
    return URL;
}

- (void)setImageURL:(NSURL *)imageURL
{
    self.imageURLString = [imageURL absoluteString];
}

- (NSURL *)imageURL
{
    NSURL *imageURL = nil;
    NSString *imageURLString = self.imageURLString;
    if (nil != imageURLString) {
        imageURL = [NSURL URLWithString:imageURLString];
    }
    return imageURL;
}

-(NSString *)baseFilePath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
}

- (NSString *)description
{
    return [[super description] stringByAppendingFormat:@" %@ - %@", self.id, self.title];
}

- (BOOL)isImageDownloaded
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self imageFilePath]];;
}

- (BOOL)isHTMLDownloaded
{
    return self.htmlDownloadedValue;
}

- (void)prepareForDeletion
{
    [super prepareForDeletion];
    [self deleteImage];
    [self deleteHTML];
}

#pragma mark - Image

-(UIImage *)image
{
    UIImage *image = nil;
    if (self.isImageDownloaded) {
        NSData *imageData = [NSData dataWithContentsOfFile:self.imageFilePath];
        image = [UIImage imageWithData:imageData];
    }
    return image;
}

-(void)deleteImage
{
    [[NSFileManager defaultManager] removeItemAtPath:[self imageFilePath] error:nil];
}

- (BOOL)writeImageData:(NSData *)data
{
    return [data writeToFile:[self imageFilePath] atomically:NO];
}

-(NSString *)imageFilePath
{
    return [[self baseFilePath] stringByAppendingPathComponent:[self.imageURL lastPathComponent]];
}

#pragma mark - HTML

- (void)deleteHTML
{
    [[NSFileManager defaultManager] removeItemAtPath:[self HTMLFilePath] error:nil];
    self.htmlDownloadedValue = NO;
}

- (NSString *)HTML
{
    return [NSString stringWithContentsOfFile:[self HTMLFilePath] encoding:NSUTF8StringEncoding error:nil];
}

- (NSURLRequest *)HTMLURLRequest
{
    if (!self.htmlDownloadedValue) {
        return nil;
    }
    return [DDGUtility requestWithURL:[NSURL fileURLWithPath:[self HTMLFilePath]]];
}

- (void)writeHTMLString:(NSString *)html completion:(void (^)(BOOL success))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL suceess = [html writeToFile:[self HTMLFilePath] atomically:NO encoding:NSUTF8StringEncoding error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.managedObjectContext performBlockAndWait:^{
                self.htmlDownloadedValue = YES;
            }];
            if (completion)
                completion(suceess);
        });
    });
}

-(NSString *)HTMLFilePath
{
    return [[self baseFilePath] stringByAppendingPathComponent:[@"story" stringByAppendingFormat:@"%@.html",self.id]];
}

@end
