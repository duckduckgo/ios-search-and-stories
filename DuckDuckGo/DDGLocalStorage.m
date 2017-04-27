//
//  DDGLocalStorage.m
//  DuckDuckGo
//
//  Created by Ioannis Kokkinidis on 16/09/16.
//
//

#import "DDGLocalStorage.h"

#define LOCAL_STORAGE_PATH "WebKit/com.duckduckgo.mobile.ios/WebsiteData/LocalStorage"

@implementation DDGLocalStorage




#pragma mark - Initialization methods

+(instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] initPrivate];    //we call our own init
    });
    return sharedInstance;
}

- (instancetype)init {  //any calls to this init should result in an error.
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Use [DDGLocalStorage sharedInstance] to get a ref to this (shared) object." userInfo:nil];
}

- (instancetype)initPrivate {   //this will be our init from now on
    return [super init];
}




#pragma mark - Clearing storage data

-(void) clearCookies{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]) { //for each cookie
        [storage deleteCookie:cookie];  //delete
    }
}

-(void) clearLocalStorage {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@LOCAL_STORAGE_PATH];
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *string in array) {   //for each file in our local storage dir
        if ([[string pathExtension] isEqualToString:@"localstorage"]){  //if the file is of type .localstorage
            [[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:string] error:nil];   //go ahead and delete it
        }
    }
}

-(void) deleteTemporaryData {
    [self clearCookies];    // first, remove the cookies.
    [self clearLocalStorage];   //then delete all the cache files
}

@end
