//
//  DDGActivityItemProvider.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 28/03/2013.
//
//

#import <UIKit/UIKit.h>

@interface DDGActivityItemProvider : UIActivityItemProvider

- (void)setItem:(id)item forActivityType:(NSString *)activityType;
- (id)itemForActivityType:(NSString *)activityType;

@end
