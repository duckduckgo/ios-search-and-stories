//
//  DDGMenuSectionHeaderView.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 27/03/2014.
//
//

#import "DDGMenuSectionHeaderView.h"

@interface DDGMenuSectionHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@end

@implementation DDGMenuSectionHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.containerView setBackgroundColor:[UIColor clearColor]];
    [self.containerView setHidden:YES];
    [self.containerView setOpaque:NO];
    [self.titleLabel setTextColor:[UIColor duckGray]];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.containerView addGestureRecognizer:tapGestureRecognizer];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    if (self.closeBlock && ![self.containerView isHidden]) {
        CGPoint tapLocation = [recognizer locationInView:self];
        if (CGRectContainsPoint([self.containerView frame], tapLocation)) {
            self.closeBlock();
        }
    }
}

- (void)setCloseBlock:(DDGMenuSectionHeaderCloseBlock)closeBlock
{
    _closeBlock = [closeBlock copy];
    [self.containerView setHidden:NO];
}

- (void)setTitle:(NSString *)title
{
    _title = [[title uppercaseString] copy];
    [self.titleLabel setText:_title];
}

@end
