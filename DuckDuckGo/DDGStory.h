//
//  DDGStory.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGStory : NSObject <NSCoding> {
    UIImage *_image;
    BOOL imageDownloaded;
}

@property(strong) NSString *storyID;
@property(strong) NSString *title;
@property(strong) NSString *url;
@property(strong) NSString *feed;
@property(strong) NSDate *date;

@property(strong) NSString *imageURL;
@property(readonly) UIImage *image;

-(void)downloadImageFinished:(void (^)())finished;
-(void)prefetchAndDecompressImage;
-(void)unloadImage;
-(void)deleteImage;
-(void)loadImageIntoView:(UIImageView *)imageView;

@end
