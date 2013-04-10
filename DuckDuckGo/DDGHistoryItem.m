#import "DDGHistoryItem.h"
#import "DDGStory.h"

@implementation DDGHistoryItem

- (NSNumber *)section {
    if (nil != self.story)
        return @(1);
    return @(0);
}

@end
