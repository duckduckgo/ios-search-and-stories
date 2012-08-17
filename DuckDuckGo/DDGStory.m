//
//  DDGStory.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import "DDGStory.h"
#import "NSOperationStack.h"

@implementation DDGStory
static NSMutableDictionary *loadingImageViews;
static NSOperationQueue *imageLoadingStack;

#pragma mark - NSCoding

-(id)init {
    self = [super init];
    if(self) {
        @synchronized(@"DDGStoryLoadingImageViews") {
            if(!loadingImageViews)
                loadingImageViews = [[NSMutableDictionary alloc] init];
            if(!imageLoadingStack) {
                imageLoadingStack = [[NSOperationQueue alloc] init];
                imageLoadingStack.maxConcurrentOperationCount = 2;
            }
        }
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if(self) {
        self.storyID = [aDecoder decodeObjectForKey:@"storyID"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.feed = [aDecoder decodeObjectForKey:@"feed"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
        self.imageURL = [aDecoder decodeObjectForKey:@"imageURL"];
        imageDownloaded = [aDecoder decodeBoolForKey:@"imageDownloaded"];
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
    [encoder encodeBool:imageDownloaded forKey:@"imageDownloaded"];
}

#pragma mark - Image

-(BOOL)downloadImage {
    @synchronized(self) {
        if(imageDownloaded)
            return NO;
    }
    
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:_imageURL]];
    [imageData writeToFile:self.imageFilePath atomically:YES];
    imageDownloaded = YES;
    @synchronized(self) {
        _image = [UIImage imageWithData:imageData];
    }
    [self prefetchAndDecompressImage];
    
    return YES;
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
    UIImage *image = self.image;
    
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
    UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    @synchronized(self) {
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
        [[[NSFileManager alloc] init] removeItemAtPath:self.imageFilePath error:nil];
        imageDownloaded = NO;
    }
}

-(void)loadImageIntoView:(UIImageView *)imageView {
    @synchronized(self) {
        @synchronized(loadingImageViews) {
            [loadingImageViews setObject:self forKey:[NSValue valueWithNonretainedObject:imageView]];
        }
        
        
        if(_image) {
            imageView.image = _image;
        } else {
            imageView.image = nil;
            
            [imageLoadingStack addOperationAtFrontOfQueueWithBlock:^{
                @synchronized(loadingImageViews) {
                    if([loadingImageViews objectForKey:[NSValue valueWithNonretainedObject:imageView]] != self)
                        return;
                }
                
                [self prefetchAndDecompressImage];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(loadingImageViews) {
                        if([loadingImageViews objectForKey:[NSValue valueWithNonretainedObject:imageView]] == self) {
                            imageView.image = self.image;
                            [loadingImageViews removeObjectForKey:[NSValue valueWithNonretainedObject:imageView]];
                        }
                    }
                });
            }];
        }
    }
}

-(NSString *)imageFilePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[@"image" stringByAppendingFormat:@"%@.jpg",self.storyID]];
}

@end
