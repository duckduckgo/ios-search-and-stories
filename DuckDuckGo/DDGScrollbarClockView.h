//
//  DDGScrollbarClockView.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/12/12.
//
//

#import <UIKit/UIKit.h>

@interface DDGScrollbarClockView : UIView {
    BOOL showing;
    NSDate *date;
    UILabel *label;
    NSDateFormatter *formatter;
}

-(void)show:(BOOL)show animated:(BOOL)animated;
-(void)updateDate:(NSDate *)newDate;

@end
