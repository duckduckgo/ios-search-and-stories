//
//  DDGFixedSizeImageView.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/04/2013.
//
//

#import "DDGFixedSizeImageView.h"

@implementation DDGFixedSizeImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.size = self.bounds.size;
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted == _highlighted)
        return;
    
    _highlighted = highlighted;
    [self setNeedsDisplay];
}

- (void)setImage:(UIImage *)image {
    if (image == _image)
        return;
    
    _image = image;
    [self setNeedsDisplay];
}

- (void)setHighlightedImage:(UIImage *)highlightedImage {
    if (highlightedImage == _highlightedImage)
        return;
    
    _highlightedImage = highlightedImage;
    [self setNeedsDisplay];
}

- (void)setSize:(CGSize)size {
    if (CGSizeEqualToSize(size, _size))
        return;
    
    _size = size;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGRect bounds = self.bounds;
    CGSize size = self.size;
    
    CGRect drawingRect = CGRectMake(bounds.origin.x + floor((bounds.size.width - size.width) / 2.0),
                                    bounds.origin.y + floor((bounds.size.height - size.height) / 2.0),
                                    size.width,
                                    size.height);
    
    UIImage *image = (self.isHighlighted && self.highlightedImage) ? self.highlightedImage : self.image;
    [image drawInRect:drawingRect];
}

@end
