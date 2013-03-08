//
//  DDGStory.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGStory : NSObject <NSCoding> {
}

@property(nonatomic, strong) NSString *storyID;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) NSString *feed;
@property(nonatomic, strong) NSDate *date;

@property(nonatomic, strong) NSURL *imageURL;
@property(nonatomic, readonly, strong) UIImage *image;
@property(nonatomic, strong) UIImage *decompressedImage;
@property(nonatomic, readonly, getter = isImageDownloaded) BOOL imageDownloaded;
@property(nonatomic, readonly, getter = isHTMLDownloaded) BOOL HTMLDownloaded;

-(void)unloadImage;
-(void)deleteImage;

- (NSURLRequest *)HTMLURLRequest;

- (void)writeHTMLString:(NSString *)html completion:(void (^)(BOOL success))completion;
- (void)writeImageData:(NSData *)data completion:(void (^)(BOOL success))completion;

@end
