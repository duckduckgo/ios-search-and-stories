//
//  DDGLocalStorage.h
//  DuckDuckGo
//
//  Created by Ioannis Kokkinidis on 16/09/16.
//
//

#import <Foundation/Foundation.h>

@interface DDGLocalStorage : NSObject

+(instancetype)sharedInstance;  // returns a reference to this singleton
-(void) deleteTemporaryData;    // clears all temporary local storage data (that is cookies and .localStorage files)

@end
