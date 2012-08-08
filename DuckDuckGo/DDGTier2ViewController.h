//
//  DDGTier2ViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/6/12.
//
//

#import <UIKit/UIKit.h>

@interface DDGTier2ViewController : UITableViewController {
    NSArray *news;
}
@property(nonatomic, copy) NSDictionary *suggestionItem;

-(id)initWithSuggestionItem:(NSDictionary *)aSuggestionItem;

@end
