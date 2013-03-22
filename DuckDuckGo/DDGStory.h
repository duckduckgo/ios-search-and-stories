//
//  DDGStory.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/10/12.
//
//

#import "_DDGStory.h"

@interface DDGStory : _DDGStory {
}

//@property(nonatomic, strong) NSString *storyID;
//@property(nonatomic, strong) NSString *title;
//@property(nonatomic, strong) NSString *url;
//@property(nonatomic, strong) NSString *article_url;
//@property(nonatomic, strong) NSString *feed;
//@property(nonatomic, strong) NSDate *date;

@property(nonatomic, strong) NSURL *URL;
@property(nonatomic, strong) NSURL *imageURL;
@property(nonatomic, readonly) UIImage *image;
@property(nonatomic, readonly) BOOL isImageDownloaded;
@property(nonatomic, readonly) BOOL isHTMLDownloaded;

- (void)deleteImage;
- (void)deleteHTML;

- (NSString *)HTML;
- (NSURLRequest *)HTMLURLRequest;

- (void)writeHTMLString:(NSString *)html completion:(void (^)(BOOL success))completion;
- (void)writeImageData:(NSData *)data completion:(void (^)(BOOL success))completion;

@end
