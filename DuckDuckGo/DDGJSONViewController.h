//
//  DDGJSONViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/13/12.
//
//

#import <UIKit/UIKit.h>

@interface DDGJSONViewController : UITableViewController {
    NSArray *json;
}
@property(nonatomic,strong) NSURL *jsonURL;

@end
