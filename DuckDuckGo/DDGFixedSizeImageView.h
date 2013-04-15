//
//  DDGFixedSizeImageView.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/04/2013.
//
//

#import <UIKit/UIKit.h>


@interface DDGFixedSizeImageView : UIView
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic) CGSize size;
@property(nonatomic, getter=isHighlighted) BOOL highlighted;
@end
