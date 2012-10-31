//
//  DDGRegionProvider.h
//  DuckDuckGo
//
//  Created by Chris Heimark on 10/31/12.
//
//

#import <Foundation/Foundation.h>

@interface DDGRegionProvider : NSObject

@property (nonatomic, strong, readonly)		NSArray *regions;
@property (nonatomic, assign)				NSString *region;

+(DDGRegionProvider *)shared;

- (NSString*)titleForRegion:(NSString*)aRegion;

@end
