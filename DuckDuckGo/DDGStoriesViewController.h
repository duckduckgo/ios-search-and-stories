//
//  DDGStoriesViewController.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "DDGSearchHandler.h"
#import "DDGSearchController.h"
#import "DDGStoryCell.h"


#define DDGStoriesInterRowSpacing 10
#define DDGStoriesBetweenItemsSpacing 10
#define DDGStoriesMulticolumnWidthThreshold 500
#define DDGStoryImageRatio 2.083333333
// aka 1/0.48f

#define DDGStoryImageWithoutTitleRatio 2.0f
#define DDGStoryImageRatioMosaic 1.356f



CGFloat DDG_rowHeightWithContainerSize(CGSize containerSize);

typedef enum : NSUInteger {
    DDGStoriesListModeNormal,
    DDGStoriesListModeFavorites,
    DDGStoriesListModeRecents,
} DDGStoriesListMode;

@interface DDGStoriesViewController : UIViewController <DDGStoryCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, NSFetchedResultsControllerDelegate>
{}

@property (nonatomic, readonly, weak) id <DDGSearchHandler> searchHandler;
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) DDGStoriesListMode storiesMode;
@property (nonatomic, strong) UIImage *searchControllerBackButtonIconDDG;
@property BOOL showsOnboarding;

- (id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
