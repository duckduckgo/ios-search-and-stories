//
//  DDGProgressBarTextField.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 5/13/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAddressBarTextField.h"
#import <QuartzCore/QuartzCore.h>

@interface DDGAddressBarTextField ()
@property NSAttributedString* actualPlaceholderText;
@property NSAttributedString* inactivePlaceholderText;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *placeholderTextLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *placeholderTextCenter;
@property (strong, nonatomic) IBOutlet UIImageView *placeholderIconView;

@end

@implementation DDGAddressBarTextField

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self setup];
    }
    return self;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"text"]) {
        id newText = [change valueForKey:@"new"];
        if(newText!=nil && [newText length]>0) {
            [self hidePlaceholder];
        }
        [self textWasUpdated:nil];
    }
}


-(void)textWasUpdated:(id)source {
    NSString* newText = self.text;
    if(newText!=nil && [newText length]>0) {
        self.clearButton.hidden = FALSE;
    } else {
        self.clearButton.hidden = TRUE;
    }
}

-(void)setup
{
    self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.stopButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
    self.stopButton.frame = CGRectMake(0,0,27,23);
    
    self.reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.reloadButton setImage:[UIImage imageNamed:@"refresh.png"] forState:UIControlStateNormal];
    self.reloadButton.frame = CGRectMake(0,0,27,23);
    
    self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.clearButton setImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal];
    self.clearButton.frame = CGRectMake(0,0,27,23);
    
    [self addTarget:self action:@selector(textWasUpdated:) forControlEvents:UIControlEventEditingChanged];
    
    self.actualPlaceholderText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"SearchPlaceholder", nil)
                                                                 attributes:@{NSForegroundColorAttributeName: [UIColor duckSearchFieldPlaceholderForeground]}];
    self.inactivePlaceholderText = [[NSAttributedString alloc] initWithString:@" " attributes:@{}];
    self.attributedPlaceholder = self.inactivePlaceholderText; // need to set to a non-empty string in order to prevent it sliding in from {0,0} when made visible
    [self addObserver:self
           forKeyPath:@"text"
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    [self addTarget:self action:@selector(hidePlaceholder) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(showPlaceholder) forControlEvents:UIControlEventEditingDidEnd];
    
    self.backgroundColor = [UIColor duckSearchFieldBackground];
    self.textColor = [UIColor duckSearchFieldForeground];
    self.tintColor = [UIColor duckSearchFieldForeground];
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    
    [self.clearButton addTarget:self action:@selector(clear:) forControlEvents:UIControlEventTouchUpInside];
    
    CALayer *layer = self.layer;
    layer.cornerRadius = 4.0f;
    layer.masksToBounds = NO;
}

-(void)setRightButtonMode:(DDGAddressBarRightButtonMode)newMode {
    switch (newMode) {
        case DDGAddressBarRightButtonModeDefault:
            self.rightView = self.clearButton;
            self.rightViewMode = UITextFieldViewModeWhileEditing;
            break;
        case DDGAddressBarRightButtonModeRefresh:
            self.rightView = self.reloadButton;
            self.rightViewMode = UITextFieldViewModeAlways;
            break;
        case DDGAddressBarRightButtonModeStop:
            self.rightView = self.stopButton;
            self.rightViewMode = UITextFieldViewModeAlways;
            break;
        case DDGAddressBarRightButtonModeNone:
            self.rightView = self.reloadButton;
            self.rightViewMode = UITextFieldViewModeNever;
            break;
    }
}

-(void)resetField
{
    [self clear:nil];
    [self showPlaceholder];
}


-(IBAction)clear:(id)sender {
    self.text = @"";
}

-(void)hidePlaceholder {
    [UIView animateWithDuration:0.2 animations:^{
        self.placeholderTextLeft.active = TRUE;
        self.placeholderTextCenter.active = FALSE;
        self.placeholderIconView.alpha = 0;
        [self.placeholderView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.attributedPlaceholder = self.actualPlaceholderText;
        self.placeholderView.hidden = TRUE;
    }];
}

-(void)showPlaceholder {
    [UIView animateWithDuration:0.2 animations:^{
        self.placeholderTextLeft.active = FALSE;
        self.placeholderTextCenter.active = TRUE;
        self.placeholderIconView.alpha = 1;
        [self.placeholderView layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
    
    NSString* text = self.text;
    self.placeholderView.hidden = !(text==nil || text.length<=0);
    self.attributedPlaceholder = self.inactivePlaceholderText;
}



// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect rect = [super textRectForBounds:bounds];
    if(self.additionalLeftSideInset!=0) rect.origin.x = self.additionalLeftSideInset;
    rect.size.width -= self.additionalLeftSideInset;
    rect.size.width -= self.additionalRightSideInset;
    return rect;
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect rect = [super editingRectForBounds:bounds];
    if(self.additionalLeftSideInset!=0) rect.origin.x = self.additionalLeftSideInset;
    rect.size.width -= self.additionalLeftSideInset;
    rect.size.width -= self.additionalRightSideInset;
    return rect;
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"text"];
}

@end
