//
//  DDGScrollbarClockView.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/12/12.
//
//

#import "DDGScrollbarClockView.h"

@implementation DDGScrollbarClockView

- (id)init {
    self = [super initWithFrame:CGRectMake(0, 0, 100, 34)];
    if (self) {
        self.backgroundColor = [UIColor redColor];
        self.alpha = 0.5;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
