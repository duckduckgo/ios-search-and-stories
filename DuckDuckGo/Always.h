//
//  Always.h
//  DuckDuckGo
//
//  Created by Chris Heimark on 12/14/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#ifndef DuckDuckGo_Always_h
#define DuckDuckGo_Always_h

// cache control indices
enum
{ 
	kCacheStoreIndexNoFileCache = -1,	// this must be defined as -1
	kCacheStoreIndexTransient = 0,
	kCacheStoreIndexImages,
	kCacheStoreIndexTopics,
	
	kCacheStoreCacheCount
};


#endif
