//
//  DDGToolbar.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 2016.01.05.
//
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    DDGToolbarLocationBottom,
    DDGToolbarLocationTop,
} DDGToolbarLocation;


@interface DDGToolbarItem : NSObject

@property id target;
@property SEL action;
@property NSString* imageName;
@property NSString* selectedImageName;
@property UIButton* button;
@property BOOL initiallySelected;



+(DDGToolbarItem*)toolbarItemWithTarget:(id)target
                               action:(SEL)action
                              imageName:(NSString*)imageName
                      selectedImageName:(NSString*)selectedImageName
                      initiallySelected:(BOOL)initiallySelected;

@end


@interface DDGToolbar : UIView

@property (nonatomic, strong) NSLayoutConstraint *toolbarWidthConstraint;

+(DDGToolbar*)toolbarInContainer:(UIView*)containerView
                       withItems:(NSArray<DDGToolbarItem*>*)toolbarItems
                      atLocation:(DDGToolbarLocation)location;

@end
