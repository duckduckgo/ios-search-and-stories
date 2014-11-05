//
//  TestTableView.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 05/11/2014.
//
//

#import "TestTableView.h"
#import "UIScrollView+DDG.h"

@implementation TestTableView

- (void)setContentOffset:(CGPoint)contentOffset {
    if (self.isIgnoringOffset && contentOffset.y == self.offsetToIgnore) {
        return;
    }
    [super setContentOffset:contentOffset];
}

//- (void)_adjustContentOffsetIfNecessary {
//    
//}

@end
