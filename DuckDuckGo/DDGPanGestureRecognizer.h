//
//  DDGPanLeftGestureRecognizer.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 25/02/2013.
//
//

#import <UIKit/UIKit.h>

typedef enum DDGPanGestureRecognizerDirection {
    DDGPanGestureRecognizerDirectionLeft=0,
    DDGPanGestureRecognizerDirectionRight
} DDGPanGestureRecognizerDirection;

@interface DDGPanGestureRecognizer : UIPanGestureRecognizer
@property (nonatomic) DDGPanGestureRecognizerDirection direction;
@end
