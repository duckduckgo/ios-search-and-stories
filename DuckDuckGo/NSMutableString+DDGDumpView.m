//
//  NSMutableString+DDGDumpView.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 11/30/12.
//
//

#import "NSMutableString+DDGDumpView.h"

@implementation NSMutableString (DDGDumpView)

// utilitarian view hierarchy
- (void) dumpView:(UIView *)aView atIndent:(int)indent
{
    for (int i = 0; i < indent; i++)
		[self appendString:@"--"];
	NSString *tag = (aView.tag == 0) ? @"" : [NSString stringWithFormat:@" (%ld)", (long)aView.tag];
	
    [self appendFormat:@"[%2d] %@%@ -- F:(%.f, %.f, %.f, %.f), B:(%.f, %.f, %.f, %.f), visible=%@\n",
	 indent, [[aView class] description], tag,
	 aView.frame.origin.x, aView.frame.origin.y, aView.frame.size.width, aView.frame.size.height,
	 aView.bounds.origin.x, aView.bounds.origin.y, aView.bounds.size.width, aView.bounds.size.height,
	 aView.hidden ? @"N" : @"Y"];
	
    for (UIView *view in [aView subviews])
        [self dumpView:view atIndent:indent + 1];
}

@end

