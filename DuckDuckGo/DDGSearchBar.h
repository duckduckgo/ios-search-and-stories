//
//  DDGSearchBar.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 04/04/2013.
//
//

#import <UIKit/UIKit.h>
#import "DDGAddressBarTextField.h"
#import "DDGProgressBar.h"

@class DDGAddressBarTextField;
@interface DDGSearchBar : UIView
@property(nonatomic) BOOL showsCancelButton;
@property(nonatomic) BOOL showsLeftButton;
@property(nonatomic) BOOL showsBangButton;
@property(nonatomic) CGFloat buttonSpacing;
@property(nonatomic, strong) IBOutlet UIButton *bangButton;
@property(nonatomic, strong) IBOutlet UIButton *orangeButton;
@property(nonatomic, weak) IBOutlet UIButton *leftButton;
@property(nonatomic, weak) IBOutlet UIButton *cancelButton;
@property(nonatomic, weak) IBOutlet DDGAddressBarTextField *searchField;
@property(strong, nonatomic) IBOutlet DDGProgressBar *progressView;
@property (nonatomic, weak) IBOutlet UILabel *compactedLabel;
@property (nonatomic, weak) IBOutlet UIButton *goBackToExpandedStateButton;

- (void)setShowsCancelButton:(BOOL)show animated:(BOOL)animated;
- (void)setShowsBangButton:(BOOL)show animated:(BOOL)animated;
- (void)setShowsLeftButton:(BOOL)show animated:(BOOL)animated;
- (void)layoutIfNeeded:(NSTimeInterval)animationDuration;
- (void)cancel;
- (void)finish;
- (void)enableCompactState;
- (void)enableExpandedState;

- (IBAction)goBackToExpandedState:(id)sender;
+ (NSString*)getTextFromSearchBarText:(NSString*)searchText;
@end
