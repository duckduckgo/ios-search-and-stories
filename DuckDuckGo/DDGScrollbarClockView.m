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
        self.backgroundColor = [UIColor whiteColor];
        self.alpha = 0;
        
        label = [[UILabel alloc] initWithFrame:self.bounds];
        label.font = [UIFont systemFontOfSize:12];
        [self addSubview:label];
        
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MMM dd hh:mm a";
    }
    return self;
}

-(void)show:(BOOL)show animated:(BOOL)animated {
    if(show == showing)
        return;
    
    showing = show;
    [UIView animateWithDuration:(animated ? 0.25 : 0) animations:^{
        self.alpha = (show ? 1 : 0);
    }];
}

-(void)updateDate:(NSDate *)newDate {
    if(date == newDate)
        return;
    date = newDate;
    label.text = [formatter stringFromDate:date];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return NO;
}

@end
