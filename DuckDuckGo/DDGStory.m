//
//  DDGStory.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import "DDGStory.h"
#import "NSOperationStack.h"

@interface DDGStory () {
    UIImage *_image;
}
@property(nonatomic, readwrite, getter = isImageDownloaded) BOOL imageDownloaded;
@property(nonatomic, readwrite, getter = isHTMLDownloaded) BOOL HTMLDownloaded;
@property(nonatomic, readwrite, strong) UIImage *image;
@end

@implementation DDGStory

#pragma mark - NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if(self) {
        self.storyID = [aDecoder decodeObjectForKey:@"storyID"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.feed = [aDecoder decodeObjectForKey:@"feed"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
        self.article_url = [aDecoder decodeObjectForKey:@"article_url"];
        self.imageURL = [NSURL URLWithString:[aDecoder decodeObjectForKey:@"imageURL"]];
        self.imageDownloaded = [aDecoder decodeBoolForKey:@"imageDownloaded"];
        self.HTMLDownloaded = [aDecoder decodeBoolForKey:@"HTMLDownloaded"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.storyID forKey:@"storyID"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.feed forKey:@"feed"];
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:self.article_url forKey:@"article_url"];    
    [encoder encodeObject:[self.imageURL absoluteString] forKey:@"imageURL"];
    [encoder encodeBool:self.imageDownloaded forKey:@"imageDownloaded"];
    [encoder encodeBool:self.HTMLDownloaded forKey:@"HTMLDownloaded"];
}

#pragma mark - Image

- (void)setImage:(UIImage *)image {
    if (image == _image)
        return;
    
    _image = image;    
}

-(UIImage *)image {
    if (nil == _image && self.imageDownloaded) {
        NSData *imageData = [NSData dataWithContentsOfFile:self.imageFilePath];
        _image = [UIImage imageWithData:imageData];
    }
    
    return _image;
}

-(void)unloadImage {
    self.image = nil;
    self.decompressedImage = nil;
}

-(void)deleteImage {
    self.image = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self imageFilePath] error:nil];
    self.imageDownloaded = NO;
}

- (void)deleteHTML {
    [[NSFileManager defaultManager] removeItemAtPath:[self HTMLFilePath] error:nil];
    self.HTMLDownloaded = NO;
}

- (NSURLRequest *)HTMLURLRequest {
    if (!self.isHTMLDownloaded)
        return nil;
    
    return [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[self HTMLFilePath]]];
}

- (void)writeHTMLString:(NSString *)html completion:(void (^)(BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL suceess = [html writeToFile:[self HTMLFilePath] atomically:NO encoding:NSUTF8StringEncoding error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.HTMLDownloaded = YES;
            if (completion)
                completion(suceess);
        });
    });
}

- (void)writeImageData:(NSData *)data completion:(void (^)(BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL suceess = [data writeToFile:[self imageFilePath] atomically:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageDownloaded = YES;
            if (completion)
                completion(suceess);
        });
    });
}

-(NSString *)baseFilePath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
}

-(NSString *)HTMLFilePath {
    return [[self baseFilePath] stringByAppendingPathComponent:[@"story" stringByAppendingFormat:@"%@.html",self.storyID]];
}

-(NSString *)imageFilePath {
    return [[self baseFilePath] stringByAppendingPathComponent:[@"image" stringByAppendingFormat:@"%@.jpg",self.storyID]];
}

@end
