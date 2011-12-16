//
//  UtilityCHS.h
//  DuckDuckGo, Inc
//
//  Created by Chris Heimark on 9/17/09.
//  Copyright 2009 DuckDuckGo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UtilityCHS : NSObject
{
}

+ (void)dispatchURL:(NSDictionary*)entry;
+ (BOOL)portrait:(UIInterfaceOrientation)orientation;
+ (BOOL)upsideDownOK;
+ (BOOL)validateEmail:(NSString *)candidate;
+ (id)followPath:(NSArray*)keyPath pathIndex:(NSInteger)index inDictionary:(NSDictionary*)dictionary;
+ (id)itemWithKeyPath:(NSString*)path within:(NSDictionary*)dictionary;
+ (void)bubbleWithMessage:(NSString*)msg andResponse:(NSInteger)responseCode orWithError:(NSError*)error;
+ (void)renderImage:(UIView*)view savePath:(id)path withKey:(NSString*)key;

// HTTP POST request code
+ (NSMutableURLRequest*)constructMultipartPostRequestWithURL:(NSString*)url argumentKeyValues:(NSArray*)keyVals;
+ (NSString*)requestSynchPostMultipart:(NSString*)url argumentKeyValues:(NSArray*)keyVals response:(NSHTTPURLResponse**)response error:(NSError**)error;

+ (NSMutableURLRequest*)constructPostRequestWithURL:(NSString*)url argumentKeyValues:(NSArray*)keyVals;
+ (NSString*)requestSynchPost:(NSString*)url argumentKeyValues:(NSArray*)keyVals response:(NSHTTPURLResponse**)response error:(NSError**)error;

+ (id)makeObjectFromJSON:(NSString*)dataJSON;

+ (CGFloat)fontSizeToFit:(CGSize)size withString:(NSString*)text;
+ (BOOL)isPhone;

+ (NSDate*)dateFromInternetdDateString:(NSString*)dateString;

+ (NSString*)stripURL:(NSString*)url;
+ (NSString*)fixupString:(NSString*)s;
+ (NSString*)fixupURL:(NSString*)url;

+ (void)activityIndication:(BOOL)onOrOff;
+ (void)activityIndication:(BOOL)onOrOff withMessage:(NSString*)message;

+ (UIBarButtonItem*)iconButtonWithImageNamed:(NSString*)name action:(SEL)selector target:(id)target tag:(NSInteger)tag;

+ (NSString*)versionOfSoftware;

+ (BOOL)isIpad;
+ (BOOL)hasCanTweet;

@end

@interface NSDictionary(UtilityCHS)

- (BOOL)isEmpty;

@end

#define CHESSY_IPAD_PORTRAIT_WIDTH		768
#define CHESSY_IPAD_PORTRAIT_HEIGHT		1024
#define CHESSY_IPHONE_PORTRAIT_WIDTH	320
#define CHESSY_IPHONE_PORTRAIT_HEIGHT	480
#define	CHESSY_IPAD_USING_GROUPED_STYLE	88		// lose this many pixels
