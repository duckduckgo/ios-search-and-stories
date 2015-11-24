//
//  DDGSegmentedControl.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 28/08/2015.
//
//

#import <UIKit/UIKit.h>

@interface DDGSegmentedControl : UIControl

@property (nonatomic) NSInteger selectedSegmentIndex;
@property (nonatomic) UIColor* foregroundColor;

-(id)initWithFrame:(CGRect)frame;

-(void)addSegment:(UIBarButtonItem*)buttonItem;

@end
