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


-(void)updatePlaceholder {
    [self updatePlaceholderAnimated:TRUE];
}

-(void)updateConstraints {
    [super updateConstraints];
    BOOL fieldIsActive = self.isFirstResponder;
    if([self.placeholderTextCenter respondsToSelector:@selector(setActive:)]) {
        // iOS8+ - the right way
        self.placeholderTextLeft.active = fieldIsActive;
        self.placeholderTextCenter.active = !fieldIsActive;
    } else {
        // iOS7 - the workaround way
        if(fieldIsActive) {
            [self.superview removeConstraint:self.placeholderTextCenter];
            [self.superview addConstraint:self.placeholderTextLeft];
        } else {
            [self.superview removeConstraint:self.placeholderTextLeft];
            [self.superview addConstraint:self.placeholderTextCenter];
        }
    }
}

-(void)updatePlaceholderAnimated:(BOOL)animated {
    NSString* text = self.text;
    BOOL fieldIsActive = self.isFirstResponder;
    BOOL emptyText = text.length <= 0;
    
    // if the text is non-empty then hide the placeholder immediately
    if(!emptyText) {
        self.placeholderView.alpha = 0.0f;
    }
    
    void(^animator)() = ^() {
        // position the placeholder
        if([self.placeholderTextCenter respondsToSelector:@selector(setActive:)]) {
            // iOS8+ - the right way
            self.placeholderTextLeft.active = fieldIsActive;
            self.placeholderTextCenter.active = !fieldIsActive;
        } else {
            // iOS7 - the workaround way
            if(fieldIsActive) {
                [self.superview removeConstraint:self.placeholderTextCenter];
                [self.superview addConstraint:self.placeholderTextLeft];
            } else {
                [self.superview removeConstraint:self.placeholderTextLeft];
                [self.superview addConstraint:self.placeholderTextCenter];
            }
        }
        
        // fade the loupe icon in or out
        self.placeholderIconView.alpha = fieldIsActive ? 0 : 1.0f;
        
        // if the text is empty, then let's fade in the placeholder
        if(emptyText) {
            self.placeholderView.alpha = 1.0f;
        }
        
        [self.placeholderView layoutIfNeeded];
    };
    
    if(animated) {
        [UIView animateWithDuration:0.2f animations:animator];
    } else {
        animator();
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"text"]) {
        [self updatePlaceholderAnimated:TRUE];
        //        id newText = [change valueForKey:@"new"];
//        if(newText!=nil && [newText length]>0) {
//            [self hidePlaceholder];
//        }
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
    
    [self addObserver:self
           forKeyPath:@"text"
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    [self addTarget:self action:@selector(updatePlaceholder) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(updatePlaceholder) forControlEvents:UIControlEventEditingDidEnd];
    [self addTarget:self action:@selector(updatePlaceholder) forControlEvents:UIControlEventEditingChanged];
    
    self.backgroundColor = [UIColor duckSearchFieldBackground];
    self.textColor = [UIColor duckSearchFieldForeground];
    self.tintColor = [UIColor duckSearchFieldForeground];
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    
    [self.clearButton addTarget:self action:@selector(clear:) forControlEvents:UIControlEventTouchUpInside];
    
    CALayer *layer = self.layer;
    layer.cornerRadius = 4.0f;
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
    [self updatePlaceholder];
}


-(IBAction)clear:(id)sender {
    self.text = @"";
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

#pragma mark - Safe Update Text 
- (void)safeUpdateText:(NSString*)textToUpdate {
    self.text = @"";
    [self updatePlaceholderAnimated:false];
    self.text = textToUpdate;
}

@end
