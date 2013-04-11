#import "DDGHistoryItem.h"
#import "DDGStory.h"

@implementation DDGHistoryItem

- (NSString *)section {
    if (nil != self.story)
        return @"stories";
    return @"searches";
}

- (void)willSave {
    [super willSave];
    
    BOOL oldValue = self.isStoryItemValue;
    BOOL isStoryItemValue = (nil != self.story);
    
    if (isStoryItemValue != oldValue)
        self.isStoryItemValue = isStoryItemValue;
}

@end
