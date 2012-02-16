//
//  Always.h
//  DuckDuckGo
//
//  Created by Chris Heimark on 12/14/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#ifndef DuckDuckGo_Always_h
#define DuckDuckGo_Always_h

#define kCacheIDNoFileCache @"NoFileCache"
#define kCacheIDTransient @"transient"
#define kCacheIDImages @"images"

#define IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPad : NO)
#define IPHONE ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone : YES)

#define LANDSCAPE (([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) || ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight))
#define PORTRAIT (([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) || ([UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown))

#endif
