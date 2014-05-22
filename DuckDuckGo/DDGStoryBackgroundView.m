//
//  DDGStoryBackgroundView.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/02/2014.
//
//

#import "DDGStoryBackgroundView.h"

#define DDGStoryBackgroundViewBackgroundColor [UIColor colorWithRed:0.247f green:0.267f blue:0.302f alpha:1.0f].CGColor

@implementation DDGStoryBackgroundView

- (void)reset
{
    self.backgroundImage = nil;
    self.blurRect = CGRectZero;
    self.blurredImage = nil;
}

#pragma mark -

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor duckNoContentColor].CGColor);
    CGContextFillRect(context, self.bounds);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    if (self.backgroundImage) {
        imageView.image = self.backgroundImage;
        [imageView.layer renderInContext:context];
    }
    
    if (self.blurredImage) {
        CGRect clipRect = self.blurRect;
        clipRect.origin.y += 3.5f;
        CGContextClipToRect(context, clipRect);
        imageView.image = self.blurredImage;
        [imageView.layer renderInContext:context];
    }
}

@end
