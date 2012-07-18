//
//  Always.h
//  DuckDuckGo
//
//  Created by Chris Heimark on 12/14/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#ifndef DuckDuckGo_Always_h
#define DuckDuckGo_Always_h

#define IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPad : NO)
#define IPHONE ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone : YES)

#define LANDSCAPE (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) || ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight))
#define PORTRAIT (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationPortraitUpsideDown))

#endif