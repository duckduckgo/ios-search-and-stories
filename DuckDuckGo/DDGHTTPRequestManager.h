//
//  DDGHTTPRequestManager.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 29/05/2014.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface DDGHTTPRequestManager : NSObject

+ (void)performRequest:(NSURLRequest *)request
        operationQueue:(NSOperationQueue *)operationQueue
         callbackQueue:(dispatch_queue_t)callbackQueue
               retries:(NSUInteger)retries
               success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
            expiration:(void (^)())expiration;
                                                                                                                         
@end
