//
//  DDGProgressBar.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 07/07/2015.
//
//

#import <UIKit/UIKit.h>

@interface DDGProgressBar : UIView

@property (assign) NSUInteger percentCompleted;
@property (strong) UIColor* noncompletedForeground;
@property (strong) UIColor* completedForeground;

-(void)setPercentCompleted:(NSUInteger)percentCompleted animated:(BOOL)animated;

@end
