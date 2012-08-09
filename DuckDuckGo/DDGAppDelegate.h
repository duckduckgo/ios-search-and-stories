//
//  DDGAppDelegate.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DDGAppDelegate : UIResponder <UIApplicationDelegate> {
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}
@property (strong, nonatomic) UIWindow *window;

-(NSPersistentStoreCoordinator *)persistentStoreCoordinator;

@end
