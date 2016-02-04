//
//  DDGToolbar.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 2016.01.05.
//
//
//  Toolbar Implementation

#import "DDGToolbar.h"


@implementation DDGToolbarItem

+(DDGToolbarItem*)toolbarItemWithTarget:(id)target
                               action:(SEL)action
                              imageName:(NSString*)imageName
                      selectedImageName:(NSString*)selectedImageName
                      initiallySelected:(BOOL)initiallySelected
{
    DDGToolbarItem* item = [DDGToolbarItem new];
    item.target = target;
    item.action = action;
    item.imageName = imageName;
    item.selectedImageName = selectedImageName;
    item.initiallySelected = initiallySelected;
    return item;
}

@end



@implementation DDGToolbar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


+(DDGToolbar*)toolbarInContainer:(UIView*)containerView
                       withItems:(NSArray<DDGToolbarItem*>*)toolbarItems
                      atLocation:(DDGToolbarLocation)location
{
    CGFloat buttonSpace = 1.0/toolbarItems.count;
    CGFloat halfButtonSpace = buttonSpace * 0.5;
    UIButton* (^makeToolbarButton) (UIView*, DDGToolbarItem* item, NSInteger buttonIndex) =
    ^UIButton*(UIView* toolbar, DDGToolbarItem* item, NSInteger buttonIndex) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = FALSE;
        [button setTitle:nil forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:item.imageName] forState:UIControlStateNormal];
        if(item.selectedImageName) {
            [button setImage:[UIImage imageNamed:item.selectedImageName] forState:UIControlStateSelected];
        }
        button.selected = item.initiallySelected;
        [button addTarget:item.target action:item.action forControlEvents:UIControlEventTouchUpInside];
        [toolbar addSubview:button];
        [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                              toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1 constant:48]];
        [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                              toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1 constant:48]];
        
        CGFloat xMultiplier = halfButtonSpace + (buttonIndex * buttonSpace);
        
        // Initial fix for the Tab Bar icons for iPad
        /*
        if (IPAD) {
            if (xMultiplier != 0.5) {
                if (xMultiplier < 0.5) {
                    if (buttonIndex == 0) {
                        xMultiplier += buttonSpace/2;
                    } else {
                        xMultiplier += buttonSpace/4;
                    }
                } else {
                    if (buttonIndex == toolbarItems.count-1) {
                        xMultiplier -= buttonSpace/2;
                    } else {
                        xMultiplier -= buttonSpace/4;
                    }
                }
            }
        }*/
        
        [toolbar addConstraints:@[
                                  [NSLayoutConstraint constraintWithItem:button
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:toolbar
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0 ],
                                  [NSLayoutConstraint constraintWithItem:button
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:toolbar
                                                               attribute:NSLayoutAttributeTrailing
                                                              multiplier:xMultiplier
                                                                constant:0 ]
                                  ]
         ];
        
        return button;
    };
    
    DDGToolbar* toolbarView = [DDGToolbar new];
    toolbarView.translatesAutoresizingMaskIntoConstraints = FALSE;
    toolbarView.backgroundColor = [UIColor clearColor];
    toolbarView.opaque = FALSE;
    
    UIView *innerToolbarContainer = [UIView new];
    innerToolbarContainer.translatesAutoresizingMaskIntoConstraints = FALSE;
    innerToolbarContainer.backgroundColor = [UIColor clearColor];
    innerToolbarContainer.opaque = FALSE;
    
    // setup the top border
    UIView* borderView = [UIView new];
    borderView.translatesAutoresizingMaskIntoConstraints = FALSE;
    borderView.backgroundColor = [UIColor duckTabBarBorder];
    [toolbarView addSubview:borderView];
    [borderView addConstraint:[NSLayoutConstraint constraintWithItem:borderView
                                                           attribute:NSLayoutAttributeHeight
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1 constant:1]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:borderView
                                                            attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:toolbarView
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:1 constant:0 ]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:borderView
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toolbarView
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1 constant:0 ]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:borderView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toolbarView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1 constant:0 ]];
    
    // setup the opaque background
    UIView* backgroundView = [UIView new];
    backgroundView.translatesAutoresizingMaskIntoConstraints = FALSE;
    backgroundView.backgroundColor = [UIColor duckTabBarBackground];
    [toolbarView addSubview:backgroundView];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView
                                                           attribute:NSLayoutAttributeHeight
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1 constant:49]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toolbarView
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:1 constant:0 ]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toolbarView
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1 constant:0 ]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toolbarView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1 constant:0 ]];

    // add the toolbar to the container
    [containerView addSubview:toolbarView];

    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:toolbarView
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1 constant:50 ]];
    
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:toolbarView attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:containerView attribute:NSLayoutAttributeWidth
                                                             multiplier:1 constant:0 ]];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:toolbarView
                                                              attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                                 toItem:containerView attribute:NSLayoutAttributeBottom
                                                             multiplier:1 constant:0 ]];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:toolbarView attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:containerView attribute:NSLayoutAttributeCenterX
                                                             multiplier:1 constant:0 ]];
    NSInteger tabPosition = 0;
    for(DDGToolbarItem* item in toolbarItems) {
        makeToolbarButton(innerToolbarContainer, item, tabPosition);
        tabPosition++;
    }
    
    [toolbarView addSubview:innerToolbarContainer];
    
    
    toolbarView.toolbarWidthConstraint = [NSLayoutConstraint constraintWithItem:innerToolbarContainer attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:toolbarView attribute:NSLayoutAttributeWidth
                                                                     multiplier:1 constant:0];
    [toolbarView addConstraint:toolbarView.toolbarWidthConstraint];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:innerToolbarContainer
                                                              attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                                 toItem:toolbarView attribute:NSLayoutAttributeBottom
                                                             multiplier:1 constant:0 ]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:innerToolbarContainer
                                                            attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                                               toItem:toolbarView attribute:NSLayoutAttributeTop
                                                           multiplier:1 constant:0 ]];
    [toolbarView addConstraint:[NSLayoutConstraint constraintWithItem:innerToolbarContainer attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:toolbarView attribute:NSLayoutAttributeCenterX
                                                             multiplier:1 constant:0 ]];
    [containerView setNeedsLayout];
    return toolbarView;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    CGFloat tabBarWidthConstrant = 0;
    
    
    if (self.traitCollection) {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
            tabBarWidthConstrant = -200;

        }
    }
    
    self.toolbarWidthConstraint.constant = tabBarWidthConstrant;
    [self needsUpdateConstraints];
}

@end
