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
#import "DDGWebKitWebViewController.h"
#import "Constants.h"

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
            return NSLocalizedString(@"Enable Readability", @"Activity title: switch on readability mode");
            break;
        case DDGReadabilityToggleModeOff:
        default:
            return NSLocalizedString(@"Disable Readability", @"Activity title: switch off readability mode");
            break;
    }
    
    return nil;
}

- (UIImage *)activityImage {    
    switch (self.toggleMode) {
        case DDGReadabilityToggleModeOn:
            return [UIImage imageNamed:@"ReadabilityOn"];
            break;
        case DDGReadabilityToggleModeOff:
        default:
            return [UIImage imageNamed:@"ReadabilityOff"];
            break;
    }
    
    return nil;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id object in activityItems) {
        if ([self objectIsKindOfWebView:object]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[activityItems count]];
    for (id object in activityItems) {
        if ([self objectIsKindOfWebView:object]) {
            [items addObject:object];
        }
    }
    self.webViewControllers = items;
}

- (void)performActivity {
    for (id webViewController in self.webViewControllers) {
        // There's no type checking here....
        switch (self.toggleMode) {
            case DDGReadabilityToggleModeOn:
                if ([webViewController canSwitchToReadabilityMode])
                    [webViewController switchReadabilityMode:YES];
                break;
            case DDGReadabilityToggleModeOff:
            default:
                [webViewController switchReadabilityMode:NO];
                break;
        }
    }
    
    [self activityDidFinish:YES];
}

- (BOOL)objectIsKindOfWebView:(id)object {
    if ([object isKindOfClass:[DDGWebViewController class]] || [object isKindOfClass:[DDGWebKitWebViewController class]]) {
        return YES;
    }
    return NO;
}


@end
