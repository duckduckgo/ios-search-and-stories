//
//  DDGRegionProvider.m
//  DuckDuckGo
//
//  Created by Chris Heimark on 10/31/12.
//
//

#import "DDGRegionProvider.h"

#import "DDGCache.h"

@interface DDGRegionProvider ()

@property (nonatomic, strong)  NSArray *regions;

@end

@implementation DDGRegionProvider

static DDGRegionProvider *shared = nil;

@synthesize regions;
@synthesize region;

-(id)init
{
    self = [super init];
    if(self)
	{
        // Custom initialization
        NSData *json = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"regions" ofType:@"json"]];
        self.regions = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    }
    return self;
}

+(DDGRegionProvider *)shared
{
    @synchronized(self)
	{
        if(!shared)
            shared = [[DDGRegionProvider alloc] init];
        
        return shared;
    }
}

- (NSString*)region
{
	return [DDGCache objectForKey:@"region" inCache:@"settings"];
}

- (void)setRegion:(NSString*)aRegion
{
	[DDGCache setObject:aRegion forKey:@"region" inCache:@"settings"];
}

- (NSString*)titleForRegion:(NSString*)aRegion
{
	for (NSDictionary *item in regions)
	{
		NSString *title = [item objectForKey:aRegion];
		if (title)
		{
			// found a match
			return title;
		}
	}
	return nil;
}


@end
