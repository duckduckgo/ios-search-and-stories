//
//  NSMutableString+DDGDumpView.h
//  DuckDuckGo
//
//  Created by Chris Heimark on 11/30/12.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableString (DDGDumpView)

- (void) dumpView: (UIView *) aView atIndent:(int)indent;

@end

