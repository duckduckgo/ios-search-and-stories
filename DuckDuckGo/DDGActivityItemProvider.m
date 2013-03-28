//
//  DDGActivityItemProvider.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 28/03/2013.
//
//

#import "DDGActivityItemProvider.h"

@interface DDGActivityItemProvider ()
@property (nonatomic, strong) NSMutableDictionary *activities;
@end

@implementation DDGActivityItemProvider

- (id)initWithPlaceholderItem:(id)placeholderItem
{
    self = [super initWithPlaceholderItem:placeholderItem];
    if (self) {
        self.activities = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)item {
    return self.placeholderItem;
}

- (void)setItem:(id)item forActivityType:(NSString *)activityType {
    NSAssert([item isKindOfClass:[self.placeholderItem class]], @"The item's class must match the placeholder item's class as specified in initWithPlaceholderItem:");
    [self.activities setObject:item forKey:activityType];
}

- (id)itemForActivityType:(NSString *)activityType {
    return [self.activities objectForKey:activityType];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    
    id item = [self itemForActivityType:activityType];
    if (nil != item) {
        if ([item isKindOfClass:[NSNull class]])
            return nil;
        return item;
    }
    
    return [super activityViewController:activityViewController itemForActivityType:activityType];
}

@end
