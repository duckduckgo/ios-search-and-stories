//
//  DDGReadabilityToggleActivity.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/03/2013.
//
//

#import "DDGReadabilityToggleActivity.h"
#import "DDGWebViewController.h"
#import "DDGStory.h"

@interface DDGReadabilityToggleActivity ()
@property (nonatomic, strong) NSArray *webViewControllers;
@end

@implementation DDGReadabilityToggleActivity

- (NSString *)activityType {
    return @"com.duckduckgo.readability-toggle";
}

- (NSString *)activityTitle {
    
    switch (self.toggleMode) {
        case DDGReadabilityToggleModeOn:
            return NSLocalizedString(@"Readability On", @"Activity title: switch on readability mode");
            break;
        case DDGReadabilityToggleModeOff:
        default:
            return NSLocalizedString(@"Readability Off", @"Activity title: switch off readability mode");
            break;
    }
    
    return nil;
}

- (UIImage *)activityImage {    
    switch (self.toggleMode) {
        case DDGReadabilityToggleModeOn:
            return [UIImage imageNamed:@"ui-activity_readability-on"];
            break;
        case DDGReadabilityToggleModeOff:
        default:
            return [UIImage imageNamed:@"ui-activity_readability-off"];
            break;
    }
    
    return nil;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id object in activityItems) {
        if ([object isKindOfClass:[DDGWebViewController class]]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[activityItems count]];
    for (id object in activityItems) {
        if ([object isKindOfClass:[DDGWebViewController class]]) {
            [items addObject:object];
        }
    }
    self.webViewControllers = items;
}

- (void)performActivity {
    
    for (DDGWebViewController *webViewController in self.webViewControllers) {
        DDGStory *story = webViewController.story;
        switch (self.toggleMode) {
            case DDGReadabilityToggleModeOn:
                [webViewController loadStory:story];
                break;
            case DDGReadabilityToggleModeOff:
            default:
                [webViewController loadQueryOrURL:story.url];
                break;
        }
    }
    
    [self activityDidFinish:YES];
}


@end
