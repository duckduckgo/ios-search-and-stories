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

@end

@implementation DDGMenuSectionHeaderView

- (void)setTitle:(NSString *)title
{
    _title = [[title uppercaseString] copy];
    [self.titleLabel setText:_title];
}

@end
