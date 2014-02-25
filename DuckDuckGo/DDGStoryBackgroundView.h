//
//  DDGStoryBackgroundView.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/02/2014.
//
//

#import <UIKit/UIKit.h>

@interface DDGStoryBackgroundView : UIView

@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) CGRect blurRect;
@property (nonatomic, strong) UIImage *blurredImage;

- (void)reset;

@end
