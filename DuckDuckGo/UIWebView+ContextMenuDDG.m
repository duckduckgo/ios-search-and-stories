//
//  UIWebView+ContextMenuDDG.m
//  DuckDuckGo
//
//  Created by Anh Quang Do on 2/22/14.
//


#import "UIWebView+ContextMenuDDG.h"


@implementation UIWebView (ContextMenuDDG)

- (void)injectJavaScriptIfNecessary
{
    if (![[self stringByEvaluatingJavaScriptFromString:@"ddg_injected == true"] isEqualToString:@"true"]) {
        NSError *error = nil;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"contextmenu" ofType:@"js"];
        NSString *js = [[NSString alloc] initWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];

        [self stringByEvaluatingJavaScriptFromString:js];
    }
}

- (void)findElementAtPoint:(CGPoint)point {
    NSString *js = [NSString stringWithFormat:@"ddg_findElementAtPoint(%i, %i)", (NSInteger)point.x, (NSInteger)point.y];
    [self stringByEvaluatingJavaScriptFromString:js];
}

- (NSString *)contextMenuImageURLString {
    return [self stringByEvaluatingJavaScriptFromString:@"ddg_imageURL"];
}

@end