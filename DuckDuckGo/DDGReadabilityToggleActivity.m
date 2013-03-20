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
    return NSLocalizedString(@"Readability Off", @"Activity title: switch off readability mode");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"ui-activity_readability-off"];
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
        webViewController.story = nil;
        [webViewController loadQueryOrURL:story.url];
    }
    
    [self activityDidFinish:YES];
}


@end
