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
    }
}


-(void)setup
{
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
    
    CALayer *layer = self.layer;
    layer.cornerRadius = 4.0f;
    layer.masksToBounds = NO;
}

-(void)hidePlaceholder {
    self.placeholderView.hidden = TRUE;
    self.attributedPlaceholder = self.actualPlaceholderText;
}

-(void)showPlaceholder {
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
