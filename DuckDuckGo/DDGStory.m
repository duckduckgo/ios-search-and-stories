//
//  DDGStory.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import "DDGStory.h"

@implementation DDGStory

// make a serial background queue for last-minute image loading because we need to make sure images are loaded in the order they are requested.
// (otherwise an old load request could overwrite the image from the newer, correct one)
static dispatch_queue_t imageLoadingQueue;

#pragma mark - NSCoding

-(id)init {
    self = [super init];
    if(self) {
        @synchronized(@"DDGStoryImageLoadingQueue") {
            if(!imageLoadingQueue)
                imageLoadingQueue = dispatch_queue_create("DDGStoryImageLoadingQueue", NULL);
        }
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        self.storyID = [aDecoder decodeObjectForKey:@"storyID"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.feed = [aDecoder decodeObjectForKey:@"feed"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
        self.imageURL = [aDecoder decodeObjectForKey:@"imageURL"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.storyID forKey:@"storyID"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.feed forKey:@"feed"];
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:self.imageURL forKey:@"imageURL"];
}

#pragma mark - Image

-(void)downloadImageFinished:(void (^)())finished {
    @synchronized(self) {
        if(self.image)
            return;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:_imageURL]];
            [imageData writeToFile:self.imageFilePath atomically:YES];
            _image = [UIImage imageWithData:imageData];
            [self prefetchAndDecompressImage];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(finished)
                    finished();
            });
        });
    }
}

-(UIImage *)image {
    @synchronized(self) {
        if(!_image) {
            NSData *imageData = [NSData dataWithContentsOfFile:self.imageFilePath];
            _image = [UIImage imageWithData:imageData];
        }
        return _image;
    }
}

-(void)prefetchAndDecompressImage {
    @synchronized(self) {
        UIImage *image = self.image;
        
        UIGraphicsBeginImageContext(image.size);
        [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
        UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        _image = decompressed;
    }
}

-(void)unloadImage {
    @synchronized(self) {
        _image = nil;
    }
}

-(void)deleteImage {
    @synchronized(self) {
        [[NSFileManager defaultManager] removeItemAtPath:self.imageFilePath error:nil];
    }
}

-(void)loadImageIntoView:(UIImageView *)imageView {
    @synchronized(self) {
        if(_image) {
            imageView.image = _image;
        } else {
            imageView.image = nil;
            dispatch_async(imageLoadingQueue, ^{
                [self prefetchAndDecompressImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = self.image;
                });
            });
        }
    }
}

-(NSString *)imageFilePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[@"image" stringByAppendingFormat:@"%@.jpg",self.storyID]];
}

@end
