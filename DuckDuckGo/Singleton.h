/*
 *  SingletonTemplate.h
 *
 *  Created by Chris Heimark on 11/10/10.
 *  Copyright 2010 CHS Systems. All rights reserved.
 *
 */

/*
 *  Singleton.h
 *
 *  Template for making a class into a singleton.
 *
 *  Usage:
 
 @interface Foo ...
 + (Foo*) sharedInstance;
 @end
 
 @implementation
 #define SINGLETON_CLASS_NAME Foo
 #define SINGLETON_INIT_SELECTOR initWithCapacity:42
 #import "Singleton.h"
 ...
 @end
 
 *  See "Creating a Singleton Instance" in the Cocoa Fundamentals Guide for more info
 *
 */


#if !defined (SINGLETON_CLASS_NAME)
#error You must define SINGLETON_CLASS_NAME before including/importing this file!
#endif

#if !defined (SINGLETON_INIT_SELECTOR)
#define SINGLETON_INIT_SELECTOR init
#endif

#define _replace_1( SubstitutionOne, SubstitutionTwo ) SubstitutionOne##SubstitutionTwo
#define _replace_2( SubstitutionOne, SubstitutionTwo ) _replace_1( SubstitutionOne, SubstitutionTwo )
#define SINGLETON_REF  _replace_2(shared, SINGLETON_CLASS_NAME)

static SINGLETON_CLASS_NAME * SINGLETON_REF = nil;

+ (SINGLETON_CLASS_NAME *)sharedInstance {
	@synchronized(self) {
		if (SINGLETON_REF == nil) {
			[[self alloc] SINGLETON_INIT_SELECTOR]; // assignment done in alloc below, not here
		}
	}
	return SINGLETON_REF;
}


+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (SINGLETON_REF == nil) {
			SINGLETON_REF = [super allocWithZone:zone];
			return SINGLETON_REF;  // assignment and return on first allocation
		}
	}
	return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain {
	return self;
}

- (unsigned)retainCount {
	return UINT_MAX;  // denotes an object that cannot be released
}

- (oneway void)release {
	//do nothing
}

- (id)autorelease {
	return self;
}

#undef SINGLETON_CLASS_NAME
#undef SINGLETON_INIT_SELECTOR
#undef _replace_1
#undef _replace_2
#undef SINGLETON_REF
