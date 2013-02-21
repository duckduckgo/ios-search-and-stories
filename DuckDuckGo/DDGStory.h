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
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) UIImage *decompressedImage;
@property(nonatomic, getter = isImageDownloaded) BOOL imageDownloaded;

-(void)unloadImage;
-(void)deleteImage;

@end
