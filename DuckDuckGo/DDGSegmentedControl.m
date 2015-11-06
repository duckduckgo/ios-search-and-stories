//
//  DDGSegmentedControl.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 28/08/2015.
//
//

#import "DDGSegmentedControl.h"


@interface DDGSegmentedControl () {
    NSInteger _selectedSegmentIndex;
    UIColor* _foregroundColor;
}

@property (nonatomic) UIView* selectedView;
@property (nonatomic, strong) NSMutableArray* buttonItems;
@property (nonatomic, strong) NSMutableArray* buttons;

@end


@implementation DDGSegmentedControl

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self configure];
    }
    return self;
}


-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        [self configure];
    }
    return self;
}

-(void)configure
{
    self.layer.cornerRadius = 4.0f;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 1.0f;
    self.selectedView = [[UIView alloc] init];
    self.selectedView.layer.cornerRadius = 4.0f;
    self.selectedView.backgroundColor = [UIColor duckSegmentedForeground];
    self.buttonItems = [NSMutableArray new];
    self.buttons = [NSMutableArray new];
    self.selectedSegmentIndex = 0;
    
    self.foregroundColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor duckSearchBarBackground];
    [self addSubview:self.selectedView];
    [self setNeedsLayout];

}

- (void)addSegment:(UIBarButtonItem*)buttonItem
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setTitle:buttonItem.title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor duckSegmentedForeground] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor duckSegmentedBackground] forState:UIControlStateSelected];
    button.titleLabel.font = [UIFont duckFontWithSize:14.0f];
    [button addTarget:self action:@selector(buttonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.buttons addObject:button];
    [self.buttonItems addObject:buttonItem];
    [self addSubview:button];
    [self updateSelectedButton];
    [self setNeedsLayout];
}

-(void)layoutSubviews
{
    CGRect f = self.frame;
    f.origin = CGPointMake(0,0);
    CGFloat itemWidth = f.size.width/self.buttonItems.count;
    f.size.width = itemWidth;
    for(UIButton* button in self.buttons) {
        button.frame = f;
        f.origin.x += itemWidth;
    }
    NSInteger idx = self.selectedSegmentIndex;
    if(idx >= 0 && idx < self.buttons.count) {
        self.selectedView.frame = ((UIButton*)self.buttons[idx]).frame;
    }
    [super layoutSubviews];
}

-(NSInteger)selectedSegmentIndex {
    return _selectedSegmentIndex;
}


-(UIColor*)foregroundColor
{
    return _foregroundColor;
}

-(void)setForegroundColor:(UIColor *)foregroundColor
{
    _foregroundColor = foregroundColor;
    self.selectedView.backgroundColor = foregroundColor;
    self.layer.borderColor = foregroundColor.CGColor;
    [self updateSelectedButton];
}

-(void)updateSelectedButton
{
    NSInteger idx = 0, selIdx = self.selectedSegmentIndex;
    for(UIButton* button in self.buttons) {
        button.selected = idx==selIdx;
        idx++;
    }
    [self setNeedsDisplay];
}

- (void)layoutIfNeeded:(NSTimeInterval)animationDuration {
    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
}

-(void)setSelectedSegmentIndex:(NSInteger)itemIndex
{
    [self setSelectedSegmentIndex:itemIndex animate:FALSE];
}

-(void)setSelectedSegmentIndex:(NSInteger)itemIndex animate:(BOOL)animate
{
    if(itemIndex < 0 || itemIndex >= self.buttonItems.count || itemIndex==_selectedSegmentIndex) return;
    
    _selectedSegmentIndex = itemIndex;
    [self updateSelectedButton];
    [self setNeedsLayout];
    [self layoutIfNeeded:animate ? 0.1 : 0.0];

    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

-(void)buttonWasPressed:(id)sender
{
    NSInteger idx = 0;
    for(id button in self.buttons) {
        if(button==sender) {
            [self setSelectedSegmentIndex:idx animate:TRUE];
            return;
        }
        idx++;
    }
}

-(void)dealloc
{
    [self.buttonItems removeAllObjects];
    [self.buttons removeAllObjects];
}

@end
