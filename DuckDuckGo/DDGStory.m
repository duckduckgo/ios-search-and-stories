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
        self.imageURL = [NSURL URLWithString:[aDecoder decodeObjectForKey:@"imageURL"]];
        self.imageDownloaded = [aDecoder decodeBoolForKey:@"imageDownloaded"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.storyID forKey:@"storyID"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.feed forKey:@"feed"];
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:[self.imageURL absoluteString] forKey:@"imageURL"];
    [encoder encodeBool:self.imageDownloaded forKey:@"imageDownloaded"];
}

#pragma mark - Image

- (void)setImage:(UIImage *)image {
    if (image == _image)
        return;
    
    _image = image;
    
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:[self imageFilePath] atomically:NO];
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
    [[NSFileManager defaultManager] removeItemAtPath:self.imageFilePath error:nil];
    self.imageDownloaded = NO;
}

-(NSString *)imageFilePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[@"image" stringByAppendingFormat:@"%@.jpg",self.storyID]];
}

@end
