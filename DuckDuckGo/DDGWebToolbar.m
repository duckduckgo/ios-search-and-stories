//
//  DDGWebToolbar.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 23/07/2015.
//
//

#import "DDGWebToolbar.h"

@interface DDGWebToolbar ()

@property DDGWebViewController* webController;

@end



@implementation DDGWebToolbar



-(id)initWithDDGWebController:(DDGWebViewController*)webController
                     andFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.webController = webController;
        self.backgroundColor = [UIColor duckTabBarBackground];
        self.tintColor = [UIColor duckTabBarForeground];
        
        self.backButton = [self setupToolbarButton:@"webbar-back"];
        self.forwardButton = [self setupToolbarButton:@"webbar-forward"];
        self.favButton = [self setupToolbarButton:@"webbar-fav"];
        self.shareButton = [self setupToolbarButton:@"webbar-share"];
        self.tabsButton = [self setupToolbarButton:@"webbar-tabs"];
        
        NSArray* buttons = @[ self.backButton, self.forwardButton, self.favButton, self.shareButton]; // self.tabsButton omitted
        
        CGFloat numButtons = buttons.count;
        CGFloat halfSpace = (0.5f/numButtons);
        for(int i=0; i<numButtons; i++) {
            [self addConstraint:[NSLayoutConstraint constraintWithItem:buttons[i]
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:(halfSpace*2)*i + halfSpace
                                                              constant:0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:buttons[i]
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                              constant:0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:buttons[i]
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:1
                                                              constant:0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:buttons[i]
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:1
                                                              constant:0]];
            [self addSubview:buttons[i]];
        }
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeTrailing
                                                        multiplier:1
                                                          constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:0]];
    }
    return self;
}

-(UIButton*)setupToolbarButton:(NSString*)imageName
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    button.tintColor = [UIColor duckTabBarForeground];
    return button;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
