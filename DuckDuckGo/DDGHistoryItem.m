#import "DDGHistoryItem.h"
#import "DDGStory.h"

@implementation DDGHistoryItem

- (NSString *)section {
    if (nil != self.story)
        return @"stories";
    return @"searches";
}

@end
