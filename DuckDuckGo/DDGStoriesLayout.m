//
//  DDGStoriesLayout.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//  Extended by Josiah Clumont from 21/04/16.
//

#import "DDGStoriesLayout.h"
#import "DDGStoriesViewController.h"

#pragma mark DDGStoriesLayout

NSString* const DDGStoriesLayoutKind = @"PhotoCell";
NSString* const DDGOnboardingBannerViewKindID = @"OnboardBanner";

@implementation DDGStoriesLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.mosaicMode = TRUE;
}

- (void)prepareLayout
{
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item = 0; item < itemCount; item++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            UICollectionViewLayoutAttributes* itemAttributes =
            [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            itemAttributes.frame = [self frameForStoryAtIndexPath:indexPath];
            
            cellLayoutInfo[indexPath] = itemAttributes;
        }
    }
    
    newLayoutInfo[DDGStoriesLayoutKind] = cellLayoutInfo;
    
    self.layoutInfo = newLayoutInfo;
}


CGFloat DDG_rowHeightWithContainerSize(CGSize size) {
    BOOL mosaicMode = size.width >= DDGStoriesMulticolumnWidthThreshold;
    CGFloat rowHeight;
    if(mosaicMode) { // set to the height of the larger story
        rowHeight = ((size.width - DDGStoriesBetweenItemsSpacing)*2/3) / DDGStoryImageWithoutTitleRatio + DDGTitleBarHeightMosaicLarge;
    } else { // set to the height
        rowHeight = size.width / DDGStoryImageRatio + DDGTitleBarHeight;
    }
    return MAX(10.0f, rowHeight); // a little safety
}

- (CGSize)collectionViewContentSize
{
    NSUInteger numStories = [self.collectionView numberOfItemsInSection:0];
    CGSize size = self.collectionView.frame.size;
    self.mosaicMode = size.width >= DDGStoriesMulticolumnWidthThreshold;
    NSUInteger cellsPerRow = self.mosaicMode ? 3 : 1;
    CGFloat rowHeight = DDG_rowHeightWithContainerSize(size) + DDGStoriesBetweenItemsSpacing;
    NSUInteger numRows = numStories/cellsPerRow;
    if(numStories%cellsPerRow!=0) numRows++;
    size.height = rowHeight * numRows + self.bannerHeight;
    return size;
}



- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray* elementAttributes = [NSMutableArray new];
    CGSize size = self.collectionView.frame.size;
    BOOL mosaicMode = size.width >= DDGStoriesMulticolumnWidthThreshold;
    NSUInteger bannerHeight = self.bannerHeight;
    CGFloat rowHeight = DDG_rowHeightWithContainerSize(size) + DDGStoriesBetweenItemsSpacing;
    
    if(rect.origin.y <= bannerHeight && bannerHeight>0) {
        // add attributes for the banner...
        UICollectionViewLayoutAttributes *bannerAttributes =
        [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:DDGOnboardingBannerViewKindID
                                                                       withIndexPath:[NSIndexPath indexPathForItem:0
                                                                                                         inSection:0]];
        bannerAttributes.frame = CGRectMake(0, 0, size.width, bannerHeight);
        [elementAttributes addObject:bannerAttributes];
    }
    
    NSUInteger cellsPerRow = mosaicMode ? 3 : 1;
    NSUInteger rowsBeforeRect = floor(rect.origin.y / rowHeight);
    NSUInteger rowsWithinRect = ceil((rect.origin.y+rect.size.height) / rowHeight) - rowsBeforeRect + 1;
    
    for(NSUInteger row = rowsBeforeRect; row < rowsBeforeRect + rowsWithinRect; row++) {
        for(NSUInteger column = 0 ; column < cellsPerRow; column++) {
            NSUInteger storyIndex = row * cellsPerRow + column;
            if(storyIndex >= [self.collectionView numberOfItemsInSection:0]) break;
            UICollectionViewLayoutAttributes* attributes = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:storyIndex inSection:0]];
            [elementAttributes addObject:attributes];
        }
    }
    return elementAttributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    itemAttributes.frame = [self frameForStoryAtIndexPath:indexPath];
    return itemAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return TRUE; // re-layout for all bounds changes
}

- (CGRect)frameForStoryAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.item;
    if(row==NSNotFound) return CGRectZero;
    row = row / (self.mosaicMode ? 3 : 1);
    NSInteger column = indexPath.item % (self.mosaicMode ? 3 : 1);
    CGSize frameSize = self.collectionView.frame.size;
    CGFloat rowHeight = DDG_rowHeightWithContainerSize(frameSize);
    CGFloat rowWidth = frameSize.width;
    BOOL oddRow = (row % 2) == 1;
    CGFloat cellY = self.bannerHeight + (row * (rowHeight + DDGStoriesBetweenItemsSpacing));
    CGRect storyRect = CGRectMake(0, cellY, rowWidth, rowHeight);
    if(self.mosaicMode) {
        if(oddRow) {
            if(column==0) { // top left of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
            } else if(column==1) { // bottom left of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
                storyRect.origin.y += rowHeight - storyRect.size.height;
            } else { // if(column==2) // the large right-side story
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)*2/3;
                storyRect.origin.x += rowWidth - storyRect.size.width;
            }
        } else { // even row
            if(column==1) { // top right of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
                storyRect.origin.x += rowWidth - storyRect.size.width;
            } else if(column==2) { // bottom right of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
                storyRect.origin.y += rowHeight - storyRect.size.height;
                storyRect.origin.x += rowWidth - storyRect.size.width;
            } else { // if(column==0) // the large left-side story
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)*2/3;
            }
        }
        storyRect.origin.y += DDGStoriesBetweenItemsSpacing;
    } else { // not a mosaic
        // the defaults are good enough
    }
    
    return storyRect;
}


@end
