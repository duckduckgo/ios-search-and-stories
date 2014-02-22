//
//  UIWebView+ContextMenuDDG.h
//  DuckDuckGo
//
//  Created by Anh Quang Do on 2/22/14.
//


#import <Foundation/Foundation.h>

@interface UIWebView (ContextMenuDDG)

- (void)injectJavaScriptIfNecessary;
- (void)findElementAtPoint:(CGPoint)point;
- (NSString *)contextMenuImageURLString;
@end