//
//  DDGSafariActivity.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 28/03/2013.
//
//

#import "DDGSafariActivity.h"

@implementation DDGSafariActivityItem
+ (id)safariActivityItemWithURL:(NSURL *)URL {
    DDGSafariActivityItem *item = [DDGSafariActivityItem new];
    item.URL = URL;
    return item;
}
@end

@implementation DDGSafariActivity
{
    DDGSafariActivityItem *_safariActivityItem;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[DDGSafariActivityItem class]] && [[UIApplication sharedApplication] canOpenURL:[activityItem URL]]) {
			return YES;
		}
	}
	
	return [super canPerformWithActivityItems:activityItems];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[DDGSafariActivityItem class]]) {
			_safariActivityItem = activityItem;
		}
	}
    
    [super prepareWithActivityItems:activityItems];        
}

- (void)performActivity
{
    if (nil != _safariActivityItem) {
        BOOL completed = [[UIApplication sharedApplication] openURL:_safariActivityItem.URL];
        [self activityDidFinish:completed];
    } else {
        [super performActivity];
    }
}


@end
