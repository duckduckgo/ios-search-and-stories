//
//  Instapaper.h
//  ChessyLib
//
//  Created by Chris Heimark on 1/28/11.
//  Copyright 2011 CHS Systems. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Instapaper : NSObject
{

}

- (id)initWithUser:(NSString*)user password:(NSString*)password title:(NSString*)title urlToLog:(NSString*)url;

@end
